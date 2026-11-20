using AanganMandi.Application.Analytics;
using AanganMandi.Domain.Common;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Infrastructure.Services;

/// <summary>One of the host's spaces in the period: stalls held there and the fees from them.</summary>
public sealed record SpaceEarning(Guid Id, string Title, int Held, decimal Fees);

/// <summary>
/// A host's "My earnings" for a period ending today. Held, NoShows and FeesEarned: confirmed stalls dated in the
/// period (fees of the held ones). Upcoming and FeesExpected: confirmed stalls still to come (not limited to the
/// period). Requests, Accepted, Declined: requests received in the period. Rating: farmers' stars, all time.
/// </summary>
public sealed record HostSummary(int Days, DateOnly From, DateOnly To, int Held, int NoShows, decimal FeesEarned,
    int Upcoming, decimal FeesExpected, int Requests, int Accepted, int Declined, double? Rating, int RatingCount,
    List<SpaceEarning> Spaces);

/// <summary>
/// A farmer's "My stalls" for a period ending today. Trips: selling days planned in the period (not cancelled).
/// Held, NoShows, FeesPaid: confirmed stalls dated in the period (fees of the held ones). Upcoming: confirmed stalls
/// still to come. Rating: hosts' stars, all time. Crops and Places: what the farmer sold most and where, by held stalls.
/// </summary>
public sealed record FarmerSummary(int Days, DateOnly From, DateOnly To, int Trips, int Held, int NoShows,
    decimal FeesPaid, int Upcoming, double? Rating, int RatingCount, List<TopItem> Crops, List<TopItem> Places);

/// <summary>Each host's and farmer's own figures; read only. The counting rules are in <see cref="SummaryRules"/>.</summary>
public class SummaryService(AppDbContext db, RatingService ratings)
{
    public async Task<HostSummary> HostAsync(Guid hostId, int days, CancellationToken ct)
    {
        var (first, today) = Period(days);
        var stalls = await StallsAsync(db.Bookings.Where(b => b.HostUserId == hostId), first, ct);
        var inPeriod = stalls.Where(s => s.Date <= today).ToList();
        var upcoming = stalls.Where(s => SummaryRules.IsUpcoming(s, today)).ToList();
        var tally = SummaryRules.Tally(inPeriod);

        var startUtc = AnalyticsRules.StartUtc(first);
        var requests = await db.Bookings.AsNoTracking().Where(b => b.HostUserId == hostId && b.CreatedAt >= startUtc)
            .Select(b => new { b.Status, b.RespondedAt }).ToListAsync(ct);
        var declined = requests.Count(r => r.Status == BookingStatus.Declined);
        var accepted = requests.Count(r => r.RespondedAt != null && r.Status != BookingStatus.Declined);

        // Every space the host has now, plus deleted ones that had stalls in the period.
        var stallSpaceIds = inPeriod.Select(s => s.SpaceId).Distinct().ToList();
        var spaces = await db.Spaces.IgnoreQueryFilters().AsNoTracking()
            .Where(s => s.HostUserId == hostId && (!s.IsDeleted || stallSpaceIds.Contains(s.Id)))
            .Select(s => new { s.Id, s.Title }).ToListAsync(ct);
        var perSpace = spaces.Select(s =>
        {
            var t = SummaryRules.Tally(inPeriod.Where(x => x.SpaceId == s.Id));
            return new SpaceEarning(s.Id, s.Title, t.Held, t.Fees);
        }).OrderByDescending(s => s.Fees).ThenByDescending(s => s.Held).ThenBy(s => s.Title).ToList();

        var stars = await ratings.HostStarsAsync(hostId, ct);
        return new HostSummary(days, first, today, tally.Held, tally.NoShows, tally.Fees, upcoming.Count,
            upcoming.Sum(s => s.Fee), requests.Count, accepted, declined, stars.Average, stars.Count, perSpace);
    }

    public async Task<FarmerSummary> FarmerAsync(Guid farmerId, int days, CancellationToken ct)
    {
        var (first, today) = Period(days);
        var stalls = await StallsAsync(db.Bookings.Where(b => b.FarmerUserId == farmerId), first, ct);
        var inPeriod = stalls.Where(s => s.Date <= today).ToList();
        var tally = SummaryRules.Tally(inPeriod);
        var trips = await db.Trips.CountAsync(t => t.FarmerUserId == farmerId && t.Status == TripStatus.Planned
            && t.Date >= first && t.Date <= today, ct);

        // What sold and where: each held stall counts once per crop it brought.
        var held = inPeriod.Where(s => s.Held).ToList();
        var tripIds = held.Select(s => s.TripId).Distinct().ToList();
        var produce = await db.TripProduce.AsNoTracking().Where(p => tripIds.Contains(p.TripId))
            .Select(p => new { p.TripId, p.CropCode }).ToListAsync(ct);
        var cropKeys = held.SelectMany(s => produce.Where(p => p.TripId == s.TripId).Select(p => p.CropCode));
        var spaceIds = held.Select(s => s.SpaceId).Distinct().ToList();
        var titles = await db.Spaces.IgnoreQueryFilters().AsNoTracking().Where(s => spaceIds.Contains(s.Id))
            .ToDictionaryAsync(s => s.Id, s => s.Title, ct);
        var placeKeys = held.Select(s => titles.GetValueOrDefault(s.SpaceId, ""));

        var record = await ratings.FarmerRecordAsync(farmerId, ct);
        return new FarmerSummary(days, first, today, trips, tally.Held, tally.NoShows, tally.Fees,
            stalls.Count(s => SummaryRules.IsUpcoming(s, today)), record.Average, record.Ratings,
            [.. SummaryRules.Top(cropKeys).Select(t => new TopItem(t.Key, t.Count))],
            [.. SummaryRules.Top(placeKeys).Select(t => new TopItem(t.Key, t.Count))]);
    }

    private static (DateOnly First, DateOnly Today) Period(int days)
    {
        if (!SummaryRules.Periods.Contains(days))
            throw ApiException.BadRequest("summary_period", ("days", string.Join(", ", SummaryRules.Periods)));
        return AnalyticsRules.Range(days, TripService.Today);
    }

    /// <summary>Confirmed stalls dated from <paramref name="first"/> on, including those still to come.</summary>
    private static Task<List<StallRow>> StallsAsync(IQueryable<Booking> bookings, DateOnly first, CancellationToken ct) =>
        bookings.AsNoTracking().Where(b => b.Status == BookingStatus.Accepted && b.Date >= first)
            .Select(b => new StallRow(b.SpaceId, b.TripId, b.Date, b.Fee, b.ArrivedAt != null, b.NoShowAt != null))
            .ToListAsync(ct);
}
