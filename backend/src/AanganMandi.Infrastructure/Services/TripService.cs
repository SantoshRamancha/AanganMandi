using AanganMandi.Application.Master;
using AanganMandi.Application.Notifications;
using AanganMandi.Application.Trips;
using AanganMandi.Domain.Common;
using AanganMandi.Domain.Farmers;
using AanganMandi.Domain.Spaces;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Infrastructure.Services;

public sealed record ProduceInput(string CropCode, decimal? QuantityKg, decimal? PricePerKg);
public sealed record TripInput(DateOnly Date, VehicleType Vehicle, string? PreferredArea, string? Notes, ProduceInput[] Produce);

/// <summary>
/// The farmer's side of selling: plan, edit and cancel trips, find a space with a free slot, request it, cancel the
/// request, and check in on the day. Refusals are <see cref="ApiException"/>s; nothing here knows about HTTP.
/// </summary>
public class TripService(AppDbContext db, INotifier notifier)
{
    public static DateOnly Today => TripRules.TodayInIndia(DateTime.UtcNow);

    public async Task<Trip> GetAsync(Guid farmerId, Guid tripId, CancellationToken ct) =>
        await db.Trips.Include(t => t.Produce).SingleOrDefaultAsync(t => t.Id == tripId && t.FarmerUserId == farmerId, ct)
        ?? throw ApiException.NotFound();

    public async Task<Trip> CreateAsync(Guid farmerId, TripInput input, CancellationToken ct)
    {
        await RequireVerifiedAsync(farmerId, ct);
        var produce = await ValidateAsync(input, ct);
        var trip = new Trip { FarmerUserId = farmerId };
        Apply(trip, input, produce);
        db.Trips.Add(trip);
        await db.SaveChangesAsync(ct);
        return trip;
    }

    /// <summary>Edits a planned trip. Date and vehicle are fixed while a booking is requested or accepted.</summary>
    public async Task<Trip> UpdateAsync(Guid farmerId, Guid tripId, TripInput input, CancellationToken ct)
    {
        var trip = await GetAsync(farmerId, tripId, ct);
        if (trip.Status != TripStatus.Planned || trip.Date < Today) throw ApiException.Conflict("trip_locked");
        var produce = await ValidateAsync(input, ct);
        var active = await db.Bookings.AnyAsync(b => b.TripId == tripId
            && (b.Status == BookingStatus.Requested || b.Status == BookingStatus.Accepted), ct);
        if (active && (input.Date != trip.Date || input.Vehicle != trip.Vehicle))
            throw ApiException.Conflict("trip_cancel_booking_first");
        db.TripProduce.RemoveRange(trip.Produce);
        Apply(trip, input, produce);
        await db.SaveChangesAsync(ct);
        return trip;
    }

    /// <summary>Cancels the trip and any requested or accepted booking for it (the hosts are told).</summary>
    public async Task CancelAsync(Guid farmerId, Guid tripId, string? reason, CancellationToken ct)
    {
        var trip = await GetAsync(farmerId, tripId, ct);
        if (trip.Status != TripStatus.Planned) throw ApiException.Conflict("trip_already_cancelled");
        trip.Status = TripStatus.Cancelled;
        trip.UpdatedAt = DateTime.UtcNow;
        var cancelled = (await db.Bookings.Where(b => b.TripId == tripId).ToListAsync(ct)).Where(b => b.IsActive).ToList();
        foreach (var b in cancelled) b.Cancel("Farmer", Trim(reason));
        await db.SaveChangesAsync(ct);
        foreach (var b in cancelled) await notifier.BookingChangedAsync(b.Id, ct);
    }

