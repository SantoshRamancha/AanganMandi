using AanganMandi.Api.Auth;
using AanganMandi.Application.Notifications;
using AanganMandi.Application.Master;
using AanganMandi.Application.Trips;
using AanganMandi.Domain.Farmers;
using AanganMandi.Domain.Spaces;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// Verified farmers plan selling trips (date, vehicle, produce), find a live space that is open that day and fits
/// the vehicle, and request its slot. The host accepts or declines; only then are the address and phones shared.
/// </summary>
[ApiController]
[Authorize(Roles = "Farmer")]
[Route("api/v1/farmers/me/trips")]
public class FarmerTripsController(AppDbContext db, INotifier notifier) : ControllerBase
{
    public record ProduceItem(string CropCode, decimal? QuantityKg, decimal? PricePerKg);
    public record TripRequest(DateOnly Date, VehicleType Vehicle, string? PreferredArea, string? Notes, ProduceItem[] Produce);
    /// <summary>Status: Planned, Cancelled, or Completed (planned, date passed).</summary>
    public record TripDto(Guid Id, DateOnly Date, VehicleType Vehicle, string? PreferredArea, string? Notes, string Status,
        ProduceItem[] Produce, BookingDto? Booking);
    public record SpaceCard(Guid Id, string Title, SpaceType Type, string Locality, int AreaSqFt, string MaxStallSize,
        VehicleType MaxVehicle, Amenities[] Amenities, bool IsFree, decimal Fee, TimeOnly OpenFrom, TimeOnly OpenTo,
        string? Rules, string[] PhotoUrls);
    /// <summary>Shared only for an accepted booking (FR-1.9).</summary>
    public record HostContact(string? Name, string Phone, string Address, double Latitude, double Longitude);
    public record BookingDto(Guid Id, BookingStatus Status, DateOnly Date, TimeOnly From, TimeOnly To, decimal Fee,
        string? Message, string? Reason, bool SlotTaken, string? CancelledBy, SpaceCard Space, HostContact? Host);
    public record BookRequest(Guid SpaceId, string? Message);
    public record CancelRequest(string? Reason);

