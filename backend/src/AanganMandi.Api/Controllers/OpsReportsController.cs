using AanganMandi.Api.Auth;
using AanganMandi.Application.Notifications;
using AanganMandi.Domain.Support;
using AanganMandi.Infrastructure.Persistence;
using AanganMandi.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

/// <summary>Admins: problem reports from farmers, hosts and buyers; resolve with a note the reporter sees.</summary>
[ApiController]
[Authorize]
[StaffOnly(AdminOnly = true)]
[Route("api/v1/ops/reports")]
public class OpsReportsController(AppDbContext db, ReportService reports) : ControllerBase
{
    public record ReportRow(Guid Id, ReportCategory Category, string Message, ReportStatus Status, string? Resolution,
        DateTime CreatedAt, DateTime? ResolvedAt, string? ReporterName, string ReporterPhone, string[] ReporterRoles,
        Guid? BookingId, string? SpaceTitle, DateOnly? BookingDate, string? FarmerName, string? HostName);
    public record ResolveRequest(string? Resolution);

    /// <summary>status: Open (default, oldest first, so nothing waits too long) or Resolved (newest first).</summary>
    [HttpGet]
    public async Task<IEnumerable<ReportRow>> List([FromQuery] ReportStatus status = ReportStatus.Open, CancellationToken ct = default)
    {
        var rows = await (
            from r in db.ProblemReports.AsNoTracking()
            where r.Status == status
            join u in db.Users.AsNoTracking().IgnoreQueryFilters().Include(u => u.Roles) on r.ReporterUserId equals u.Id
            join b in db.Bookings.AsNoTracking() on r.BookingId equals b.Id into bs
            from b in bs.DefaultIfEmpty()
            join s in db.Spaces.AsNoTracking() on b.SpaceId equals s.Id into ss
            from s in ss.DefaultIfEmpty()
            join f in db.Users.AsNoTracking() on b.FarmerUserId equals f.Id into fs
            from f in fs.DefaultIfEmpty()
            join h in db.Users.AsNoTracking() on b.HostUserId equals h.Id into hs
            from h in hs.DefaultIfEmpty()
            select new { r, u, b, s, FarmerName = f == null ? null : f.Name, HostName = h == null ? null : h.Name })
            .ToListAsync(ct);
        var ordered = status == ReportStatus.Open ? rows.OrderBy(x => x.r.CreatedAt) : rows.OrderByDescending(x => x.r.ResolvedAt);
        return ordered.Select(x => new ReportRow(x.r.Id, x.r.Category, x.r.Message, x.r.Status, x.r.Resolution,
            x.r.CreatedAt, x.r.ResolvedAt, x.u.Name, x.u.Phone, x.u.Roles.Select(ro => ro.Role.ToString()).ToArray(),
            x.r.BookingId, x.s?.Title, x.b?.Date, x.FarmerName, x.HostName)).ToList();
    }

    /// <summary>Closes the report with a note the reporter sees in the app and by email.</summary>
    [HttpPost("{id:guid}/resolve")]
    public async Task<IActionResult> Resolve(Guid id, ResolveRequest req, CancellationToken ct)
    {
        await reports.ResolveAsync(User.UserId(), id, req.Resolution, ct);
        return NoContent();
    }
}
