using AanganMandi.Api.Auth;
using AanganMandi.Application.Trips;
using AanganMandi.Domain.Spaces;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Persistence;
using AanganMandi.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// Verified farmers plan selling trips (date, vehicle, produce), find a live space that is open that day and fits
/// the vehicle, and request its slot. The host accepts or declines; only then are the address and phones shared.
/// The rules are in <see cref="TripService"/>; this controller translates requests and responses.
/// </summary>
[ApiController]
[Authorize(Roles = "Farmer")]
[Route("api/v1/farmers/me/trips")]
public class FarmerTripsController(AppDbContext db, TripService trips, RatingService ratings) : ControllerBase
{
    public record ProduceItem(string CropCode, decimal? QuantityKg, decimal? PricePerKg);
    public record TripRequest(DateOnly Date, VehicleType Vehicle, string? PreferredArea, string? Notes, ProduceItem[] Produce);
    /// <summary>Status: Planned, Cancelled, or Completed (planned, date passed).</summary>
    public record TripDto(Guid Id, DateOnly Date, VehicleType Vehicle, string? PreferredArea, string? Notes, string Status,
        ProduceItem[] Produce, BookingDto? Booking);
    /// <summary>Rating: farmers' average stars for the space (null until rated), from RatingCount ratings.</summary>
    public record SpaceCard(Guid Id, string Title, SpaceType Type, string Locality, int AreaSqFt, string MaxStallSize,
        VehicleType MaxVehicle, Amenities[] Amenities, bool IsFree, decimal Fee, TimeOnly OpenFrom, TimeOnly OpenTo,
        string? Rules, string[] PhotoUrls, double? Rating, int RatingCount);
    /// <summary>Shared only for an accepted booking (FR-1.9).</summary>
    public record HostContact(string? Name, string Phone, string Address, double Latitude, double Longitude);
    /// <summary>
    /// ArrivedAt: the farmer's check-in (UTC). NoShow: the host marked that the farmer did not come. CanRate: the stall
    /// is over and the farmer has not rated the space yet; MyStars: the farmer's rating once given.
    /// </summary>
    public record BookingDto(Guid Id, BookingStatus Status, DateOnly Date, TimeOnly From, TimeOnly To, decimal Fee,
        string? Message, string? Reason, bool SlotTaken, string? CancelledBy, SpaceCard Space, HostContact? Host,
        DateTime? ArrivedAt, bool NoShow, bool CanRate, int? MyStars);
    public record BookRequest(Guid SpaceId, string? Message);
    /// <summary>The phone's GPS position at the space.</summary>
    public record ArriveRequest(double Latitude, double Longitude);
    public record CancelRequest(string? Reason);

    [HttpGet]
    public async Task<IEnumerable<TripDto>> List(CancellationToken ct)
    {
        var today = TripService.Today;
        var mine = await db.Trips.Include(t => t.Produce).Where(t => t.FarmerUserId == User.UserId()).ToListAsync(ct);
        var bookings = await LatestBookingsAsync(mine.Select(t => t.Id).ToList(), ct);
        // Upcoming first (soonest at the top), then past and cancelled trips, newest first.
        return mine
            .OrderBy(t => t.Status != TripStatus.Planned || t.Date < today)
            .ThenBy(t => t.Status == TripStatus.Planned && t.Date >= today ? t.Date.DayNumber : -t.Date.DayNumber)
            .Select(t => ToDto(t, bookings.GetValueOrDefault(t.Id), today));
    }

    [HttpGet("{id:guid}")]
    public async Task<TripDto> Get(Guid id, CancellationToken ct) => await DtoAsync(await trips.GetAsync(User.UserId(), id, ct), ct);

    [HttpPost]
    public async Task<ActionResult<TripDto>> Create(TripRequest req, CancellationToken ct)
    {
        var trip = await trips.CreateAsync(User.UserId(), Input(req), ct);
        return CreatedAtAction(nameof(Get), new { id = trip.Id }, ToDto(trip, null, TripService.Today));
    }

    /// <summary>Edits a planned trip. Date and vehicle are fixed while a booking is requested or accepted.</summary>
    [HttpPut("{id:guid}")]
    public async Task<TripDto> Update(Guid id, TripRequest req, CancellationToken ct) =>
        await DtoAsync(await trips.UpdateAsync(User.UserId(), id, Input(req), ct), ct);

    /// <summary>Cancels the trip and any requested or accepted booking for it.</summary>
    [HttpPost("{id:guid}/cancel")]
    public async Task<IActionResult> Cancel(Guid id, CancelRequest req, CancellationToken ct)
    {
        await trips.CancelAsync(User.UserId(), id, req.Reason, ct);
        return NoContent();
    }

    /// <summary>
    /// Live spaces with a free slot for this trip: open on its weekday, big enough for its vehicle, nobody confirmed
    /// for that day, and not the farmer's own. <paramref name="area"/> matches the locality or title.
    /// </summary>
    [HttpGet("{id:guid}/spaces")]
    public async Task<IEnumerable<SpaceCard>> Spaces(Guid id, [FromQuery] string? area, CancellationToken ct)
    {
        var spaces = await trips.FindSpacesAsync(User.UserId(), id, area, ct);
        var stars = await ratings.SpaceStarsAsync(spaces.Select(s => s.Id).ToList(), ct);
        return spaces.Select(s => ToCard(s, stars.GetValueOrDefault(s.Id))).ToList();
    }

