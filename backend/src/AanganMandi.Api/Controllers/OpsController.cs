using AanganMandi.Api.Auth;
using AanganMandi.Application.Storage;
using AanganMandi.Domain.Farmers;
using AanganMandi.Domain.Identity;
using AanganMandi.Domain.Spaces;
using AanganMandi.Infrastructure;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

/// <summary>Staff home: the dashboard counts, and private files (KYC, land and space proofs) for review.</summary>
[ApiController]
[Authorize]
[StaffOnly]
[Route("api/v1/ops")]
public class OpsController(AppDbContext db, IFileStorage storage) : ControllerBase
{
    public record DashboardDto(string? Name, bool IsAdmin, int FarmersWaiting, int FarmersUnassigned, int FarmersVerified,
        int Verifiers, int SpacesWaiting, int SpacesLive);

    [HttpGet("dashboard")]
    public async Task<DashboardDto> Dashboard(CancellationToken ct)
    {
        var userId = User.UserId();
        var isAdmin = StaffAccessFilter.IsAdmin(HttpContext);
        // Verifiers count only the farmers routed to them.
        var farmers = isAdmin ? db.FarmerProfiles : db.FarmerProfiles.Where(f => f.AssignedVerifierId == userId);
        return new DashboardDto(
            await db.Users.Where(u => u.Id == userId).Select(u => u.Name).SingleAsync(ct),
            isAdmin,
            await farmers.CountAsync(f => f.Status == VerificationStatus.Pending, ct),
            isAdmin ? await db.FarmerProfiles.CountAsync(f => f.Status == VerificationStatus.Pending && f.AssignedVerifierId == null, ct) : 0,
            await farmers.CountAsync(f => f.Status == VerificationStatus.Verified, ct),
            isAdmin ? await db.UserRoles.CountAsync(r => r.Role == Role.Verifier, ct) : 0,
            await db.Spaces.CountAsync(s => s.Status == SpaceStatus.PendingReview, ct),
            await db.Spaces.CountAsync(s => s.Status == SpaceStatus.Live, ct));
    }

    /// <summary>Any stored file, private ones included, for staff only. Paths come from the review endpoints.</summary>
    [HttpGet("files/{**path}")]
    public async Task<IActionResult> GetFile(string path, CancellationToken ct)
    {
        if (path.Contains("..") || path.Contains('\\') || !(path.StartsWith("kyc/") || path.StartsWith("spaces/"))) return NotFound();
        var stream = await storage.OpenReadAsync(path, ct);
        if (stream is null) return NotFound();
        Response.Headers.CacheControl = "private, max-age=3600";
        return File(stream, ContentTypes.ForPath(path));
    }
}
