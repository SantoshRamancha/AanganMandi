using AanganMandi.Domain.Common;

namespace AanganMandi.Domain.Spaces;

/// <summary>
/// A day a host closes their space although it is normally open that weekday (a family function, travel, repairs).
/// Farmers do not find the space for that day and cannot request it. One row per space and date.
/// </summary>
public class SpaceBlockedDate : Entity
{
    public Guid SpaceId { get; set; }
    public DateOnly Date { get; set; }
    /// <summary>The host's own note ("Wedding at home"); also the reason on requests declined by blocking.</summary>
    public string? Note { get; set; }
}

/// <summary>Pure rules for blocking dates (no database), so they can be unit-tested.</summary>
public static class BlockedDateRules
{
    public const int MaxNote = 100;

    /// <summary>How far ahead a date can be blocked: the same as how far ahead farmers can plan.</summary>
    public const int MaxDaysAhead = 60;

    /// <summary>The reason pending requests get when the host blocks their day without a note.</summary>
    public const string DefaultReason = "The host is not available that day";

    /// <summary>Null when the date can be blocked (today up to <see cref="MaxDaysAhead"/> days on), else why not.</summary>
    public static ApiError? Check(DateOnly date, DateOnly today, string? note)
    {
        if (date < today) return new("block_date_past");
        if (date > today.AddDays(MaxDaysAhead)) return ApiError.Of("block_date_too_far", ("days", MaxDaysAhead));
        if (note?.Trim().Length > MaxNote) return ApiError.Of("block_note_long", ("max", MaxNote));
        return null;
    }
}
