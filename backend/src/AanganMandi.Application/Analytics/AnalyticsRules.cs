namespace AanganMandi.Application.Analytics;

/// <summary>Pure helpers for the admin analytics (no database), so they can be unit-tested.</summary>
public static class AnalyticsRules
{
    /// <summary>The periods an admin can pick, in days, ending today.</summary>
    public static readonly int[] Periods = [7, 30, 90];

    /// <summary>How many rows the "top crops" and "top areas" lists show.</summary>
    public const int TopCount = 8;

    /// <summary>India is UTC+5:30 all year.</summary>
    private static readonly TimeSpan IndiaOffset = TimeSpan.FromHours(5.5);

    /// <summary>The first and last day (India dates) of a period of <paramref name="days"/> ending today.</summary>
    public static (DateOnly From, DateOnly To) Range(int days, DateOnly today) => (today.AddDays(1 - days), today);

    /// <summary>The UTC instant an India date starts, for comparing with UTC timestamps.</summary>
    public static DateTime StartUtc(DateOnly indiaDate) =>
        DateTime.SpecifyKind(indiaDate.ToDateTime(TimeOnly.MinValue) - IndiaOffset, DateTimeKind.Utc);

    /// <summary>The India date of a UTC timestamp.</summary>
    public static DateOnly IndiaDate(DateTime utc) => DateOnly.FromDateTime(utc + IndiaOffset);

    /// <summary>Part of a whole in whole percent, or null when there is nothing to divide (shown as "–").</summary>
    public static int? Percent(int part, int whole) => whole <= 0 ? null : (int)Math.Round(100.0 * part / whole);

    /// <summary>Every day from <paramref name="from"/> to <paramref name="to"/>, so days with nothing show as zero.</summary>
    public static IEnumerable<DateOnly> Days(DateOnly from, DateOnly to)
    {
        for (var d = from; d <= to; d = d.AddDays(1)) yield return d;
    }
}
