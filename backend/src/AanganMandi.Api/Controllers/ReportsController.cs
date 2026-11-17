using AanganMandi.Api.Auth;
using AanganMandi.Application.Notifications;
using AanganMandi.Domain.Support;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// "Report a problem" for any signed-in user, about one of their bookings or the app. Admins are emailed and handle
/// reports in Operations (OpsReportsController); the reporter sees the answer here and gets an email.
/// </summary>
[ApiController]
[Authorize]
[Route("api/v1/reports")]
public class ReportsController(AppDbContext db, INotifier notifier) : ControllerBase
{
    public record ReportRequest(ReportCategory Category, string Message, Guid? BookingId);
    public record ReportDto(Guid Id, ReportCategory Category, string Message, Guid? BookingId, string? SpaceTitle,
        DateOnly? BookingDate, ReportStatus Status, string? Resolution, DateTime CreatedAt, DateTime? ResolvedAt);

    [HttpPost]
    public async Task<ActionResult<ReportDto>> Create(ReportRequest req, CancellationToken ct)
    {
        var me = User.UserId();
        var since = DateTime.UtcNow.AddDays(-1);
        var filedToday = await db.ProblemReports.CountAsync(r => r.ReporterUserId == me && r.CreatedAt >= since, ct);
        if (ProblemReport.Check(req.Category, req.Message, filedToday) is { } error)
            return this.Fail(error.Code == "report_too_many" ? 429 : 400, error);
        if (req.BookingId is { } bookingId
            && !await db.Bookings.AnyAsync(b => b.Id == bookingId && (b.FarmerUserId == me || b.HostUserId == me), ct))
            return NotFound();

        var report = new ProblemReport
        {
            ReporterUserId = me, BookingId = req.BookingId, Category = req.Category, Message = req.Message.Trim(),
        };
        db.ProblemReports.Add(report);
        await db.SaveChangesAsync(ct);
        await notifier.ProblemReportedAsync(report.Id, ct);
        return (await MineAsync(me, report.Id, ct)).Single();
    }

    /// <summary>The user's own reports, newest first, with the team's answer once resolved.</summary>
    [HttpGet("mine")]
    public async Task<IEnumerable<ReportDto>> Mine(CancellationToken ct) => await MineAsync(User.UserId(), null, ct);

    private Task<List<ReportDto>> MineAsync(Guid me, Guid? only, CancellationToken ct) => (
        from r in db.ProblemReports.AsNoTracking()
        where r.ReporterUserId == me && (only == null || r.Id == only)
        join b in db.Bookings.AsNoTracking().IgnoreQueryFilters() on r.BookingId equals b.Id into bs
        from b in bs.DefaultIfEmpty()
        join s in db.Spaces.AsNoTracking().IgnoreQueryFilters() on b.SpaceId equals s.Id into ss
        from s in ss.DefaultIfEmpty()
        orderby r.CreatedAt descending
        select new ReportDto(r.Id, r.Category, r.Message, r.BookingId, s == null ? null : s.Title,
            b == null ? null : b.Date, r.Status, r.Resolution, r.CreatedAt, r.ResolvedAt)).ToListAsync(ct);
}