    /// <summary>
    /// Live spaces with a free slot for the trip: open on its weekday and not blocked by the host that day, big enough
    /// for its vehicle, nobody confirmed for that day, and not the farmer's own; cheapest first. <paramref name="area"/>
    /// matches locality or title.
    /// </summary>
    public async Task<List<Space>> FindSpacesAsync(Guid farmerId, Guid tripId, string? area, CancellationToken ct)
    {
        var trip = await GetAsync(farmerId, tripId, ct);
        var taken = db.Bookings.Where(b => b.Date == trip.Date && b.Status == BookingStatus.Accepted).Select(b => b.SpaceId);
        var blocked = db.SpaceBlockedDates.Where(d => d.Date == trip.Date).Select(d => d.SpaceId);
        var query = db.Spaces.Include(s => s.Photos)
            .Where(s => s.Status == SpaceStatus.Live && s.HostUserId != farmerId && !taken.Contains(s.Id)
                && !blocked.Contains(s.Id));
        if (!string.IsNullOrWhiteSpace(area))
        {
            var a = area.Trim();
            query = query.Where(s => s.Locality.Contains(a) || s.Title.Contains(a));
        }
        var spaces = await query.ToListAsync(ct);
        return spaces
            .Where(s => TripRules.OpenOn(s.AvailableDays, trip.Date) && TripRules.VehicleFits(s.MaxVehicle, trip.Vehicle))
            .OrderBy(s => s.IsFree ? 0 : s.Fee).ThenBy(s => s.Locality)
            .ToList();
    }

    /// <summary>
    /// Requests a space's slot on the trip date. A trip has at most one requested or accepted booking, and a farmer
    /// with too many recent no-shows cannot request (see <see cref="NoShowPolicy"/>).
    /// </summary>
    public async Task<(Booking Booking, Space Space)> BookAsync(Guid farmerId, Guid tripId, Guid spaceId, string? message,
        CancellationToken ct)
    {
        await RequireVerifiedAsync(farmerId, ct);
        var trip = await GetAsync(farmerId, tripId, ct);
        if (trip.Status != TripStatus.Planned || trip.Date < Today) throw ApiException.Conflict("trip_not_bookable");
        if (await db.Bookings.AnyAsync(b => b.TripId == tripId
                && (b.Status == BookingStatus.Requested || b.Status == BookingStatus.Accepted), ct))
            throw ApiException.Conflict("trip_has_booking");
        message = Trim(message);
        if (message?.Length > 200) throw ApiException.BadRequest("message_too_long", ("max", 200));
        var since = NoShowPolicy.WindowStart(DateTime.UtcNow);
        var noShows = await db.Bookings.CountAsync(b => b.FarmerUserId == farmerId && b.NoShowAt >= since, ct);
        if (NoShowPolicy.CheckCanBook(noShows) is { } blocked) throw ApiException.Conflict(blocked);

        var space = await db.Spaces.Include(s => s.Photos).SingleOrDefaultAsync(s => s.Id == spaceId, ct);
        if (space is null || space.Status != SpaceStatus.Live || space.HostUserId == farmerId) throw ApiException.NotFound();
        if (!TripRules.OpenOn(space.AvailableDays, trip.Date)
            || await db.SpaceBlockedDates.AnyAsync(d => d.SpaceId == space.Id && d.Date == trip.Date, ct))
            throw ApiException.Conflict("space_closed_that_day");
        if (!TripRules.VehicleFits(space.MaxVehicle, trip.Vehicle)) throw ApiException.Conflict("vehicle_too_big");
        if (await db.Bookings.AnyAsync(b => b.SpaceId == space.Id && b.Date == trip.Date && b.Status == BookingStatus.Accepted, ct))
            throw ApiException.Conflict("space_taken");

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
        return (booking, space);
    }

    public async Task CancelBookingAsync(Guid farmerId, Guid tripId, Guid bookingId, string? reason, CancellationToken ct)
    {
        var booking = await FindBookingAsync(farmerId, tripId, bookingId, ct);
        if (!booking.IsActive) throw ApiException.Conflict("booking_closed");
        if (booking.Date < Today) throw ApiException.Conflict("booking_date_passed");
        booking.Cancel("Farmer", Trim(reason));
        await db.SaveChangesAsync(ct);
        await notifier.BookingChangedAsync(booking.Id, ct);
    }

