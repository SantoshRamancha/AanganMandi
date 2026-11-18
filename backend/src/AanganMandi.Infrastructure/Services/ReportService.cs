using AanganMandi.Application.Notifications;
using AanganMandi.Domain.Common;
using AanganMandi.Domain.Support;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Infrastructure.Services;

/// <summary>"Report a problem": any user files one (about their own booking, or the app); an admin resolves it.</summary>
public class ReportService(AppDbContext db, INotifier notifier)
{
    public async Task<ProblemReport> CreateAsync(Guid userId, ReportCategory category, string? message, Guid? bookingId,
        CancellationToken ct)
    {
        var since = DateTime.UtcNow.AddDays(-1);
        var filedToday = await db.ProblemReports.CountAsync(r => r.ReporterUserId == userId && r.CreatedAt >= since, ct);
        if (ProblemReport.Check(category, message, filedToday) is { } error)
            throw new ApiException(error.Code == "report_too_many" ? 429 : 400, error);
        if (bookingId is { } id && !await db.Bookings.AnyAsync(b => b.Id == id && (b.FarmerUserId == userId || b.HostUserId == userId), ct))
            throw ApiException.NotFound();

        var report = new ProblemReport { ReporterUserId = userId, BookingId = bookingId, Category = category, Message = message!.Trim() };
        db.ProblemReports.Add(report);
        await db.SaveChangesAsync(ct);
        await notifier.ProblemReportedAsync(report.Id, ct);
        return report;
    }

    /// <summary>Admin: closes the report with a note the reporter sees in the app and by email.</summary>
    public async Task ResolveAsync(Guid adminId, Guid reportId, string? resolution, CancellationToken ct)
    {
        var report = await db.ProblemReports.SingleOrDefaultAsync(r => r.Id == reportId, ct) ?? throw ApiException.NotFound();
        if (report.Status == ReportStatus.Resolved) throw ApiException.Conflict("report_already_resolved");
        var note = resolution?.Trim() ?? "";
        if (note.Length == 0) throw ApiException.BadRequest("report_resolution_required");
        if (note.Length > ProblemReport.MaxResolution) throw ApiException.BadRequest("reason_too_long", ("max", ProblemReport.MaxResolution));
        report.Status = ReportStatus.Resolved;
        report.Resolution = note;
        report.ResolvedAt = report.UpdatedAt = DateTime.UtcNow;
        report.ResolvedBy = adminId;
        await db.SaveChangesAsync(ct);
        await notifier.ProblemResolvedAsync(report.Id, ct);
    }
}
