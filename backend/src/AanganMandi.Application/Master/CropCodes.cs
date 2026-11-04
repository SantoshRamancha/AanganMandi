using System.Text.RegularExpressions;

namespace AanganMandi.Application.Master;

/// <summary>
/// Crop codes are master codes ("TOMATO") or, for a crop the farmer adds that is not in the list,
/// "custom:" plus the name they typed ("custom:Kakarakaya"). Custom names are kept as typed (any language).
/// </summary>
public static partial class CropCodes
{
    public const string CustomPrefix = "custom:";
    public const int MaxCrops = 30;

    public static bool IsCustom(string code) => code.StartsWith(CustomPrefix, StringComparison.Ordinal);

    public static string CustomName(string code) => code[CustomPrefix.Length..];

    /// <summary>2–30 characters: letters (any script, with their marks), spaces, dots, apostrophes, hyphens.</summary>
    [GeneratedRegex(@"^[\p{L}\p{M}][\p{L}\p{M} .'\-]{1,29}$")]
    private static partial Regex CustomNameRegex();

    /// <summary>
    /// Checks a crop list against the known master codes and tidies custom names (trimmed, single spaces).
    /// Returns the distinct codes in order, or the reason the list is not valid.
    /// </summary>
    public static (string[]? Codes, string? Error) Normalize(IEnumerable<string> codes, IReadOnlySet<string> known)
    {
        var result = new List<string>();
        foreach (var raw in codes)
        {
            var code = raw.Trim();
            if (IsCustom(code))
            {
                var name = Regex.Replace(CustomName(code).Trim(), @"\s+", " ");
                if (!CustomNameRegex().IsMatch(name)) return (null, "Crop names must be 2 to 30 letters");
                code = CustomPrefix + name;
            }
            else if (!known.Contains(code))
            {
                return (null, "Unknown crop code");
            }
            if (!result.Contains(code, StringComparer.OrdinalIgnoreCase)) result.Add(code);
        }
        return result.Count > MaxCrops ? (null, $"Choose at most {MaxCrops} crops") : (result.ToArray(), null);
    }
}
