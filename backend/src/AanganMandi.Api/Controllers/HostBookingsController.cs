using AanganMandi.Api.Auth;
using AanganMandi.Application.Trips;
using AanganMandi.Domain.Spaces;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// Hosts see farmers' requests for their spaces and accept or decline them. Accepting confirms that farmer for the
/// day and declines the other requests for the same space and day; then both sides see each other's phone.
/// </summary>
[ApiController]
[Authorize(Roles = "Host")]
[Route("api/v1/hosts/me/bookings")]
public class HostBookingsController(AppDbContext db) : ControllerBase
{
    public record ProduceItem(string CropCode, decimal? QuantityKg, decimal? PricePerKg);
    /// <summary>Phone only for an accepted booking (FR-1.9 works both ways).</summary>
    public record FarmerCard(string? Name, string? Village, string? District, string? Phone);
    public record HostBookingDto(Guid Id, BookingStatus Status, DateOnly Date, TimeOnly From, TimeOnly To, decimal Fee,
        string? Message, string? Reason, bool SlotTaken, string? CancelledBy, Guid SpaceId, string SpaceTitle,
        VehicleType Vehicle, ProduceItem[] Produce, FarmerCard Farmer, DateTime RequestedAt);
    public record ReasonRequest(string? Reason);

    /// <summary>view: "requests" (waiting for you), "upcoming" (accepted, today or later) or "past" (everything else).</summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<HostBookingDto>>> List([FromQuery] string view, CancellationToken ct)
    {
        var today = TripRules.TodayInIndia(DateTime.UtcNow);
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
            join s in db.Spaces on b.SpaceId equals s.Id
            join u in db.Users on b.FarmerUserId equals u.Id
            join f in db.FarmerProfiles on b.FarmerUserId equals f.UserId into fs
            from f in fs.DefaultIfEmpty()
            select new { b, t, s.Title, u.Name, u.Phone, Village = f == null ? null : f.Village, District = f == null ? null : f.District })
            .ToListAsync(ct);
        var ordered = view == "past" ? rows.OrderByDescending(r => r.b.Date) : rows.OrderBy(r => r.b.Date).ThenBy(r => r.b.CreatedAt);
        return ordered.Select(r => new HostBookingDto(r.b.Id, r.b.Status, r.b.Date, r.b.From, r.b.To, r.b.Fee, r.b.Message,
            r.b.Reason, r.b.SlotTaken, r.b.CancelledBy, r.b.SpaceId, r.Title, r.t.Vehicle,
            r.t.Produce.Select(p => new ProduceItem(p.CropCode, p.QuantityKg, p.PricePerKg)).ToArray(),
            new FarmerCard(r.Name, r.Village, r.District, r.b.Status == BookingStatus.Accepted ? r.Phone : null),
            r.b.CreatedAt)).ToList();
    }

    /// <summary>Confirms this farmer for the day; other requests for the same space and day are declined.</summary>
    [HttpPost("{id:guid}/accept")]
    public async Task<IActionResult> Accept(Guid id, CancellationToken ct)
    {
        var booking = await FindAsync(id, ct);
        if (booking is null) return NotFound();
        if (booking.Status != BookingStatus.Requested) return Problem(statusCode: 409, title: "This request is already answered");
        if (booking.Date < TripRules.TodayInIndia(DateTime.UtcNow)) return Problem(statusCode: 409, title: "This date has passed");
        var space = await db.Spaces.SingleAsync(s => s.Id == booking.SpaceId, ct);
        if (space.Status != SpaceStatus.Live) return Problem(statusCode: 409, title: "The space is not live");

        var sameDay = await db.Bookings.Where(b => b.SpaceId == booking.SpaceId && b.Date == booking.Date && b.Id != id
            && (b.Status == BookingStatus.Requested || b.Status == BookingStatus.Accepted)).ToListAsync(ct);
        if (sameDay.Any(b => b.Status == BookingStatus.Accepted))
            return Problem(statusCode: 409, title: "You already confirmed another farmer for this day");

        var now = DateTime.UtcNow;
        booking.Status = BookingStatus.Accepted;
        booking.RespondedAt = now;
        booking.UpdatedAt = now;
        foreach (var other in sameDay)
        {
            other.Status = BookingStatus.Declined;
            other.SlotTaken = true;
            other.RespondedAt = now;
            other.UpdatedAt = now;
        }
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            // The unique "one accepted per space and day" index caught a race with another accept.
            return Problem(statusCode: 409, title: "You already confirmed another farmer for this day");
        }
        return NoContent();
    }

    [HttpPost("{id:guid}/decline")]
    public async Task<IActionResult> Decline(Guid id, ReasonRequest req, CancellationToken ct)
    {
        var booking = await FindAsync(id, ct);
        if (booking is null) return NotFound();
        if (booking.Status != BookingStatus.Requested) return Problem(statusCode: 409, title: "This request is already answered");
        if (ReasonError(req.Reason) is { } error) return error;
        booking.Status = BookingStatus.Declined;
        booking.Reason = req.Reason!.Trim();
        booking.RespondedAt = booking.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    /// <summary>Cancels an accepted booking (e.g. the host cannot open the space that day); the farmer sees why.</summary>
    [HttpPost("{id:guid}/cancel")]
    public async Task<IActionResult> Cancel(Guid id, ReasonRequest req, CancellationToken ct)
    {
        var booking = await FindAsync(id, ct);
        if (booking is null) return NotFound();
        if (booking.Status != BookingStatus.Accepted) return Problem(statusCode: 409, title: "Only a confirmed booking can be cancelled");
        if (booking.Date < TripRules.TodayInIndia(DateTime.UtcNow)) return Problem(statusCode: 409, title: "This date has passed");
        if (ReasonError(req.Reason) is { } error) return error;
        booking.Cancel("Host", req.Reason!.Trim());
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    private Task<Booking?> FindAsync(Guid id, CancellationToken ct) =>
        db.Bookings.SingleOrDefaultAsync(b => b.Id == id && b.HostUserId == User.UserId(), ct);

    /// <summary>The farmer needs to know why, so a reason is required.</summary>
    private ObjectResult? ReasonError(string? reason) =>
        string.IsNullOrWhiteSpace(reason) ? Problem(statusCode: 400, title: "Give the farmer a reason") :
        reason.Trim().Length > 200 ? Problem(statusCode: 400, title: "Keep the reason under 200 characters") :
        null;
}
