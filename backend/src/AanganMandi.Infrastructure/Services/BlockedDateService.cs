using AanganMandi.Application.Notifications;
using AanganMandi.Domain.Common;
using AanganMandi.Domain.Spaces;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Infrastructure.Services;

/// <summary>A blocked day and, when blocking it, how many waiting requests for it were declined.</summary>
public sealed record BlockResult(SpaceBlockedDate Blocked, int DeclinedRequests);

/// <summary>
/// Days a host closes their space although it is open that weekday. Blocking refuses a day with a confirmed farmer
/// (cancel that booking first, so the farmer is told why) and declines the day's waiting requests with the host's note.
/// Farmers then do not find the space for that day (<see cref="TripService.FindSpacesAsync"/>) and cannot request it.
/// </summary>
public class BlockedDateService(AppDbContext db, INotifier notifier)
{
    /// <summary>The space's blocked days from today on, earliest first.</summary>
    public async Task<List<SpaceBlockedDate>> ListAsync(Guid hostId, Guid spaceId, CancellationToken ct)
    {
        await RequireSpaceAsync(hostId, spaceId, ct);
        var today = TripService.Today;
        return await db.SpaceBlockedDates.AsNoTracking()
            .Where(d => d.SpaceId == spaceId && d.Date >= today).OrderBy(d => d.Date).ToListAsync(ct);
    }

    /// <summary>Blocks the day (blocking it again only changes the note).</summary>
    public async Task<BlockResult> BlockAsync(Guid hostId, Guid spaceId, DateOnly date, string? note, CancellationToken ct)
    {
        await RequireSpaceAsync(hostId, spaceId, ct);
        if (BlockedDateRules.Check(date, TripService.Today, note) is { } error) throw ApiException.BadRequest(error);
        note = TripService.Trim(note);

        var dayBookings = await db.Bookings.Where(b => b.SpaceId == spaceId && b.Date == date
            && (b.Status == BookingStatus.Requested || b.Status == BookingStatus.Accepted)).ToListAsync(ct);
        if (dayBookings.Any(b => b.Status == BookingStatus.Accepted)) throw ApiException.Conflict("block_date_booked");

        var blocked = await db.SpaceBlockedDates.SingleOrDefaultAsync(d => d.SpaceId == spaceId && d.Date == date, ct);
        if (blocked is null)
        {
            blocked = new SpaceBlockedDate { SpaceId = spaceId, Date = date };
            db.SpaceBlockedDates.Add(blocked);
        }
        blocked.Note = note;
        blocked.UpdatedAt = DateTime.UtcNow;

        var now = DateTime.UtcNow;
        foreach (var b in dayBookings)
        {
            b.Status = BookingStatus.Declined;
            b.Reason = note ?? BlockedDateRules.DefaultReason;
            b.RespondedAt = b.UpdatedAt = now;
        }
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            // Two taps at once: the unique (space, date) index kept one row, which is what was asked for.
            db.ChangeTracker.Clear();
            blocked = await db.SpaceBlockedDates.AsNoTracking().SingleAsync(d => d.SpaceId == spaceId && d.Date == date, ct);
            return new BlockResult(blocked, 0);
        }
        foreach (var b in dayBookings) await notifier.BookingChangedAsync(b.Id, ct);
        return new BlockResult(blocked, dayBookings.Count);
    }

    /// <summary>Opens the day again; nothing happens if it was not blocked.</summary>
    public async Task UnblockAsync(Guid hostId, Guid spaceId, DateOnly date, CancellationToken ct)
    {
        await RequireSpaceAsync(hostId, spaceId, ct);
        if (await db.SpaceBlockedDates.SingleOrDefaultAsync(d => d.SpaceId == spaceId && d.Date == date, ct) is { } row)
        {
            db.SpaceBlockedDates.Remove(row);
            await db.SaveChangesAsync(ct);
        }
    }

    private async Task RequireSpaceAsync(Guid hostId, Guid spaceId, CancellationToken ct)
    {
        if (!await db.Spaces.AnyAsync(s => s.Id == spaceId && s.HostUserId == hostId, ct)) throw ApiException.NotFound();
    }
}
