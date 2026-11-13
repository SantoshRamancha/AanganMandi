using AanganMandi.Api.Auth;
using AanganMandi.Application.Trips;
using AanganMandi.Domain.Buyers;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// Buyers save where they live and how far they will go (1, 2 or 5 km), then see verified farmers selling inside that
/// area today and tomorrow, and get email alerts the evening before and when a farmer arrives. The exact address is
/// shown only while the farmer is there; until then, the area.
/// </summary>
[ApiController]
[Authorize(Roles = "Buyer")]
[Route("api/v1/buyers/me")]
public class BuyersController(AppDbContext db) : ControllerBase
{
    public record AreaDto(double Latitude, double Longitude, int RadiusKm, bool AlertsOn);
    /// <summary>Area is null until the buyer saves one. HasEmail: alerts need an email address in the profile.</summary>
    public record BuyerDto(AreaDto? Area, bool HasEmail);
    public record ProduceItem(string CropCode, decimal? QuantityKg, decimal? PricePerKg);
    /// <summary>
    /// One farmer's stall inside the buyer's area. SellingNow: checked in and the slot is running. Address and position
    /// only while selling now.
    /// </summary>
    public record NearbyStall(Guid BookingId, DateOnly Date, TimeOnly From, TimeOnly To, bool SellingNow,
        string? FarmerName, string? Village, ProduceItem[] Produce, string SpaceTitle, string Locality,
        string? Address, double? Latitude, double? Longitude, double DistanceKm);

    private static readonly GeometryFactory Geo = NetTopologySuite.NtsGeometryServices.Instance.CreateGeometryFactory(4326);

    [HttpGet]
    public async Task<BuyerDto> Get(CancellationToken ct) => await DtoAsync(await AreaAsync(ct), ct);

    [HttpPut("area")]
    public async Task<ActionResult<BuyerDto>> SaveArea(AreaDto req, CancellationToken ct)
    {
        if (req.Latitude is < -90 or > 90 || req.Longitude is < -180 or > 180 || (req.Latitude == 0 && req.Longitude == 0))
            return Problem(statusCode: 400, title: "Capture your location");
        if (!BuyerArea.Radii.Contains(req.RadiusKm))
            return Problem(statusCode: 400, title: $"Choose {string.Join(", ", BuyerArea.Radii)} km");

        var area = await AreaAsync(ct);
        if (area is null)
        {
            area = new BuyerArea { UserId = User.UserId(), Location = Point(req) };
            db.BuyerAreas.Add(area);
        }
        area.Location = Point(req);
        area.RadiusKm = req.RadiusKm;
        area.AlertsOn = req.AlertsOn;
        area.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return await DtoAsync(area, ct);
    }

    /// <summary>Forgets the saved area: no nearby list and no alerts.</summary>
    [HttpDelete("area")]
    public async Task<IActionResult> DeleteArea(CancellationToken ct)
    {
        if (await AreaAsync(ct) is { } area)
        {
            db.BuyerAreas.Remove(area);
            await db.SaveChangesAsync(ct);
        }
        return NoContent();
    }

    /// <summary>Confirmed stalls inside the buyer's area for the rest of today and tomorrow: selling now first.</summary>
    [HttpGet("nearby")]
    public async Task<ActionResult<IEnumerable<NearbyStall>>> Nearby(CancellationToken ct)
    {
        var area = await AreaAsync(ct);
        if (area is null) return Array.Empty<NearbyStall>();
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

        var now = ArrivalRules.IndiaTime(DateTime.UtcNow);
        var nowTime = TimeOnly.FromDateTime(now);
        return rows
            .Where(r => r.b.Date > today || nowTime < r.b.To) // today's stalls drop off when their slot ends
            .Select(r =>
            {
                var selling = r.b.Date == today && r.b.ArrivedAt is not null && nowTime < r.b.To;
                return new NearbyStall(r.b.Id, r.b.Date, r.b.From, r.b.To, selling, r.Name, r.Village,
                    r.t.Produce.Select(p => new ProduceItem(p.CropCode, p.QuantityKg, p.PricePerKg)).ToArray(),
                    r.s.Title, r.s.Locality,
                    selling ? $"{r.s.Address}, {r.s.Locality}" : null,
                    selling ? r.s.Location.Y : null, selling ? r.s.Location.X : null,
                    Math.Round(r.Meters / 1000, 1));
            })
            .OrderByDescending(x => x.SellingNow).ThenBy(x => x.Date).ThenBy(x => x.From).ThenBy(x => x.DistanceKm)
            .ToList();
    }

    private Task<BuyerArea?> AreaAsync(CancellationToken ct) =>
        db.BuyerAreas.SingleOrDefaultAsync(a => a.UserId == User.UserId(), ct);

    private async Task<BuyerDto> DtoAsync(BuyerArea? a, CancellationToken ct)
    {
        var me = User.UserId();
        var hasEmail = await db.Users.AnyAsync(u => u.Id == me && u.Email != null, ct);
        return new BuyerDto(a is null ? null : new AreaDto(a.Location.Y, a.Location.X, a.RadiusKm, a.AlertsOn), hasEmail);
    }

    private static Point Point(AreaDto r) => Geo.CreatePoint(new Coordinate(r.Longitude, r.Latitude));
}
