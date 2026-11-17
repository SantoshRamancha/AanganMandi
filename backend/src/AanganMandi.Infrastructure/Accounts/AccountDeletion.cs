using System.Security.Cryptography;
using AanganMandi.Application.Notifications;
using AanganMandi.Application.Storage;
using AanganMandi.Application.Trips;
using AanganMandi.Domain.Identity;
using AanganMandi.Domain.Spaces;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AanganMandi.Infrastructure.Accounts;

/// <summary>
/// Marks a space deleted without saving: its photo and proof rows go, and its waiting or confirmed bookings from
/// today on are cancelled by the host with <paramref name="reason"/>. The caller saves, then deletes the returned
/// files from storage and notifies the farmers of the returned bookings.
/// </summary>
public static class SpaceRemoval
{
    public static async Task<(List<string> Files, List<Booking> Cancelled)> PrepareAsync(AppDbContext db, Space space,
        string reason, CancellationToken ct)
    {
        var today = TripRules.TodayInIndia(DateTime.UtcNow);
        var cancelled = (await db.Bookings.Where(b => b.SpaceId == space.Id && b.Date >= today).ToListAsync(ct))
            .Where(b => b.IsUpcoming(today)).ToList();
        foreach (var b in cancelled) b.Cancel("Host", reason);

        var files = space.Photos.Select(p => p.FilePath).ToList();
        db.SpacePhotos.RemoveRange(space.Photos);
        space.IsDeleted = true;
        space.UpdatedAt = DateTime.UtcNow;
        return (files, cancelled);
    }
}

public enum AccountDeletionResult { Deleted, NotFound, StaffAccount }

/// <summary>
/// "Delete my account" (Play Store and DPDP requirement). Removes what identifies the person and what they uploaded,
/// and closes what is still open:
/// <list type="bullet">
/// <item>farmer: upcoming bookings cancelled (hosts told), planned trips cancelled, verification details, crops,
/// plots and the evidence photo deleted;</item>
/// <item>host: every space deleted with its photos and proof, upcoming bookings cancelled (farmers told);</item>
/// <item>buyer: saved area and alert history deleted;</item>
/// <item>the account: name, email and phone cleared (the phone can sign up again as a new user), roles and logins
/// removed, marked deleted.</item>
/// </list>
/// Past bookings stay as history for the other side, without the person's name. Staff accounts are removed by an
/// admin instead, so their waiting farmers are reassigned.
/// </summary>
public class AccountDeletion(AppDbContext db, IFileStorage storage, INotifier notifier, ILogger<AccountDeletion> log)
{
    public const string FarmerReason = "The farmer closed their Aangan Mandi account";
    public const string HostReason = "The host closed their Aangan Mandi account";

    public async Task<AccountDeletionResult> DeleteAsync(Guid userId, CancellationToken ct)
    {
        var user = await db.Users.Include(u => u.Roles).SingleOrDefaultAsync(u => u.Id == userId, ct);
        if (user is null) return AccountDeletionResult.NotFound;
        if (user.Roles.Any(r => r.Role is Role.Admin or Role.Verifier)) return AccountDeletionResult.StaffAccount;

        var today = TripRules.TodayInIndia(DateTime.UtcNow);
        var files = new List<string>();
        var cancelled = new List<Booking>();

        // As a farmer.
        var myBookings = (await db.Bookings.Where(b => b.FarmerUserId == userId && b.Date >= today).ToListAsync(ct))
            .Where(b => b.IsUpcoming(today)).ToList();
        foreach (var b in myBookings) b.Cancel("Farmer", FarmerReason);
        cancelled.AddRange(myBookings);
        foreach (var t in await db.Trips.Where(t => t.FarmerUserId == userId && t.Status == TripStatus.Planned && t.Date >= today).ToListAsync(ct))
        {
            t.Status = TripStatus.Cancelled;
            t.UpdatedAt = DateTime.UtcNow;
        }
        var docs = await db.VerificationDocuments.Where(d => d.OwnerUserId == userId).ToListAsync(ct);
        files.AddRange(docs.Select(d => d.FilePath));
        db.VerificationDocuments.RemoveRange(docs);
        var profile = await db.FarmerProfiles.Include(f => f.Crops).Include(f => f.Plots).ThenInclude(p => p.Crops)
            .SingleOrDefaultAsync(f => f.UserId == userId, ct);
        if (profile is not null) db.FarmerProfiles.Remove(profile);

        // As a host.
        foreach (var space in await db.Spaces.Include(s => s.Photos).Where(s => s.HostUserId == userId).ToListAsync(ct))
        {
            var (spaceFiles, spaceBookings) = await SpaceRemoval.PrepareAsync(db, space, HostReason, ct);
            files.AddRange(spaceFiles);
            cancelled.AddRange(spaceBookings);
        }

        // As a buyer.
        db.BuyerAreas.RemoveRange(await db.BuyerAreas.Where(a => a.UserId == userId).ToListAsync(ct));
        db.NearbyAlerts.RemoveRange(await db.NearbyAlerts.Where(a => a.BuyerUserId == userId).ToListAsync(ct));

        // The account itself.
        db.RefreshTokens.RemoveRange(await db.RefreshTokens.Where(t => t.UserId == userId).ToListAsync(ct));
        db.UserRoles.RemoveRange(user.Roles);
        user.Name = null;
        user.Email = null;
        user.Phone = AnonymousPhone();
        user.Status = "Deleted";
        user.IsDeleted = true;
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        foreach (var path in files)
        {
            try { await storage.DeleteAsync(path, ct); }
            catch (Exception e) { log.LogWarning(e, "Could not delete {Path} of a deleted account", path); }
        }
        foreach (var b in cancelled) await notifier.BookingChangedAsync(b.Id, ct);
        log.LogInformation("Account {UserId} deleted: {Files} files, {Bookings} bookings cancelled", userId, files.Count, cancelled.Count);
        return AccountDeletionResult.Deleted;
    }

    /// <summary>
    /// A placeholder that is never a real number ("x" + 14 digits, fits the 15-character column) and keeps the
    /// phone column unique, so the real number can register again.
    /// </summary>
    public static string AnonymousPhone() => "x" + string.Concat(Enumerable.Range(0, 14).Select(_ => RandomNumberGenerator.GetInt32(10)));
}

/// <summary>Server commands for setting up a fresh database: the first admin.</summary>
public static class AdminSetup
{
    /// <summary>
    /// Makes the phone an Admin, creating the user if needed (it logs in with that phone and an OTP). Returns what
    /// happened, or the reason the phone was refused.
    /// </summary>
    public static async Task<string> MakeAdminAsync(AppDbContext db, string phoneInput, string? name, CancellationToken ct)
    {
        var (phone, error) = Application.Identity.PhoneNumbers.Normalize(phoneInput);
        if (phone is null) return error!;
        var user = await db.Users.Include(u => u.Roles).SingleOrDefaultAsync(u => u.Phone == phone, ct);
        var created = user is null;
        if (user is null)
        {
            user = new User { Phone = phone, Name = string.IsNullOrWhiteSpace(name) ? null : name.Trim() };
            db.Users.Add(user);
        }
        else if (!string.IsNullOrWhiteSpace(name) && user.Name is null) user.Name = name.Trim();
        if (user.Roles.Any(r => r.Role == Role.Admin)) return $"{phone} is already an admin.";
        user.Roles.Add(new UserRole { Role = Role.Admin });
        await db.SaveChangesAsync(ct);
        return created ? $"Created {phone} as an admin. Log in to the app with this number." : $"{phone} is now an admin.";
    }
}
