using AanganMandi.Domain.Common;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Infrastructure.Services;

/// <summary>The stars each side gave one booking (null: not rated yet).</summary>
public sealed record BookingStars(int? ByFarmer, int? ByHost);

/// <summary>
/// Ratings after a stall (farmer rates the space, host rates the farmer) and the records shown to the other side:
/// a space's stars on the farmer's search, a farmer's stars, no-shows and completed stalls on the host's requests.
/// </summary>
public class RatingService(AppDbContext db)
{
    /// <summary>
    /// Rates the booking as its farmer or its host (whichever <paramref name="userId"/> is). Once per side; see
    /// <see cref="RatingRules"/> for when.
    /// </summary>
    public async Task<Rating> RateAsync(Guid userId, Guid bookingId, int stars, string? comment, CancellationToken ct)
    {
        var booking = await db.Bookings.SingleOrDefaultAsync(
            b => b.Id == bookingId && (b.FarmerUserId == userId || b.HostUserId == userId), ct)
            ?? throw ApiException.NotFound();
        var side = booking.FarmerUserId == userId ? RatingSide.Farmer : RatingSide.Host;
        if (RatingRules.CheckInput(stars, comment) is { } inputError) throw ApiException.BadRequest(inputError);
        if (RatingRules.WhyNot(booking, side, ArrivalRules.IndiaTime(DateTime.UtcNow)) is { } notNow)
            throw ApiException.Conflict(notNow);
        if (await db.Ratings.AnyAsync(r => r.BookingId == bookingId && r.By == side, ct))
            throw ApiException.Conflict("rating_already_given");

        var rating = new Rating
        {
            BookingId = booking.Id,
            SpaceId = booking.SpaceId,
            RaterUserId = userId,
            RatedUserId = side == RatingSide.Farmer ? booking.HostUserId : booking.FarmerUserId,
            By = side,
            Stars = stars,
            Comment = TripService.Trim(comment),
        };
        db.Ratings.Add(rating);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            // Two taps at once: the unique (booking, side) index keeps one.
            throw ApiException.Conflict("rating_already_given");
        }
        return rating;
    }

    /// <summary>Stars from farmers for each space.</summary>
    public async Task<Dictionary<Guid, StarSummary>> SpaceStarsAsync(IReadOnlyCollection<Guid> spaceIds, CancellationToken ct)
    {
        if (spaceIds.Count == 0) return [];
        var rows = await db.Ratings.AsNoTracking()
            .Where(r => r.By == RatingSide.Farmer && spaceIds.Contains(r.SpaceId))
            .Select(r => new { r.SpaceId, r.Stars }).ToListAsync(ct);
        return rows.GroupBy(r => r.SpaceId).ToDictionary(g => g.Key, g => StarSummary.Of(g.Select(r => r.Stars)));
    }

    /// <summary>Each farmer's record: stars from hosts, no-shows in the last <see cref="NoShowPolicy.WindowDays"/> days, stalls they came to.</summary>
    public async Task<Dictionary<Guid, FarmerRecord>> FarmerRecordsAsync(IReadOnlyCollection<Guid> farmerIds, CancellationToken ct)
    {
        if (farmerIds.Count == 0) return [];
        var stars = await db.Ratings.AsNoTracking()
            .Where(r => r.By == RatingSide.Host && farmerIds.Contains(r.RatedUserId))
            .Select(r => new { r.RatedUserId, r.Stars }).ToListAsync(ct);
        var since = NoShowPolicy.WindowStart(DateTime.UtcNow);
        var stalls = await db.Bookings.AsNoTracking()
            .Where(b => farmerIds.Contains(b.FarmerUserId) && (b.NoShowAt >= since || b.ArrivedAt != null))
            .Select(b => new { b.FarmerUserId, NoShow = b.NoShowAt >= since, Came = b.ArrivedAt != null })
            .ToListAsync(ct);
        return farmerIds.Distinct().ToDictionary(id => id, id =>
        {
            var s = StarSummary.Of(stars.Where(r => r.RatedUserId == id).Select(r => r.Stars));
            var mine = stalls.Where(b => b.FarmerUserId == id).ToList();
            return new FarmerRecord(s.Average, s.Count, mine.Count(b => b.NoShow), mine.Count(b => b.Came));
        });
    }

    public async Task<FarmerRecord> FarmerRecordAsync(Guid farmerId, CancellationToken ct) =>
        (await FarmerRecordsAsync([farmerId], ct))[farmerId];

    /// <summary>The stars given on each booking, by side.</summary>
    public async Task<Dictionary<Guid, BookingStars>> BookingStarsAsync(IReadOnlyCollection<Guid> bookingIds, CancellationToken ct)
    {
        if (bookingIds.Count == 0) return [];
        var rows = await db.Ratings.AsNoTracking().Where(r => bookingIds.Contains(r.BookingId))
            .Select(r => new { r.BookingId, r.By, r.Stars }).ToListAsync(ct);
        return rows.GroupBy(r => r.BookingId).ToDictionary(g => g.Key, g => new BookingStars(
            g.FirstOrDefault(r => r.By == RatingSide.Farmer)?.Stars, g.FirstOrDefault(r => r.By == RatingSide.Host)?.Stars));
    }

    /// <summary>A host's stars across their spaces (what farmers said about them).</summary>
    public async Task<StarSummary> HostStarsAsync(Guid hostId, CancellationToken ct) =>
        StarSummary.Of(await db.Ratings.AsNoTracking().Where(r => r.By == RatingSide.Farmer && r.RatedUserId == hostId)
            .Select(r => r.Stars).ToListAsync(ct));

    /// <summary>
    /// The no-shows behind a farmer's record, newest first, for an admin to check and clear a wrong one (for example
    /// a farmer who came but could not check in).
    /// </summary>
    public Task<List<Booking>> RecentNoShowsAsync(Guid farmerId, CancellationToken ct)
    {
        var since = NoShowPolicy.WindowStart(DateTime.UtcNow);
        return db.Bookings.AsNoTracking().Where(b => b.FarmerUserId == farmerId && b.NoShowAt >= since)
            .OrderByDescending(b => b.NoShowAt).ToListAsync(ct);
    }

    /// <summary>Admin: removes a no-show mark (the farmer did come, or the host marked the wrong booking).</summary>
    public async Task ClearNoShowAsync(Guid bookingId, CancellationToken ct)
    {
        var booking = await db.Bookings.SingleOrDefaultAsync(b => b.Id == bookingId, ct) ?? throw ApiException.NotFound();
        if (booking.NoShowAt is null) throw ApiException.Conflict("no_show_not_marked");
        booking.NoShowAt = null;
        booking.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
    }
}