    [HttpGet]
    public async Task<IEnumerable<TripDto>> List(CancellationToken ct)
    {
        var today = Today;
        var trips = await db.Trips.Include(t => t.Produce).Where(t => t.FarmerUserId == User.UserId()).ToListAsync(ct);
        var bookings = await LatestBookingsAsync(trips.Select(t => t.Id).ToList(), ct);
        // Upcoming first (soonest at the top), then past and cancelled trips, newest first.
        return trips
            .OrderBy(t => t.Status != TripStatus.Planned || t.Date < today)
            .ThenBy(t => t.Status == TripStatus.Planned && t.Date >= today ? t.Date.DayNumber : -t.Date.DayNumber)
            .Select(t => ToDto(t, bookings.GetValueOrDefault(t.Id), today));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<TripDto>> Get(Guid id, CancellationToken ct)
    {
        var trip = await FindAsync(id, ct);
        if (trip is null) return NotFound();
        var bookings = await LatestBookingsAsync([trip.Id], ct);
        return ToDto(trip, bookings.GetValueOrDefault(trip.Id), Today);
    }

    [HttpPost]
    public async Task<ActionResult<TripDto>> Create(TripRequest req, CancellationToken ct)
    {
        if (await NotVerifiedAsync(ct) is { } denied) return denied;
        if (await ValidateAsync(req, ct) is { } error) return error;
        var trip = new Trip { FarmerUserId = User.UserId() };
        Apply(trip, req);
        db.Trips.Add(trip);
        await db.SaveChangesAsync(ct);
        return CreatedAtAction(nameof(Get), new { id = trip.Id }, ToDto(trip, null, Today));
    }

    /// <summary>Edits a planned trip. Date and vehicle are fixed while a booking is requested or accepted.</summary>
    [HttpPut("{id:guid}")]
    public async Task<ActionResult<TripDto>> Update(Guid id, TripRequest req, CancellationToken ct)
    {
        var trip = await FindAsync(id, ct);
        if (trip is null) return NotFound();
        if (trip.Status != TripStatus.Planned || trip.Date < Today)
            return Problem(statusCode: 409, title: "This trip can no longer be changed");
        if (await ValidateAsync(req, ct) is { } error) return error;
        var active = await db.Bookings.AnyAsync(b => b.TripId == id && (b.Status == BookingStatus.Requested || b.Status == BookingStatus.Accepted), ct);
        if (active && (req.Date != trip.Date || req.Vehicle != trip.Vehicle))
            return Problem(statusCode: 409, title: "Cancel the space booking first to change the date or vehicle");
        db.TripProduce.RemoveRange(trip.Produce);
        Apply(trip, req);
        await db.SaveChangesAsync(ct);
        var bookings = await LatestBookingsAsync([trip.Id], ct);
        return ToDto(trip, bookings.GetValueOrDefault(trip.Id), Today);
    }

    /// <summary>Cancels the trip and any requested or accepted booking for it.</summary>
    [HttpPost("{id:guid}/cancel")]
    public async Task<IActionResult> Cancel(Guid id, CancelRequest req, CancellationToken ct)
    {
        var trip = await FindAsync(id, ct);
        if (trip is null) return NotFound();
        if (trip.Status != TripStatus.Planned) return Problem(statusCode: 409, title: "Trip is already cancelled");
        trip.Status = TripStatus.Cancelled;
        trip.UpdatedAt = DateTime.UtcNow;
        var cancelled = (await db.Bookings.Where(b => b.TripId == id).ToListAsync(ct)).Where(b => b.IsActive).ToList();
        foreach (var b in cancelled) b.Cancel("Farmer", Trim(req.Reason));
        await db.SaveChangesAsync(ct);
        foreach (var b in cancelled) await notifier.BookingChangedAsync(b.Id, ct);
        return NoContent();
    }

    /// <summary>
    /// Live spaces with a free slot for this trip: open on its weekday, big enough for its vehicle, nobody confirmed
    /// for that day, and not the farmer's own. <paramref name="area"/> matches the locality or title.
    /// </summary>
    [HttpGet("{id:guid}/spaces")]
    public async Task<ActionResult<IEnumerable<SpaceCard>>> Spaces(Guid id, [FromQuery] string? area, CancellationToken ct)
    {
        var trip = await FindAsync(id, ct);
        if (trip is null) return NotFound();
        var me = User.UserId();
        var taken = db.Bookings.Where(b => b.Date == trip.Date && b.Status == BookingStatus.Accepted).Select(b => b.SpaceId);
        var query = db.Spaces.Include(s => s.Photos)
            .Where(s => s.Status == SpaceStatus.Live && s.HostUserId != me && !taken.Contains(s.Id));
        if (!string.IsNullOrWhiteSpace(area))
        {
            var a = area.Trim();
            query = query.Where(s => s.Locality.Contains(a) || s.Title.Contains(a));
        }
        var spaces = await query.ToListAsync(ct);
        return spaces
            .Where(s => TripRules.OpenOn(s.AvailableDays, trip.Date) && TripRules.VehicleFits(s.MaxVehicle, trip.Vehicle))
            .OrderBy(s => s.IsFree ? 0 : s.Fee).ThenBy(s => s.Locality)
            .Select(ToCard).ToList();
    }

    /// <summary>Requests a space's slot on the trip date. A trip has at most one requested or accepted booking.</summary>
    [HttpPost("{id:guid}/bookings")]
    public async Task<ActionResult<BookingDto>> Book(Guid id, BookRequest req, CancellationToken ct)
    {
        if (await NotVerifiedAsync(ct) is { } denied) return denied;
        var trip = await FindAsync(id, ct);
        if (trip is null) return NotFound();
        if (trip.Status != TripStatus.Planned || trip.Date < Today)
            return Problem(statusCode: 409, title: "This trip can no longer be booked");
        if (await db.Bookings.AnyAsync(b => b.TripId == id && (b.Status == BookingStatus.Requested || b.Status == BookingStatus.Accepted), ct))
            return Problem(statusCode: 409, title: "This trip already has a space requested or booked");
        var message = Trim(req.Message);
        if (message?.Length > 200) return Problem(statusCode: 400, title: "Keep the message under 200 characters");

        var space = await db.Spaces.Include(s => s.Photos).SingleOrDefaultAsync(s => s.Id == req.SpaceId, ct);
        if (space is null || space.Status != SpaceStatus.Live || space.HostUserId == User.UserId()) return NotFound();
        if (!TripRules.OpenOn(space.AvailableDays, trip.Date))
            return Problem(statusCode: 409, title: "The space is not open on that day");
        if (!TripRules.VehicleFits(space.MaxVehicle, trip.Vehicle))
            return Problem(statusCode: 409, title: "Your vehicle is too big for this space");
        if (await db.Bookings.AnyAsync(b => b.SpaceId == space.Id && b.Date == trip.Date && b.Status == BookingStatus.Accepted, ct))
            return Problem(statusCode: 409, title: "Another farmer has this space on that day");

        var booking = new Booking
        {
            TripId = trip.Id,
            SpaceId = space.Id,
            FarmerUserId = trip.FarmerUserId,
            HostUserId = space.HostUserId,
            Date = trip.Date,
            From = space.OpenFrom,
            To = space.OpenTo,
            Fee = space.IsFree ? 0 : space.Fee,
            Message = message,
        };
        db.Bookings.Add(booking);
        await db.SaveChangesAsync(ct);
        await notifier.BookingChangedAsync(booking.Id, ct);
        return ToBookingDto(booking, space, null);
    }

    [HttpPost("{id:guid}/bookings/{bookingId:guid}/cancel")]
    public async Task<IActionResult> CancelBooking(Guid id, Guid bookingId, CancelRequest req, CancellationToken ct)
    {
        var booking = await db.Bookings.SingleOrDefaultAsync(
            b => b.Id == bookingId && b.TripId == id && b.FarmerUserId == User.UserId(), ct);
        if (booking is null) return NotFound();
        if (!booking.IsActive) return Problem(statusCode: 409, title: "This booking is already closed");
        if (booking.Date < Today) return Problem(statusCode: 409, title: "This booking date has passed");
        booking.Cancel("Farmer", Trim(req.Reason));
        await db.SaveChangesAsync(ct);
        await notifier.BookingChangedAsync(booking.Id, ct);
        return NoContent();
    }

    // ---------------------------------------------------------------------------------------------

    private static DateOnly Today => TripRules.TodayInIndia(DateTime.UtcNow);

    private static string? Trim(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();

    private Task<Trip?> FindAsync(Guid id, CancellationToken ct) =>
        db.Trips.Include(t => t.Produce).SingleOrDefaultAsync(t => t.Id == id && t.FarmerUserId == User.UserId(), ct);

    /// <summary>Trips and bookings unlock at Level 2: only verified farmers can sell.</summary>
    private async Task<ObjectResult?> NotVerifiedAsync(CancellationToken ct)
    {
        var me = User.UserId();
        var verified = await db.FarmerProfiles.AnyAsync(f => f.UserId == me && f.Status == VerificationStatus.Verified, ct);
        return verified ? null : Problem(statusCode: 403, title: "Get verified before planning trips");
    }

    private async Task<ObjectResult?> ValidateAsync(TripRequest req, CancellationToken ct)
    {
        if (TripRules.CheckDate(req.Date, Today) is { } dateError) return Problem(statusCode: 400, title: dateError);
        if (!Enum.IsDefined(req.Vehicle)) return Problem(statusCode: 400, title: "Choose your vehicle");
        if (req.PreferredArea?.Trim().Length > 80) return Problem(statusCode: 400, title: "Keep the area under 80 characters");
        if (req.Notes?.Trim().Length > 200) return Problem(statusCode: 400, title: "Keep the notes under 200 characters");
        if (req.Produce.Length == 0) return Problem(statusCode: 400, title: "Add at least one crop you will bring");
        if (req.Produce.Any(p => p.QuantityKg is <= 0 or > 100_000 || p.PricePerKg is <= 0 or > 100_000))
            return Problem(statusCode: 400, title: "Quantity and price must be positive numbers");
        // Master crops by code, or the farmer's own "custom:<name>" crops; each once.
        var requested = req.Produce.Select(p => p.CropCode.Trim()).ToArray();
        var master = await db.Crops.Where(c => requested.Contains(c.Code)).Select(c => c.Code).ToListAsync(ct);
        var (codes, cropError) = CropCodes.Normalize(requested, master.ToHashSet());
        if (cropError is not null) return Problem(statusCode: 400, title: cropError);
        if (codes!.Length != req.Produce.Length) return Problem(statusCode: 400, title: "Each crop can be added once");
        // Store the tidied custom names.
        for (var i = 0; i < codes.Length; i++) req.Produce[i] = req.Produce[i] with { CropCode = codes[i] };
        return null;
    }

    private static void Apply(Trip t, TripRequest r)
    {
        t.Date = r.Date;
        t.Vehicle = r.Vehicle;
        t.PreferredArea = Trim(r.PreferredArea);
        t.Notes = Trim(r.Notes);
        t.Produce = r.Produce.Select(p => new TripProduce { CropCode = p.CropCode, QuantityKg = p.QuantityKg, PricePerKg = p.PricePerKg }).ToList();
        t.UpdatedAt = DateTime.UtcNow;
    }

    /// <summary>Each trip's most recent booking, with its space and (when accepted) the host.</summary>
    private async Task<Dictionary<Guid, BookingDto>> LatestBookingsAsync(List<Guid> tripIds, CancellationToken ct)
    {
        var rows = await (
            from b in db.Bookings
            where tripIds.Contains(b.TripId)
            join s in db.Spaces.Include(s => s.Photos) on b.SpaceId equals s.Id
            join h in db.Users on b.HostUserId equals h.Id
            select new { b, s, h }).ToListAsync(ct);
        return rows.GroupBy(r => r.b.TripId).ToDictionary(g => g.Key, g =>
        {
            var r = g.OrderByDescending(x => x.b.CreatedAt).First();
            var host = r.b.Status == BookingStatus.Accepted
                ? new HostContact(r.h.Name, r.h.Phone, $"{r.s.Address}, {r.s.Locality}", r.s.Location.Y, r.s.Location.X)
                : null;
            return ToBookingDto(r.b, r.s, host);
        });
    }

    private BookingDto ToBookingDto(Booking b, Space s, HostContact? host) =>
        new(b.Id, b.Status, b.Date, b.From, b.To, b.Fee, b.Message, b.Reason, b.SlotTaken, b.CancelledBy, ToCard(s), host);

    private static TripDto ToDto(Trip t, BookingDto? booking, DateOnly today) => new(t.Id, t.Date, t.Vehicle,
        t.PreferredArea, t.Notes,
        t.Status == TripStatus.Cancelled ? "Cancelled" : t.Date < today ? "Completed" : "Planned",
        t.Produce.Select(p => new ProduceItem(p.CropCode, p.QuantityKg, p.PricePerKg)).ToArray(), booking);

    private SpaceCard ToCard(Space s) => new(s.Id, s.Title, s.Type, s.Locality, s.AreaSqFt, s.MaxStallSize, s.MaxVehicle,
        Enum.GetValues<Amenities>().Where(a => a != Amenities.None && s.Amenities.HasFlag(a)).ToArray(),
        s.IsFree, s.Fee, s.OpenFrom, s.OpenTo, s.Rules,
        s.Photos.Where(p => !p.IsRightToUseProof).OrderBy(p => p.CreatedAt)
            .Select(p => Url.Content($"~/api/v1/files/{p.FilePath}")).ToArray());
}
