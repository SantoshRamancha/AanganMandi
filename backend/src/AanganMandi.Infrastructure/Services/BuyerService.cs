using AanganMandi.Application.Trips;
using AanganMandi.Domain.Buyers;
using AanganMandi.Domain.Common;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;

namespace AanganMandi.Infrastructure.Services;

/// <summary>
/// One confirmed stall inside a buyer's area. SellingNow: the farmer checked in and the slot is running; the exact
/// address and position are given only then.
/// </summary>
public sealed record Stall(Guid BookingId, DateOnly Date, TimeOnly From, TimeOnly To, bool SellingNow,
    string? FarmerName, string? Village, List<TripProduce> Produce, string SpaceTitle, string Locality,
    string? Address, double? Latitude, double? Longitude, double DistanceKm);

/// <summary>Buyers: the saved area (where and how far), and the farmers selling inside it today and tomorrow.</summary>
public class BuyerService(AppDbContext db)
{
    private static readonly GeometryFactory Geo = NetTopologySuite.NtsGeometryServices.Instance.CreateGeometryFactory(4326);

    public Task<BuyerArea?> GetAreaAsync(Guid buyerId, CancellationToken ct) =>
        db.BuyerAreas.SingleOrDefaultAsync(a => a.UserId == buyerId, ct);

    public async Task<BuyerArea> SaveAreaAsync(Guid buyerId, double latitude, double longitude, int radiusKm, bool alertsOn,
        CancellationToken ct)
    {
        if (latitude is < -90 or > 90 || longitude is < -180 or > 180 || (latitude == 0 && longitude == 0))
            throw ApiException.BadRequest("location_required");
        if (!BuyerArea.Radii.Contains(radiusKm))
            throw ApiException.BadRequest("radius_invalid", ("radii", string.Join(", ", BuyerArea.Radii)));

        var point = Geo.CreatePoint(new Coordinate(longitude, latitude));
        var area = await GetAreaAsync(buyerId, ct);
        if (area is null)
        {
            area = new BuyerArea { UserId = buyerId, Location = point };
            db.BuyerAreas.Add(area);
        }
        area.Location = point;
        area.RadiusKm = radiusKm;
        area.AlertsOn = alertsOn;
        area.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return area;
    }

    /// <summary>Forgets the saved area: no nearby list and no alerts.</summary>
    public async Task DeleteAreaAsync(Guid buyerId, CancellationToken ct)
    {
        if (await GetAreaAsync(buyerId, ct) is { } area)
        {
            db.BuyerAreas.Remove(area);
            await db.SaveChangesAsync(ct);
        }
    }

    /// <summary>
    /// Confirmed stalls inside the area for the rest of today and tomorrow (today's drop off when their slot ends,
    /// no-shows are left out): selling now first, then by day, start time and distance.
    /// </summary>
    public async Task<List<Stall>> NearbyAsync(Guid buyerId, CancellationToken ct)
    {
        var area = await GetAreaAsync(buyerId, ct);
        if (area is null) return [];
        var today = TripRules.TodayInIndia(DateTime.UtcNow);
        var tomorrow = today.AddDays(1);
        var here = area.Location;
        var meters = area.RadiusKm * 1000;

        var rows = await (
            from b in db.Bookings.AsNoTracking()
            where b.Status == BookingStatus.Accepted && b.NoShowAt == null && (b.Date == today || b.Date == tomorrow)
            join s in db.Spaces.AsNoTracking() on b.SpaceId equals s.Id
            where s.Location.Distance(here) <= meters
            join t in db.Trips.AsNoTracking().Include(t => t.Produce) on b.TripId equals t.Id
            join u in db.Users.AsNoTracking() on b.FarmerUserId equals u.Id
            join f in db.FarmerProfiles.AsNoTracking() on b.FarmerUserId equals f.UserId into fs
            from f in fs.DefaultIfEmpty()
            select new { b, s, t, u.Name, Village = f == null ? null : f.Village, Meters = s.Location.Distance(here) })
            .ToListAsync(ct);

        var nowTime = TimeOnly.FromDateTime(ArrivalRules.IndiaTime(DateTime.UtcNow));
        return rows
            .Where(r => r.b.Date > today || nowTime < r.b.To)
            .Select(r =>
            {
                var selling = r.b.Date == today && r.b.ArrivedAt is not null && nowTime < r.b.To;
                return new Stall(r.b.Id, r.b.Date, r.b.From, r.b.To, selling, r.Name, r.Village, r.t.Produce,
                    r.s.Title, r.s.Locality,
                    selling ? $"{r.s.Address}, {r.s.Locality}" : null,
                    selling ? r.s.Location.Y : null, selling ? r.s.Location.X : null,
                    Math.Round(r.Meters / 1000, 1));
            })
            .OrderByDescending(x => x.SellingNow).ThenBy(x => x.Date).ThenBy(x => x.From).ThenBy(x => x.DistanceKm)
            .ToList();
    }
}
