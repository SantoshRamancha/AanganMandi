namespace AanganMandi.Application.Master;

/// <summary>
/// Whether a farmer's produce is a crop a buyer is looking for. Master crops match by code; a crop typed in by hand
/// ("custom:Drumstick") matches the same name typed by the other side, or a master crop with that name in any of the
/// app's languages, ignoring case. Pure, so it can be unit-tested.
/// </summary>
public static class CropMatch
{
    /// <summary>The most crops a buyer can look for at once.</summary>
    public const int MaxWanted = 10;

    /// <param name="namesByCode">Each master crop's names (English, Telugu, Hindi).</param>
    public static bool Matches(string produceCode, IEnumerable<string> wanted,
        IReadOnlyDictionary<string, string[]> namesByCode)
    {
        var have = Keys(produceCode, namesByCode);
        return wanted.Any(w => Keys(w, namesByCode).Overlaps(have));
    }

    /// <summary>The produce codes among <paramref name="produce"/> that match any wanted crop, in their order.</summary>
    public static List<string> Matching(IEnumerable<string> produce, IReadOnlyCollection<string> wanted,
        IReadOnlyDictionary<string, string[]> namesByCode) =>
        wanted.Count == 0 ? [] : produce.Where(p => Matches(p, wanted, namesByCode)).ToList();

    /// <summary>"TOMATO,custom:Drumstick" ⇄ the saved list (null when empty).</summary>
    public static string? Join(IEnumerable<string> codes) => codes.Any() ? string.Join(',', codes) : null;

    public static string[] Split(string? saved) =>
        saved?.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries) ?? [];

    private static HashSet<string> Keys(string code, IReadOnlyDictionary<string, string[]> namesByCode)
    {
        var keys = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        if (CropCodes.IsCustom(code))
            keys.Add(CropCodes.CustomName(code).Trim());
        else
        {
            keys.Add("code:" + code);
            if (namesByCode.TryGetValue(code, out var names))
                foreach (var n in names) keys.Add(n.Trim());
        }
        return keys;
    }
}
