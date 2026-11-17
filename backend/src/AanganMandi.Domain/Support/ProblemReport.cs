using AanganMandi.Domain.Common;

namespace AanganMandi.Domain.Support;

public enum ReportCategory { NoShow, SpaceProblem, PaymentDispute, Behaviour, AppProblem, Other }

public enum ReportStatus { Open, Resolved }

/// <summary>
/// "Report a problem": a farmer, host or buyer tells the team about a booking (or the app). Admins see open reports
/// in Operations, resolve them with a note, and the reporter is told.
/// </summary>
public class ProblemReport : Entity
{
    public Guid ReporterUserId { get; set; }
    /// <summary>The booking it is about, when reported from a booking (the reporter is its farmer or host).</summary>
    public Guid? BookingId { get; set; }
    public ReportCategory Category { get; set; }
    public required string Message { get; set; }
    public ReportStatus Status { get; set; } = ReportStatus.Open;
    /// <summary>What the team did, shown to the reporter.</summary>
    public string? Resolution { get; set; }
    public DateTime? ResolvedAt { get; set; }
    public Guid? ResolvedBy { get; set; }

    public const int MinMessage = 10, MaxMessage = 1000, MaxResolution = 500, MaxPerDay = 10;

    /// <summary>Null when the report can be filed, else why not.</summary>
    public static ApiError? Check(ReportCategory category, string? message, int filedToday)
    {
        if (!Enum.IsDefined(category)) return new("report_category_required");
        var m = message?.Trim() ?? "";
        if (m.Length < MinMessage) return ApiError.Of("report_message_short", ("min", MinMessage));
        if (m.Length > MaxMessage) return ApiError.Of("report_message_long", ("max", MaxMessage));
        if (filedToday >= MaxPerDay) return new("report_too_many");
        return null;
    }
}
