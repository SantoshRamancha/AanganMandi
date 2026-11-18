using AanganMandi.Api.Auth;
using AanganMandi.Domain.Identity;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Persistence;
using AanganMandi.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// Ratings after a stall: the booking's farmer rates the space, its host rates the farmer (1–5 stars and an optional
/// comment, once each, within 14 days). Plus each user's own record, for the profile screen.
/// </summary>
[ApiController]
[Authorize]
[Route("api/v1")]
public class RatingsController(AppDbContext db, RatingService ratings) : ControllerBase
{
    public record RatingRequest(int Stars, string? Comment);
    public record RatingDto(Guid BookingId, string By, int Stars, string? Comment, DateTime CreatedAt);
    /// <summary>As a farmer: hosts' stars, stalls, recent no-shows (and the limit). As a host: farmers' stars.</summary>
    public record MyRecord(FarmerSide? AsFarmer, HostSide? AsHost);
    public record FarmerSide(double? Rating, int RatingCount, int CompletedStalls, int RecentNoShows, int NoShowLimit,
        int NoShowWindowDays);
    public record HostSide(double? Rating, int RatingCount);

    /// <summary>Rates the booking as its farmer (about the space) or its host (about the farmer).</summary>
    [HttpPost("bookings/{id:guid}/rating")]
    public async Task<RatingDto> Rate(Guid id, RatingRequest req, CancellationToken ct)
    {
        var r = await ratings.RateAsync(User.UserId(), id, req.Stars, req.Comment, ct);
        return new RatingDto(r.BookingId, r.By.ToString(), r.Stars, r.Comment, r.CreatedAt);
    }

    [HttpGet("users/me/record")]
    public async Task<MyRecord> Mine(CancellationToken ct)
    {
        var me = User.UserId();
        var roles = await db.UserRoles.Where(r => r.UserId == me).Select(r => r.Role).ToListAsync(ct);
        FarmerSide? farmer = null;
        HostSide? host = null;
        if (roles.Contains(Role.Farmer))
        {
            var f = await ratings.FarmerRecordAsync(me, ct);
            farmer = new FarmerSide(f.Average, f.Ratings, f.Completed, f.RecentNoShows, NoShowPolicy.Limit, NoShowPolicy.WindowDays);
        }
        if (roles.Contains(Role.Host))
        {
            var h = await ratings.HostStarsAsync(me, ct);
            host = new HostSide(h.Average, h.Count);
        }
        return new MyRecord(farmer, host);
    }
}
