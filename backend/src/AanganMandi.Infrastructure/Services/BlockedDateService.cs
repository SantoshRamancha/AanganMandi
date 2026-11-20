using AanganMandi.Application.Notifications;
using AanganMandi.Application.Trips;
using AanganMandi.Domain.Common;
using AanganMandi.Domain.Spaces;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Infrastructure.Services;

/// <summary>A blocked day and, when blocking it, how many waiting requests for it were declined.</summary>
public sealed record BlockResult(SpaceBlockedDate Blocked, int DeclinedRequests);

/// <summary>
/// Blocking several days at once. Blocked: the days now closed. Booked: open days left alone because a farmer is
/// confirmed (cancel that booking first). DeclinedRequests: waiting requests for the blocked days.
/// </summary>
public sealed record BlockRangeResult(List<SpaceBlockedDate> Blocked, List<DateOnly> Booked, int DeclinedRequests);

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
        var result = await BlockDaysAsync(spaceId, [date], TripService.Trim(note), ct);
        if (result.Booked.Count > 0) throw ApiException.Conflict("block_date_booked");
        return new BlockResult(result.Blocked[0], result.DeclinedRequests);
    }

    /// <summary>
    /// Blocks every day from <paramref name="from"/> to <paramref name="to"/> that the space is normally open, except
    /// days with a confirmed farmer, which are returned as Booked. Refused when none of the days is an open day.
    /// </summary>
    public async Task<BlockRangeResult> BlockRangeAsync(Guid hostId, Guid spaceId, DateOnly from, DateOnly to, string? note,
        CancellationToken ct)
    {
        var space = await RequireSpaceAsync(hostId, spaceId, ct);
        if (BlockedDateRules.CheckRange(from, to, TripService.Today, note) is { } error) throw ApiException.BadRequest(error);
        var days = BlockedDateRules.Days(from, to).Where(d => TripRules.OpenOn(space.AvailableDays, d)).ToList();
        if (days.Count == 0) throw ApiException.BadRequest("block_range_closed");
        return await BlockDaysAsync(spaceId, days, TripService.Trim(note), ct);
    }

    private async Task<BlockRangeResult> BlockDaysAsync(Guid spaceId, List<DateOnly> days, string? note, CancellationToken ct)
    {
        for (var attempt = 1; ; attempt++)
        {
            var dayBookings = await db.Bookings.Where(b => b.SpaceId == spaceId && days.Contains(b.Date)
                && (b.Status == BookingStatus.Requested || b.Status == BookingStatus.Accepted)).ToListAsync(ct);
            var booked = dayBookings.Where(b => b.Status == BookingStatus.Accepted).Select(b => b.Date).ToHashSet();
            var toBlock = days.Where(d => !booked.Contains(d)).ToList();
            var existing = await db.SpaceBlockedDates.Where(d => d.SpaceId == spaceId && toBlock.Contains(d.Date))
                .ToDictionaryAsync(d => d.Date, ct);

            var now = DateTime.UtcNow;
            var blocked = new List<SpaceBlockedDate>();
            foreach (var day in toBlock)
            {
                if (!existing.TryGetValue(day, out var row))
                {
                    row = new SpaceBlockedDate { SpaceId = spaceId, Date = day };
                    db.SpaceBlockedDates.Add(row);
                }
                row.Note = note;
                row.UpdatedAt = now;
                blocked.Add(row);
            }
            var declined = dayBookings.Where(b => b.Status == BookingStatus.Requested && !booked.Contains(b.Date)).ToList();
            foreach (var b in declined)
            {
                b.Status = BookingStatus.Declined;
                b.Reason = note ?? BlockedDateRules.DefaultReason;
                b.RespondedAt = b.UpdatedAt = now;
            }
            try
            {
                await db.SaveChangesAsync(ct);
            }
            catch (DbUpdateException) when (attempt == 1)
            {
                // Two taps at once: the other one added some of these days first. Start again from what is saved now.
                db.ChangeTracker.Clear();
                continue;
            }
            foreach (var b in declined) await notifier.BookingChangedAsync(b.Id, ct);
            return new BlockRangeResult(blocked, [.. booked.Order()], declined.Count);
        }
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

    private async Task<Space> RequireSpaceAsync(Guid hostId, Guid spaceId, CancellationToken ct) =>
        await db.Spaces.AsNoTracking().SingleOrDefaultAsync(s => s.Id == spaceId && s.HostUserId == hostId, ct)
        ?? throw ApiException.NotFound();
}
