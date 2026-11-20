using AanganMandi.Application.Analytics;
using AanganMandi.Domain.Common;
using AanganMandi.Domain.Farmers;
using AanganMandi.Domain.Identity;
using AanganMandi.Domain.Spaces;
using AanganMandi.Domain.Support;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Infrastructure.Services;

/// <summary>Who is on Aangan Mandi now (not limited to the period).</summary>
public sealed record PeopleNow(int Users, int NewUsers, int Farmers, int VerifiedFarmers, int FarmersWaiting, int Hosts,
    int Buyers, int BuyersWithArea, int SpacesLive, int SpacesWaiting);

/// <summary>
/// Requests made in the period and what became of them. Accepted counts those the host accepted, including ones
/// cancelled later. AcceptanceRate: accepted out of answered (accepted + declined), in percent.
/// </summary>
public sealed record RequestFunnel(int Made, int Waiting, int Accepted, int Declined, int Cancelled, int? AcceptanceRate);

/// <summary>
/// Confirmed stalls dated in the period. Held: the farmer checked in. ShowRate: held out of the stalls whose day is over,
/// in percent. HostFees: the fees of the held stalls, in rupees.
/// </summary>
public sealed record StallSummary(int Confirmed, int Held, int NoShows, int? ShowRate, decimal HostFees);

/// <summary>Ratings given in the period; the averages are null with none.</summary>
public sealed record RatingSummary(int Given, double? SpaceAverage, double? FarmerAverage);

public sealed record ReportSummary(int Opened, int Resolved, int OpenNow);

/// <summary>One day: requests made, stalls confirmed for it, and stalls held.</summary>
public sealed record DayCount(DateOnly Date, int Requests, int Stalls, int Held);

/// <summary>A crop or an area and how many confirmed stalls in the period had it.</summary>
public sealed record TopItem(string Key, int Stalls);

public sealed record Analytics(int Days, DateOnly From, DateOnly To, PeopleNow People, RequestFunnel Requests,
    StallSummary Stalls, RatingSummary Ratings, ReportSummary Reports, List<DayCount> Daily, List<TopItem> TopCrops,
    List<TopItem> TopAreas);

