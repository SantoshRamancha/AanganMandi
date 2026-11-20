namespace AanganMandi.Application.Analytics;

/// <summary>One confirmed stall, as the host and farmer summaries count it.</summary>
public sealed record StallRow(Guid SpaceId, Guid TripId, DateOnly Date, decimal Fee, bool Held, bool NoShow);

/// <summary>Held: the farmer checked in. NoShows: marked by the host. Fees: the fees of the held stalls, in rupees.</summary>
public sealed record StallTally(int Held, int NoShows, decimal Fees);

/// <summary>
/// Pure helpers for the "My earnings" (host) and "My stalls" (farmer) summaries (no database), so they can be
/// unit-tested. A period ends today, in India dates, like the admin analytics (<see cref="AnalyticsRules"/>).
/// </summary>
public static class SummaryRules
{
    /// <summary>The periods a host or farmer can pick, in days, ending today.</summary>
    public static readonly int[] Periods = [30, 90, 365];

    /// <summary>How many rows the "crops" and "places" lists show.</summary>
    public const int TopCount = 5;

    /// <summary>Stalls held, no-shows and the fees of the held stalls.</summary>
    public static StallTally Tally(IEnumerable<StallRow> stalls)
    {
        var list = stalls.ToList();
        return new StallTally(list.Count(s => s.Held), list.Count(s => s.NoShow), list.Where(s => s.Held).Sum(s => s.Fee));
    }

    /// <summary>Confirmed stalls still to come: today or later, the farmer not checked in or marked absent yet.</summary>
    public static bool IsUpcoming(StallRow s, DateOnly today) => s.Date >= today && !s.Held && !s.NoShow;

    /// <summary>The most frequent keys (ignoring case and spaces at the ends), most first, then by name.</summary>
    public static List<(string Key, int Count)> Top(IEnumerable<string> keys, int count = TopCount) =>
        [.. keys.Select(k => k.Trim()).Where(k => k.Length > 0)
            .GroupBy(k => k, StringComparer.OrdinalIgnoreCase)
            .Select(g => (Key: g.First(), Count: g.Count()))
            .OrderByDescending(t => t.Count).ThenBy(t => t.Key, StringComparer.OrdinalIgnoreCase).Take(count)];
}
