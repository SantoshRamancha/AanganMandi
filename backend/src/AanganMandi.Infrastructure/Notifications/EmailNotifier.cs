using System.Globalization;
using AanganMandi.Application.Master;
using AanganMandi.Application.Notifications;
using AanganMandi.Domain.Farmers;
using AanganMandi.Domain.Identity;
using AanganMandi.Domain.Spaces;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Persistence;
using Kinichit.Communication;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace AanganMandi.Infrastructure.Notifications;

/// <summary>Configuration section <c>Notifications</c>.</summary>
public sealed class NotificationOptions
{
    /// <summary>Address of the app, for the "Open Aangan Mandi" button. No button when empty.</summary>
    public string? AppUrl { get; set; }
}

/// <summary>
/// Emails people about their verification, spaces and bookings through the email queue (Kinichit.Communication), in each
/// recipient's app language. Only users who saved an email address get mail.
/// </summary>
public sealed class EmailNotifier(AppDbContext db, IEmailQueue queue, IOptions<NotificationOptions> options, ILogger<EmailNotifier> log)
    : INotifier
{
    public Task FarmerSubmittedAsync(Guid farmerUserId, CancellationToken ct) => Safe("farmer submitted", async () =>
    {
        var (farmer, profile) = await FarmerAsync(farmerUserId, ct);
        if (farmer is null || profile is null) return;
        await SendAsync(farmer, MailText.FarmerSubmitted, [], ct: ct);
        if (profile.AssignedVerifierId is { } verifierId) await SendToVerifierAsync(verifierId, farmer, profile, ct);
    });

    public Task FarmerDecidedAsync(Guid farmerUserId, CancellationToken ct) => Safe("farmer decided", async () =>
    {
        var (farmer, profile) = await FarmerAsync(farmerUserId, ct);
        if (farmer is null || profile is null) return;
        if (profile.Status == VerificationStatus.Verified)
            await SendAsync(farmer, MailText.FarmerApproved, [], ct: ct);
        else if (profile.Status == VerificationStatus.Rejected)
            await SendAsync(farmer, MailText.FarmerRejected, [], note: Note(MailText.ReasonTitle, profile.RejectionReason), ct: ct);
    });

    public Task FarmerAssignedAsync(Guid farmerUserId, CancellationToken ct) => Safe("farmer assigned", async () =>
    {
        var (farmer, profile) = await FarmerAsync(farmerUserId, ct);
        if (farmer is null || profile?.AssignedVerifierId is not { } verifierId) return;
        await SendToVerifierAsync(verifierId, farmer, profile, ct);
    });

    public Task VerifierAddedAsync(Guid verifierUserId, Guid addedByUserId, CancellationToken ct) => Safe("verifier added", async () =>
    {
        var verifier = await db.Users.AsNoTracking().SingleOrDefaultAsync(u => u.Id == verifierUserId, ct);
        if (verifier is null) return;
        var admin = await db.Users.AsNoTracking().Where(u => u.Id == addedByUserId).Select(u => u.Name).SingleOrDefaultAsync(ct);
        await SendAsync(verifier, MailText.VerifierAdded, new() { ["admin"] = admin ?? "Aangan Mandi", ["phone"] = verifier.Phone }, ct: ct);
    });

    public Task SpaceSubmittedAsync(Guid spaceId, CancellationToken ct) => Safe("space submitted", async () =>
    {
        var space = await db.Spaces.AsNoTracking().SingleOrDefaultAsync(s => s.Id == spaceId, ct);
        var host = space is null ? null : await db.Users.AsNoTracking().SingleOrDefaultAsync(u => u.Id == space.HostUserId, ct);
        if (space is null || host is null) return;
        var values = new Dictionary<string, string?> { ["space"] = space.Title, ["host"] = host.Name ?? host.Phone, ["locality"] = space.Locality };
        await SendAsync(host, MailText.SpaceSubmitted, values, ct: ct);

        // Admins approve spaces.
        var admins = await (from u in db.Users.AsNoTracking()
                            join r in db.UserRoles on u.Id equals r.UserId
                            where r.Role == Role.Admin && u.Email != null
                            select u).ToListAsync(ct);
        foreach (var admin in admins)
            await SendAsync(admin, MailText.SpaceToReview, values,
                [new(MailText.Space, space.Title), new(MailText.Locality, space.Locality), new(MailText.Host, $"{host.Name} · {host.Phone}")], ct: ct);
    });

    public Task SpaceDecidedAsync(Guid spaceId, CancellationToken ct) => Safe("space decided", async () =>
    {
        var space = await db.Spaces.AsNoTracking().SingleOrDefaultAsync(s => s.Id == spaceId, ct);
        var host = space is null ? null : await db.Users.AsNoTracking().SingleOrDefaultAsync(u => u.Id == space.HostUserId, ct);
        if (space is null || host is null) return;
        var values = new Dictionary<string, string?> { ["space"] = space.Title };
        if (space.Status == SpaceStatus.Live)
            await SendAsync(host, MailText.SpaceApproved, values, ct: ct);
        else if (space.Status == SpaceStatus.Rejected)
            await SendAsync(host, MailText.SpaceRejected, values, note: Note(MailText.ReasonTitle, space.RejectionReason), ct: ct);
    });

    public Task BookingChangedAsync(Guid bookingId, CancellationToken ct) => Safe("booking changed", async () =>
    {
        var b = await db.Bookings.AsNoTracking().SingleOrDefaultAsync(x => x.Id == bookingId, ct);
        if (b is null) return;
        var space = await db.Spaces.AsNoTracking().SingleAsync(s => s.Id == b.SpaceId, ct);
        var trip = await db.Trips.AsNoTracking().Include(t => t.Produce).SingleAsync(t => t.Id == b.TripId, ct);
        var farmer = await db.Users.AsNoTracking().SingleAsync(u => u.Id == b.FarmerUserId, ct);
        var host = await db.Users.AsNoTracking().SingleAsync(u => u.Id == b.HostUserId, ct);
        var village = await db.FarmerProfiles.AsNoTracking().Where(f => f.UserId == farmer.Id).Select(f => f.Village).SingleOrDefaultAsync(ct);

        // Each side reads the date in their own language.
        Dictionary<string, string?> ValuesFor(User to) => new()
        {
            ["space"] = space.Title,
            ["date"] = FormatDate(b.Date, Lang(to)),
            ["farmer"] = farmer.Name ?? farmer.Phone,
            ["host"] = host.Name ?? host.Phone,
        };
        var time = $"{b.From:HH\\:mm} – {b.To:HH\\:mm}";

        switch (b.Status)
        {
            case BookingStatus.Requested:
                var crops = await CropNamesAsync(trip.Produce, Lang(host), ct);
                await SendAsync(host, MailText.BookingRequested, ValuesFor(host),
                [
                    new(MailText.Date, FormatDate(b.Date, Lang(host))),
                    new(MailText.Time, time),
                    new(MailText.Farmer, village is null ? farmer.Name ?? "–" : $"{farmer.Name}, {village}"),
                    new(MailText.Vehicle, MailText.VehicleName(trip.Vehicle.ToString()).For(Lang(host))),
                    new(MailText.Crops, crops),
                ], Note(MailText.MessageTitle, b.Message), ct);
                break;

            case BookingStatus.Accepted:
                var lang = Lang(farmer);
                await SendAsync(farmer, MailText.BookingAccepted, ValuesFor(farmer),
                [
                    new(MailText.Space, space.Title),
                    new(MailText.Date, FormatDate(b.Date, lang)),
                    new(MailText.Time, time),
                    new(MailText.Address, $"{space.Address}, {space.Locality}"),
                    new(MailText.Host, $"{host.Name} · {host.Phone}"),
                    new(MailText.Fee, b.Fee == 0 ? MailText.Free.For(lang)
                        : MessageTemplate.Render(MailText.PerSlot.For(lang), new Dictionary<string, string?> { ["fee"] = b.Fee.ToString("0") })),
                ], ct: ct);
                break;

            case BookingStatus.Declined:
                var why = b.SlotTaken ? MailText.SlotTaken.For(Lang(farmer)) : b.Reason;
                await SendAsync(farmer, MailText.BookingDeclined, ValuesFor(farmer),
                    [new(MailText.Date, FormatDate(b.Date, Lang(farmer))), new(MailText.Time, time)], Note(MailText.ReasonTitle, why), ct);
                break;

            case BookingStatus.Cancelled when b.CancelledBy == "Host":
                await SendAsync(farmer, MailText.BookingCancelledByHost, ValuesFor(farmer),
                    [new(MailText.Date, FormatDate(b.Date, Lang(farmer))), new(MailText.Time, time)], Note(MailText.ReasonTitle, b.Reason), ct);
                break;

            case BookingStatus.Cancelled:
                await SendAsync(host, MailText.BookingCancelledByFarmer, ValuesFor(host),
                    [new(MailText.Date, FormatDate(b.Date, Lang(host))), new(MailText.Time, time)], Note(MailText.ReasonTitle, b.Reason), ct);
                break;
        }
    });

    // ---------------------------------------------------------------------------------------------

    private async Task<(User?, FarmerProfile?)> FarmerAsync(Guid userId, CancellationToken ct) => (
        await db.Users.AsNoTracking().SingleOrDefaultAsync(u => u.Id == userId, ct),
        await db.FarmerProfiles.AsNoTracking().SingleOrDefaultAsync(f => f.UserId == userId, ct));

    private async Task SendToVerifierAsync(Guid verifierId, User farmer, FarmerProfile profile, CancellationToken ct)
    {
        var verifier = await db.Users.AsNoTracking().SingleOrDefaultAsync(u => u.Id == verifierId, ct);
        if (verifier is null) return;
        await SendAsync(verifier, MailText.FarmerToVerify, new() { ["farmer"] = farmer.Name ?? farmer.Phone },
        [
            new(MailText.Farmer, farmer.Name ?? "–"),
            new(MailText.Village, string.Join(", ", new[] { profile.Village, profile.District }.Where(s => !string.IsNullOrWhiteSpace(s)))),
            new(MailText.Submitted, profile.SubmittedAt is { } at ? FormatDate(DateOnly.FromDateTime(at.AddHours(5.5)), Lang(verifier)) : "–"),
        ], ct: ct);
    }

    /// <summary>Renders the template in the recipient's language and queues it; users without an email address are skipped.</summary>
    private async Task SendAsync(User to, MailTemplate template, Dictionary<string, string?> values,
        IReadOnlyList<MailDetail>? details = null, MailNote? note = null, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(to.Email)) return;
        var mail = MailLayout.Render(template, Lang(to), to.Name, values, details, note, options.Value.AppUrl);
        var category = template.Key.Split('-')[0] switch { "farmer" or "verifier" => "verification", "space" => "spaces", _ => "bookings" };
        await queue.EnqueueAsync(new EmailMessage([new EmailAddress(to.Email, to.Name)], mail.Subject) { HtmlBody = mail.Html },
            category, template.Key, ct: ct);
    }

    private async Task<string> CropNamesAsync(IEnumerable<TripProduce> produce, string lang, CancellationToken ct)
    {
        var codes = produce.Select(p => p.CropCode).ToList();
        var names = await db.Crops.AsNoTracking().Where(c => codes.Contains(c.Code))
            .ToDictionaryAsync(c => c.Code, c => lang switch { "te" => c.NameTe, "hi" => c.NameHi, _ => c.NameEn }, ct);
        return string.Join(", ", codes.Select(c => CropCodes.IsCustom(c) ? CropCodes.CustomName(c) : names.GetValueOrDefault(c, c)));
    }

    private static MailNote? Note(L title, string? text) => string.IsNullOrWhiteSpace(text) ? null : new(title, text);

    private static string Lang(User u) => u.PreferredLanguage is "te" or "hi" ? u.PreferredLanguage : "en";

    /// <summary>"Sat, 7 Nov 2026" with day and month names in the recipient's language.</summary>
    public static string FormatDate(DateOnly date, string lang) =>
        date.ToString("ddd, d MMM yyyy", CultureInfo.GetCultureInfo(lang switch { "te" => "te-IN", "hi" => "hi-IN", _ => "en-IN" }));

    /// <summary>Email problems are logged and never fail the action that triggered them.</summary>
    private async Task Safe(string what, Func<Task> send)
    {
        try
        {
            await send();
        }
        catch (Exception e)
        {
            log.LogWarning(e, "Could not queue the {What} email", what);
        }
    }
}