/// <summary>
/// Admin analytics for a period ending today (India dates): people, the request funnel, stalls held and no-shows,
/// ratings, problem reports, a day-by-day series, and the most sold crops and busiest areas. Read only.
/// </summary>
public class AnalyticsService(AppDbContext db)
{
    public async Task<Analytics> GetAsync(int days, CancellationToken ct)
    {
        if (!AnalyticsRules.Periods.Contains(days))
            throw ApiException.BadRequest("analytics_period", ("days", string.Join(", ", AnalyticsRules.Periods)));
        var today = TripService.Today;
        var (first, last) = AnalyticsRules.Range(days, today);
        var startUtc = AnalyticsRules.StartUtc(first);

        // People and spaces right now.
        var roles = await db.UserRoles.AsNoTracking().GroupBy(r => r.Role)
            .Select(g => new { Role = g.Key, Count = g.Count() }).ToDictionaryAsync(g => g.Role, g => g.Count, ct);
        var people = new PeopleNow(
            await db.Users.CountAsync(ct),
            await db.Users.CountAsync(u => u.CreatedAt >= startUtc, ct),
            roles.GetValueOrDefault(Role.Farmer),
            await db.FarmerProfiles.CountAsync(f => f.Status == VerificationStatus.Verified, ct),
            await db.FarmerProfiles.CountAsync(f => f.Status == VerificationStatus.Pending, ct),
            roles.GetValueOrDefault(Role.Host),
            roles.GetValueOrDefault(Role.Buyer),
            await db.BuyerAreas.CountAsync(ct),
            await db.Spaces.CountAsync(s => s.Status == SpaceStatus.Live, ct),
            await db.Spaces.CountAsync(s => s.Status == SpaceStatus.PendingReview, ct));

        // Requests made in the period.
        var made = await db.Bookings.AsNoTracking().Where(b => b.CreatedAt >= startUtc)
            .Select(b => new { b.CreatedAt, b.Status, b.RespondedAt }).ToListAsync(ct);
        var accepted = made.Count(b => b.RespondedAt != null && b.Status != BookingStatus.Declined);
        var declined = made.Count(b => b.Status == BookingStatus.Declined);
        var requests = new RequestFunnel(made.Count, made.Count(b => b.Status == BookingStatus.Requested), accepted, declined,
            made.Count(b => b.Status == BookingStatus.Cancelled), AnalyticsRules.Percent(accepted, accepted + declined));

        // Confirmed stalls dated in the period.
        var stalls = await (
            from b in db.Bookings.AsNoTracking()
            where b.Status == BookingStatus.Accepted && b.Date >= first && b.Date <= last
            join s in db.Spaces.IgnoreQueryFilters().AsNoTracking() on b.SpaceId equals s.Id
            select new { b.Id, b.TripId, b.Date, b.Fee, Held = b.ArrivedAt != null, NoShow = b.NoShowAt != null, s.Locality })
            .ToListAsync(ct);
        var over = stalls.Where(s => s.Date < today).ToList();
        var stallSummary = new StallSummary(stalls.Count, stalls.Count(s => s.Held), stalls.Count(s => s.NoShow),
            AnalyticsRules.Percent(over.Count(s => s.Held), over.Count), stalls.Where(s => s.Held).Sum(s => s.Fee));

        // Ratings and reports in the period.
        var ratings = await db.Ratings.AsNoTracking().Where(r => r.CreatedAt >= startUtc)
            .Select(r => new { r.By, r.Stars }).ToListAsync(ct);
        double? Avg(RatingSide by) => StarSummary.Of(ratings.Where(r => r.By == by).Select(r => r.Stars)).Average;
        var reports = new ReportSummary(
            await db.ProblemReports.CountAsync(r => r.CreatedAt >= startUtc, ct),
            await db.ProblemReports.CountAsync(r => r.ResolvedAt >= startUtc, ct),
            await db.ProblemReports.CountAsync(r => r.Status == ReportStatus.Open, ct));

        // Day by day.
        var requestsByDay = made.GroupBy(b => AnalyticsRules.IndiaDate(b.CreatedAt)).ToDictionary(g => g.Key, g => g.Count());
        var stallsByDay = stalls.GroupBy(s => s.Date).ToDictionary(g => g.Key, g => (All: g.Count(), Held: g.Count(s => s.Held)));
        var daily = AnalyticsRules.Days(first, last).Select(d =>
        {
            var s = stallsByDay.GetValueOrDefault(d);
            return new DayCount(d, requestsByDay.GetValueOrDefault(d), s.All, s.Held);
        }).ToList();

        // What sold and where: each confirmed stall counts once per crop it brought.
        var tripIds = stalls.Select(s => s.TripId).Distinct().ToList();
        var produce = await db.TripProduce.AsNoTracking().Where(p => tripIds.Contains(p.TripId))
            .Select(p => new { p.TripId, p.CropCode }).ToListAsync(ct);
        var stallsPerTrip = stalls.GroupBy(s => s.TripId).ToDictionary(g => g.Key, g => g.Count());
        var topCrops = produce
            .GroupBy(p => p.CropCode, StringComparer.OrdinalIgnoreCase)
            .Select(g => new TopItem(g.First().CropCode, g.Sum(p => stallsPerTrip[p.TripId])))
            .OrderByDescending(t => t.Stalls).ThenBy(t => t.Key).Take(AnalyticsRules.TopCount).ToList();
        var topAreas = stalls
            .GroupBy(s => s.Locality.Trim(), StringComparer.OrdinalIgnoreCase)
            .Select(g => new TopItem(g.First().Locality.Trim(), g.Count()))
            .OrderByDescending(t => t.Stalls).ThenBy(t => t.Key).Take(AnalyticsRules.TopCount).ToList();

        return new Analytics(days, first, last, people, requests, stallSummary,
            new RatingSummary(ratings.Count, Avg(RatingSide.Farmer), Avg(RatingSide.Host)), reports, daily, topCrops, topAreas);
    }
}
