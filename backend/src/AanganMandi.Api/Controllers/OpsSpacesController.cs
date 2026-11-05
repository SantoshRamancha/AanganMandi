using AanganMandi.Api.Auth;
using AanganMandi.Application.Notifications;
using AanganMandi.Domain.Spaces;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

/// <summary>Space approvals for staff: any verifier or admin can review any space (no assignment yet).</summary>
[ApiController]
[Authorize]
[StaffOnly]
[Route("api/v1/ops/spaces")]
public class OpsSpacesController(AppDbContext db, INotifier notifier) : ControllerBase
{
    public record SpaceRow(Guid Id, string Title, SpaceType Type, string Locality, string HostName, DateTime UpdatedAt);
    public record SpaceDetail(Guid Id, string Title, SpaceType Type, string Address, string Locality, double Latitude,
        double Longitude, int AreaSqFt, string MaxStallSize, VehicleType MaxVehicle, Amenities[] Amenities, bool IsFree,
        decimal Fee, string? Rules, string[] AvailableDays, string OpenFrom, string OpenTo, SpaceStatus Status,
        string? RejectionReason, string HostName, string HostPhone, string? Proof, string[] Photos);
    public record DecisionRequest(bool Approve, string? Reason);

    [HttpGet]
    public Task<List<SpaceRow>> List([FromQuery] SpaceStatus status = SpaceStatus.PendingReview, CancellationToken ct = default) =>
        (from s in db.Spaces
         join u in db.Users on s.HostUserId equals u.Id
         where s.Status == status
         orderby s.UpdatedAt
         select new SpaceRow(s.Id, s.Title, s.Type, s.Locality, u.Name ?? u.Phone, s.UpdatedAt)).ToListAsync(ct);

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<SpaceDetail>> Get(Guid id, CancellationToken ct)
    {
        var s = await db.Spaces.Include(x => x.Photos).SingleOrDefaultAsync(x => x.Id == id, ct);
        if (s is null) return NotFound();
        var host = await db.Users.SingleAsync(u => u.Id == s.HostUserId, ct);
        return new SpaceDetail(s.Id, s.Title, s.Type, s.Address, s.Locality, s.Location.Y, s.Location.X, s.AreaSqFt,
            s.MaxStallSize, s.MaxVehicle,
            Enum.GetValues<Amenities>().Where(a => a != Amenities.None && s.Amenities.HasFlag(a)).ToArray(),
            s.IsFree, s.Fee, s.Rules, s.AvailableDays.Split(',', StringSplitOptions.RemoveEmptyEntries),
            s.OpenFrom.ToString("HH:mm"), s.OpenTo.ToString("HH:mm"), s.Status, s.RejectionReason,
            host.Name ?? "(no name)", host.Phone,
            s.Photos.FirstOrDefault(p => p.IsRightToUseProof)?.FilePath,
            s.Photos.Where(p => !p.IsRightToUseProof).OrderBy(p => p.CreatedAt).Select(p => p.FilePath).ToArray());
    }

    [HttpPost("{id:guid}/decision")]
    public async Task<IActionResult> Decide(Guid id, DecisionRequest req, CancellationToken ct)
    {
        var reason = string.IsNullOrWhiteSpace(req.Reason) ? null : req.Reason.Trim();
        if (!req.Approve && reason is null) return Problem(statusCode: 400, title: "Give a reason to reject; the host sees it");
        if (reason?.Length > 500) return Problem(statusCode: 400, title: "Keep the reason under 500 characters");

        var s = await db.Spaces.SingleOrDefaultAsync(x => x.Id == id, ct);
        if (s is null) return NotFound();
        if (s.Status != SpaceStatus.PendingReview) return Problem(statusCode: 409, title: "This space was already reviewed");
        s.Status = req.Approve ? SpaceStatus.Live : SpaceStatus.Rejected;
        s.RejectionReason = req.Approve ? null : reason;
        s.ReviewedAt = DateTime.UtcNow;
        s.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        await notifier.SpaceDecidedAsync(s.Id, ct);
        return NoContent();
    }
}
