using AanganMandi.Api.Auth;
using AanganMandi.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// A host's "My earnings" and a farmer's "My stalls": their own stalls held, no-shows, fees, requests and ratings for
/// the last 30, 90 or 365 days. The numbers are worked out in <see cref="SummaryService"/>.
/// </summary>
[ApiController]
[Authorize]
public class SummaryController(SummaryService summaries) : ControllerBase
{
    [Authorize(Roles = "Host")]
    [HttpGet("api/v1/hosts/me/summary")]
    public Task<HostSummary> Host([FromQuery] int days = 30, CancellationToken ct = default) =>
        summaries.HostAsync(User.UserId(), days, ct);

    [Authorize(Roles = "Farmer")]
    [HttpGet("api/v1/farmers/me/summary")]
    public Task<FarmerSummary> Farmer([FromQuery] int days = 30, CancellationToken ct = default) =>
        summaries.FarmerAsync(User.UserId(), days, ct);
}