    /// <summary>Requests a space's slot on the trip date. A trip has at most one requested or accepted booking.</summary>
    [HttpPost("{id:guid}/bookings")]
    public async Task<BookingDto> Book(Guid id, BookRequest req, CancellationToken ct)
    {
        var (booking, space) = await trips.BookAsync(User.UserId(), id, req.SpaceId, req.Message, ct);
        var stars = await ratings.SpaceStarsAsync([space.Id], ct);
        return ToBookingDto(booking, space, null, stars.GetValueOrDefault(space.Id), null);
    }

    [HttpPost("{id:guid}/bookings/{bookingId:guid}/cancel")]
    public async Task<IActionResult> CancelBooking(Guid id, Guid bookingId, CancelRequest req, CancellationToken ct)
    {
        await trips.CancelBookingAsync(User.UserId(), id, bookingId, req.Reason, ct);
        return NoContent();
    }

    /// <summary>
    /// "I've arrived": the farmer checks in at the space on the booking day, from an hour before the slot until it
    /// ends, standing within <see cref="ArrivalRules.MaxDistanceMeters"/> of it. The host is told, and so are buyers
    /// whose saved area covers the space.
    /// </summary>
    [HttpPost("{id:guid}/bookings/{bookingId:guid}/arrive")]
    public async Task<BookingDto> Arrive(Guid id, Guid bookingId, ArriveRequest req, CancellationToken ct)
    {
        await trips.ArriveAsync(User.UserId(), id, bookingId, req.Latitude, req.Longitude, ct);
        var bookings = await LatestBookingsAsync([id], ct);
        return bookings[id];
    }

    // ---------------------------------------------------------------------------------------------

    private static TripInput Input(TripRequest r) => new(r.Date, r.Vehicle, r.PreferredArea, r.Notes,
        (r.Produce ?? []).Select(p => new ProduceInput(p.CropCode, p.QuantityKg, p.PricePerKg)).ToArray());

    private async Task<TripDto> DtoAsync(Trip trip, CancellationToken ct)
    {
        var bookings = await LatestBookingsAsync([trip.Id], ct);
        return ToDto(trip, bookings.GetValueOrDefault(trip.Id), TripService.Today);
    }

    /// <summary>Each trip's most recent booking, with its space and (when accepted) the host.</summary>
    private async Task<Dictionary<Guid, BookingDto>> LatestBookingsAsync(List<Guid> tripIds, CancellationToken ct)
    {
        var rows = await (
            from b in db.Bookings
            where tripIds.Contains(b.TripId)
            join s in db.Spaces.IgnoreQueryFilters().Include(s => s.Photos) on b.SpaceId equals s.Id // deleted spaces too
            join h in db.Users on b.HostUserId equals h.Id
            select new { b, s, h }).ToListAsync(ct);
        var latest = rows.GroupBy(r => r.b.TripId).Select(g => g.OrderByDescending(x => x.b.CreatedAt).First()).ToList();
        var spaceStars = await ratings.SpaceStarsAsync(latest.Select(r => r.s.Id).Distinct().ToList(), ct);
        var given = await ratings.BookingStarsAsync(latest.Select(r => r.b.Id).ToList(), ct);
        return latest.ToDictionary(r => r.b.TripId, r =>
        {
            var host = r.b.Status == BookingStatus.Accepted
                ? new HostContact(r.h.Name, r.h.Phone, $"{r.s.Address}, {r.s.Locality}", r.s.Location.Y, r.s.Location.X)
                : null;
            return ToBookingDto(r.b, r.s, host, spaceStars.GetValueOrDefault(r.s.Id), given.GetValueOrDefault(r.b.Id)?.ByFarmer);
        });
    }

    private BookingDto ToBookingDto(Booking b, Space s, HostContact? host, StarSummary? stars, int? myStars) =>
        new(b.Id, b.Status, b.Date, b.From, b.To, b.Fee, b.Message, b.Reason, b.SlotTaken, b.CancelledBy, ToCard(s, stars), host,
            b.ArrivedAt, b.NoShowAt is not null,
            myStars is null && RatingRules.CanRate(b, RatingSide.Farmer, ArrivalRules.IndiaTime(DateTime.UtcNow)), myStars);

    private static TripDto ToDto(Trip t, BookingDto? booking, DateOnly today) => new(t.Id, t.Date, t.Vehicle,
        t.PreferredArea, t.Notes,
        t.Status == TripStatus.Cancelled ? "Cancelled" : t.Date < today ? "Completed" : "Planned",
        t.Produce.Select(p => new ProduceItem(p.CropCode, p.QuantityKg, p.PricePerKg)).ToArray(), booking);

    private SpaceCard ToCard(Space s, StarSummary? stars) => new(s.Id, s.Title, s.Type, s.Locality, s.AreaSqFt, s.MaxStallSize,
        s.MaxVehicle, Enum.GetValues<Amenities>().Where(a => a != Amenities.None && s.Amenities.HasFlag(a)).ToArray(),
        s.IsFree, s.Fee, s.OpenFrom, s.OpenTo, s.Rules,
        s.Photos.Where(p => !p.IsRightToUseProof).OrderBy(p => p.CreatedAt)
            .Select(p => Url.Content($"~/api/v1/files/{p.FilePath}")).ToArray(),
        stars?.Average, stars?.Count ?? 0);
}
