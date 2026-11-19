using AanganMandi.Api.Auth;
using AanganMandi.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// Admin analytics: people, requests and how hosts answer them, stalls held and no-shows, ratings, problem reports, a
/// day-by-day series and the top crops and areas, for the last 7, 30 or 90 days. Figures only; no names or phones.
/// The numbers are worked out in <see cref="AnalyticsService"/>.
/// </summary>
[ApiController]
[Authorize]
[StaffOnly(AdminOnly = true)]
[Route("api/v1/ops/analytics")]
public class OpsAnalyticsController(AnalyticsService analytics) : ControllerBase
{
    [HttpGet]
    public Task<Analytics> Get([FromQuery] int days = 30, CancellationToken ct = default) => analytics.GetAsync(days, ct);
}
