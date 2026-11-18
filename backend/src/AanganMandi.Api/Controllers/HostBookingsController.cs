using AanganMandi.Domain.Spaces;
using AanganMandi.Domain.Trips;
using AanganMandi.Api.Auth;
using AanganMandi.Infrastructure.Persistence;
using AanganMandi.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// Hosts see farmers' requests for their spaces and accept or decline them. Accepting confirms that farmer for the
/// day and declines the other requests for the same space and day; then both sides see each other's phone.
/// The rules are in <see cref="HostBookingService"/>.
/// </summary>
[ApiController]
[Authorize(Roles = "Host")]
[Route("api/v1/hosts/me/bookings")]
public class HostBookingsController(AppDbContext db, HostBookingService bookings, RatingService ratings) : ControllerBase
{
    public record ProduceItem(string CropCode, decimal? QuantityKg, decimal? PricePerKg);
    /// <summary>
    /// Phone only for an accepted booking (FR-1.9 works both ways). The farmer's record: Rating (hosts' average stars,
    /// null until rated) from RatingCount ratings, RecentNoShows in the last 90 days, CompletedStalls they came to.
    /// </summary>
    public record FarmerCard(string? Name, string? Village, string? District, string? Phone,
        double? Rating, int RatingCount, int RecentNoShows, int CompletedStalls);
    /// <summary>
    /// ArrivedAt: when the farmer checked in at the space (UTC). NoShow: marked by the host. CanMarkNoShow: the slot
    /// is over and the farmer never checked in. CanRate: the stall is over and the host has not rated the farmer yet;
    /// MyStars: the host's rating once given.
    /// </summary>
    public record HostBookingDto(Guid Id, BookingStatus Status, DateOnly Date, TimeOnly From, TimeOnly To, decimal Fee,
        string? Message, string? Reason, bool SlotTaken, string? CancelledBy, Guid SpaceId, string SpaceTitle,
        VehicleType Vehicle, ProduceItem[] Produce, FarmerCard Farmer, DateTime RequestedAt,
        DateTime? ArrivedAt, bool NoShow, bool CanMarkNoShow, bool CanRate, int? MyStars);
    public record ReasonRequest(string? Reason);
    /// <summary>The public stall page, e.g. https://aanganmandi.in/s/7kQ2mNp4xR.</summary>
    public record ShareLink(string Url);

    /// <summary>view: "requests" (waiting for you), "upcoming" (accepted, today or later) or "past" (everything else).</summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<HostBookingDto>>> List([FromQuery] string view, CancellationToken ct)
    {
        var today = TripService.Today;
        var q = db.Bookings.Where(b => b.HostUserId == User.UserId());
        q = view switch
        {
            "requests" => q.Where(b => b.Status == BookingStatus.Requested && b.Date >= today),
            "upcoming" => q.Where(b => b.Status == BookingStatus.Accepted && b.Date >= today),
            "past" => q.Where(b => b.Date < today || (b.Status != BookingStatus.Requested && b.Status != BookingStatus.Accepted)),
            _ => q.Where(_ => false),
        };
        var rows = await (
            from b in q
            join t in db.Trips.Include(t => t.Produce) on b.TripId equals t.Id
            join s in db.Spaces.IgnoreQueryFilters() on b.SpaceId equals s.Id // a deleted space's past bookings stay
            join u in db.Users on b.FarmerUserId equals u.Id
            join f in db.FarmerProfiles on b.FarmerUserId equals f.UserId into fs
            from f in fs.DefaultIfEmpty()
            select new { b, t, s.Title, u.Name, u.Phone, Village = f == null ? null : f.Village, District = f == null ? null : f.District })
            .ToListAsync(ct);
        var records = await ratings.FarmerRecordsAsync(rows.Select(r => r.b.FarmerUserId).Distinct().ToList(), ct);
        var given = await ratings.BookingStarsAsync(rows.Select(r => r.b.Id).ToList(), ct);
        var ordered = view == "past" ? rows.OrderByDescending(r => r.b.Date) : rows.OrderBy(r => r.b.Date).ThenBy(r => r.b.CreatedAt);
        var indiaNow = ArrivalRules.IndiaTime(DateTime.UtcNow);
        return ordered.Select(r =>
        {
            var record = records.GetValueOrDefault(r.b.FarmerUserId) ?? FarmerRecord.Empty;
            var myStars = given.GetValueOrDefault(r.b.Id)?.ByHost;
            return new HostBookingDto(r.b.Id, r.b.Status, r.b.Date, r.b.From, r.b.To, r.b.Fee, r.b.Message,
                r.b.Reason, r.b.SlotTaken, r.b.CancelledBy, r.b.SpaceId, r.Title, r.t.Vehicle,
                r.t.Produce.Select(p => new ProduceItem(p.CropCode, p.QuantityKg, p.PricePerKg)).ToArray(),
                new FarmerCard(r.Name, r.Village, r.District, r.b.Status == BookingStatus.Accepted ? r.Phone : null,
                    record.Average, record.Ratings, record.RecentNoShows, record.Completed),
                r.b.CreatedAt, r.b.ArrivedAt, r.b.NoShowAt is not null, ArrivalRules.CanMarkNoShow(r.b, indiaNow),
                myStars is null && RatingRules.CanRate(r.b, RatingSide.Host, indiaNow), myStars);
        }).ToList();
    }

    /// <summary>
    /// The public link to this stall for the host to share with neighbours (e.g. their society's WhatsApp group).
    /// The first call makes a random code; later calls return the same link. Only while the booking is confirmed and
    /// its slot is not over. The address in <c>Sharing:PublicBaseUrl</c> is used when set (production), else this
    /// API's own address.
    /// </summary>
    [HttpPost("{id:guid}/share")]
    public async Task<ShareLink> Share(Guid id, [FromServices] IConfiguration config, CancellationToken ct)
    {
        var code = await bookings.ShareCodeAsync(User.UserId(), id, ct);
        var origin = config["Sharing:PublicBaseUrl"] is { Length: > 0 } configured
            ? configured.TrimEnd('/')
            : $"{Request.Scheme}://{Request.Host}";
        return new ShareLink($"{origin}/s/{code}");
    }

    /// <summary>
    /// The farmer did not come: allowed once the slot is over and the farmer never checked in. It is recorded on the
    /// booking (shown to both sides) and counts towards the farmer's no-shows; nothing is emailed.
    /// </summary>
    [HttpPost("{id:guid}/no-show")]
    public async Task<IActionResult> NoShow(Guid id, CancellationToken ct)
    {
        await bookings.MarkNoShowAsync(User.UserId(), id, ct);
        return NoContent();
    }

    /// <summary>Confirms this farmer for the day; other requests for the same space and day are declined.</summary>
    [HttpPost("{id:guid}/accept")]
    public async Task<IActionResult> Accept(Guid id, CancellationToken ct)
    {
        await bookings.AcceptAsync(User.UserId(), id, ct);
        return NoContent();
    }

    [HttpPost("{id:guid}/decline")]
    public async Task<IActionResult> Decline(Guid id, ReasonRequest req, CancellationToken ct)
    {
        await bookings.DeclineAsync(User.UserId(), id, req.Reason, ct);
        return NoContent();
    }

    /// <summary>Cancels an accepted booking (e.g. the host cannot open the space that day); the farmer sees why.</summary>
    [HttpPost("{id:guid}/cancel")]
    public async Task<IActionResult> Cancel(Guid id, ReasonRequest req, CancellationToken ct)
    {
        await bookings.CancelAsync(User.UserId(), id, req.Reason, ct);
        return NoContent();
    }
}
