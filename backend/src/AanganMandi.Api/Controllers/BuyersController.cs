using AanganMandi.Api.Auth;
using AanganMandi.Application.Master;
using AanganMandi.Domain.Buyers;
using AanganMandi.Infrastructure.Persistence;
using AanganMandi.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// Buyers save where they live and how far they will go (1, 2 or 5 km), then see verified farmers selling inside that
/// area today and tomorrow, and get email alerts the evening before and when a farmer arrives. The exact address is
/// shown only while the farmer is there; until then, the area. The rules are in <see cref="BuyerService"/>.
/// </summary>
[ApiController]
[Authorize(Roles = "Buyer")]
[Route("api/v1/buyers/me")]
public class BuyersController(AppDbContext db, BuyerService buyers) : ControllerBase
{
    /// <summary>Crops: what the buyer is looking for (empty for any); changed with PUT crops, ignored here on save.</summary>
    public record AreaDto(double Latitude, double Longitude, int RadiusKm, bool AlertsOn, string[]? Crops = null);
    public record CropsRequest(string[]? Crops);
    /// <summary>Area is null until the buyer saves one. HasEmail: alerts need an email address in the profile.</summary>
    public record BuyerDto(AreaDto? Area, bool HasEmail);
    public record ProduceItem(string CropCode, decimal? QuantityKg, decimal? PricePerKg);
    /// <summary>
    /// One farmer's stall inside the buyer's area. SellingNow: checked in and the slot is running. Address and position
    /// only while selling now. Matched: the crop codes in Produce the buyer is looking for (empty when looking for any).
    /// </summary>
    public record NearbyStall(Guid BookingId, DateOnly Date, TimeOnly From, TimeOnly To, bool SellingNow,
        string? FarmerName, string? Village, ProduceItem[] Produce, string SpaceTitle, string Locality,
        string? Address, double? Latitude, double? Longitude, double DistanceKm, string[] Matched);

    [HttpGet]
    public async Task<BuyerDto> Get(CancellationToken ct) => await DtoAsync(await buyers.GetAreaAsync(User.UserId(), ct), ct);

    [HttpPut("area")]
    public async Task<BuyerDto> SaveArea(AreaDto req, CancellationToken ct) =>
        await DtoAsync(await buyers.SaveAreaAsync(User.UserId(), req.Latitude, req.Longitude, req.RadiusKm, req.AlertsOn, ct), ct);

    /// <summary>
    /// The crops the buyer is looking for (master codes or "custom:&lt;name&gt;", up to 10; empty for any). The nearby
    /// list and the alerts then show only farmers selling one of them. Needs a saved area.
    /// </summary>
    [HttpPut("crops")]
    public async Task<BuyerDto> SaveCrops(CropsRequest req, CancellationToken ct) =>
        await DtoAsync(await buyers.SetCropsAsync(User.UserId(), req.Crops, ct), ct);

    /// <summary>Forgets the saved area: no nearby list and no alerts.</summary>
    [HttpDelete("area")]
    public async Task<IActionResult> DeleteArea(CancellationToken ct)
    {
        await buyers.DeleteAreaAsync(User.UserId(), ct);
        return NoContent();
    }

    /// <summary>
    /// Confirmed stalls inside the buyer's area for the rest of today and tomorrow: selling now first. Only those selling
    /// a crop the buyer looks for: ?crops=TOMATO&amp;crops=ONION when given (?crops= for any), else the saved crops.
    /// </summary>
    [HttpGet("nearby")]
    public async Task<IEnumerable<NearbyStall>> Nearby([FromQuery] string[]? crops, CancellationToken ct)
    {
        var filter = Request.Query.ContainsKey("crops") ? crops?.Where(c => !string.IsNullOrWhiteSpace(c)).ToArray() ?? [] : null;
        return (await buyers.NearbyAsync(User.UserId(), filter, ct)).Select(s => new NearbyStall(s.BookingId, s.Date, s.From,
            s.To, s.SellingNow, s.FarmerName, s.Village,
            s.Produce.Select(p => new ProduceItem(p.CropCode, p.QuantityKg, p.PricePerKg)).ToArray(),
            s.SpaceTitle, s.Locality, s.Address, s.Latitude, s.Longitude, s.DistanceKm, s.Matched.ToArray())).ToList();
    }

    private async Task<BuyerDto> DtoAsync(BuyerArea? a, CancellationToken ct)
    {
        var me = User.UserId();
        var hasEmail = await db.Users.AnyAsync(u => u.Id == me && u.Email != null, ct);
        return new BuyerDto(a is null ? null
            : new AreaDto(a.Location.Y, a.Location.X, a.RadiusKm, a.AlertsOn, CropMatch.Split(a.Crops)), hasEmail);
    }
}
