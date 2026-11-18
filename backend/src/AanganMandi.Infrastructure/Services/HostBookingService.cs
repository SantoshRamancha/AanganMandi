using AanganMandi.Application.Notifications;
using AanganMandi.Domain.Common;
using AanganMandi.Domain.Spaces;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Infrastructure.Services;

/// <summary>
/// The host's side of a booking: accept (which declines the other requests for that space and day), decline,
/// cancel a confirmed one, mark a no-show after the slot, and make the public link to share with neighbours.
/// </summary>
public class HostBookingService(AppDbContext db, INotifier notifier)
{
    public async Task<Booking> GetAsync(Guid hostId, Guid bookingId, CancellationToken ct) =>
        await db.Bookings.SingleOrDefaultAsync(b => b.Id == bookingId && b.HostUserId == hostId, ct)
        ?? throw ApiException.NotFound();

    /// <summary>Confirms this farmer for the day; other requests for the same space and day are declined.</summary>
    public async Task AcceptAsync(Guid hostId, Guid bookingId, CancellationToken ct)
    {
        var booking = await GetAsync(hostId, bookingId, ct);
        if (booking.Status != BookingStatus.Requested) throw ApiException.Conflict("request_answered");
        if (booking.Date < TripService.Today) throw ApiException.Conflict("date_passed");
        var space = await db.Spaces.SingleAsync(s => s.Id == booking.SpaceId, ct);
        if (space.Status != SpaceStatus.Live) throw ApiException.Conflict("space_not_live");

        var sameDay = await db.Bookings.Where(b => b.SpaceId == booking.SpaceId && b.Date == booking.Date && b.Id != bookingId
            && (b.Status == BookingStatus.Requested || b.Status == BookingStatus.Accepted)).ToListAsync(ct);
        if (sameDay.Any(b => b.Status == BookingStatus.Accepted)) throw ApiException.Conflict("farmer_already_confirmed");

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
            throw ApiException.Conflict("farmer_already_confirmed");
        }
        await notifier.BookingChangedAsync(booking.Id, ct);
        foreach (var other in sameDay) await notifier.BookingChangedAsync(other.Id, ct); // declined: slot taken
    }

    public async Task DeclineAsync(Guid hostId, Guid bookingId, string? reason, CancellationToken ct)
    {
        var booking = await GetAsync(hostId, bookingId, ct);
        if (booking.Status != BookingStatus.Requested) throw ApiException.Conflict("request_answered");
        booking.Status = BookingStatus.Declined;
        booking.Reason = RequireReason(reason);
        booking.RespondedAt = booking.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        await notifier.BookingChangedAsync(booking.Id, ct);
    }

    /// <summary>Cancels a confirmed booking (e.g. the host cannot open the space that day); the farmer sees why.</summary>
    public async Task CancelAsync(Guid hostId, Guid bookingId, string? reason, CancellationToken ct)
    {
        var booking = await GetAsync(hostId, bookingId, ct);
        if (booking.Status != BookingStatus.Accepted) throw ApiException.Conflict("cancel_not_confirmed");
        if (booking.Date < TripService.Today) throw ApiException.Conflict("date_passed");
        booking.Cancel("Host", RequireReason(reason));
        await db.SaveChangesAsync(ct);
        await notifier.BookingChangedAsync(booking.Id, ct);
    }

    /// <summary>
    /// The farmer did not come: once the slot is over and the farmer never checked in. It counts towards the farmer's
    /// no-shows (<see cref="NoShowPolicy"/>), which hosts see on requests.
    /// </summary>
    public async Task MarkNoShowAsync(Guid hostId, Guid bookingId, CancellationToken ct)
    {
        var booking = await GetAsync(hostId, bookingId, ct);
        if (!ArrivalRules.CanMarkNoShow(booking, ArrivalRules.IndiaTime(DateTime.UtcNow)))
            throw ApiException.Conflict(booking.ArrivedAt is not null ? "no_show_checked_in" : "no_show_too_early");
        booking.NoShowAt = booking.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
    }

    /// <summary>
    /// The code in the public stall link (/s/{code}), made on the first share. Only while the booking is confirmed
    /// and its slot is not over.
    /// </summary>
    public async Task<string> ShareCodeAsync(Guid hostId, Guid bookingId, CancellationToken ct)
    {
        var booking = await GetAsync(hostId, bookingId, ct);
        if (StallStatus.StateOf(booking, ArrivalRules.IndiaTime(DateTime.UtcNow)) == StallState.Over)
            throw ApiException.Conflict("share_not_allowed");
        if (booking.ShareCode is null)
        {
            booking.ShareCode = StallStatus.NewCode();
            booking.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync(ct);
        }
        return booking.ShareCode;
    }

    /// <summary>The farmer needs to know why, so a reason is required.</summary>
    private static string RequireReason(string? reason) =>
        string.IsNullOrWhiteSpace(reason) ? throw ApiException.BadRequest("reason_required_farmer") :
        reason.Trim().Length > 200 ? throw ApiException.BadRequest("reason_too_long", ("max", 200)) :
        reason.Trim();
}