    /// <summary>
    /// "I've arrived": on the booking day, from an hour before the slot until it ends, within
    /// <see cref="ArrivalRules.MaxDistanceMeters"/> of the space. The host and nearby buyers are told.
    /// </summary>
    public async Task<(Booking Booking, Space Space)> ArriveAsync(Guid farmerId, Guid tripId, Guid bookingId,
        double latitude, double longitude, CancellationToken ct)
    {
        if (latitude is < -90 or > 90 || longitude is < -180 or > 180 || (latitude == 0 && longitude == 0))
            throw ApiException.BadRequest("checkin_location_required");
        var booking = await FindBookingAsync(farmerId, tripId, bookingId, ct);
        var space = await db.Spaces.Include(s => s.Photos).SingleOrDefaultAsync(s => s.Id == booking.SpaceId, ct)
            ?? throw ApiException.NotFound();

        var meters = ArrivalRules.DistanceMeters(latitude, longitude, space.Location.Y, space.Location.X);
        if (ArrivalRules.CheckArrival(booking, ArrivalRules.IndiaTime(DateTime.UtcNow), meters) is { } error)
            throw ApiException.Conflict(error);

        booking.ArrivedAt = DateTime.UtcNow;
        booking.ArrivalDistanceMeters = (int)Math.Round(meters);
        booking.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        await notifier.FarmerArrivedAsync(booking.Id, ct);
        return (booking, space);
    }

    // ---------------------------------------------------------------------------------------------

    private async Task<Booking> FindBookingAsync(Guid farmerId, Guid tripId, Guid bookingId, CancellationToken ct) =>
        await db.Bookings.SingleOrDefaultAsync(b => b.Id == bookingId && b.TripId == tripId && b.FarmerUserId == farmerId, ct)
        ?? throw ApiException.NotFound();

    /// <summary>Trips and bookings unlock at Level 2: only verified farmers can sell.</summary>
    private async Task RequireVerifiedAsync(Guid farmerId, CancellationToken ct)
    {
        if (!await db.FarmerProfiles.AnyAsync(f => f.UserId == farmerId && f.Status == VerificationStatus.Verified, ct))
            throw ApiException.Forbidden("not_verified");
    }

    /// <summary>Checks the trip and returns its produce with the crop codes tidied (custom names trimmed).</summary>
    private async Task<ProduceInput[]> ValidateAsync(TripInput req, CancellationToken ct)
    {
        if (TripRules.CheckDate(req.Date, Today) is { } dateError) throw ApiException.BadRequest(dateError);
        if (!Enum.IsDefined(req.Vehicle)) throw ApiException.BadRequest("vehicle_required");
        if (req.PreferredArea?.Trim().Length > 80) throw ApiException.BadRequest("area_too_long", ("max", 80));
        if (req.Notes?.Trim().Length > 200) throw ApiException.BadRequest("notes_too_long", ("max", 200));
        if (req.Produce is not { Length: > 0 }) throw ApiException.BadRequest("produce_required");
        if (req.Produce.Any(p => p.QuantityKg is <= 0 or > 100_000 || p.PricePerKg is <= 0 or > 100_000))
            throw ApiException.BadRequest("produce_numbers_invalid");
        // Master crops by code, or the farmer's own "custom:<name>" crops; each once.
        var requested = req.Produce.Select(p => p.CropCode.Trim()).ToArray();
        var master = await db.Crops.Where(c => requested.Contains(c.Code)).Select(c => c.Code).ToListAsync(ct);
        var (codes, cropError) = CropCodes.Normalize(requested, master.ToHashSet());
        if (cropError is not null) throw ApiException.BadRequest(cropError);
        if (codes!.Length != req.Produce.Length) throw ApiException.BadRequest("crop_duplicate");
        return req.Produce.Select((p, i) => p with { CropCode = codes[i] }).ToArray();
    }

    private static void Apply(Trip t, TripInput r, ProduceInput[] produce)
    {
        t.Date = r.Date;
        t.Vehicle = r.Vehicle;
        t.PreferredArea = Trim(r.PreferredArea);
        t.Notes = Trim(r.Notes);
        t.Produce = produce.Select(p => new TripProduce { CropCode = p.CropCode, QuantityKg = p.QuantityKg, PricePerKg = p.PricePerKg }).ToList();
        t.UpdatedAt = DateTime.UtcNow;
    }

    internal static string? Trim(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();
}
