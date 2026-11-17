using System.Text.RegularExpressions;

namespace AanganMandi.Application.Identity;

/// <summary>Indian mobile numbers, stored as "+91" and 10 digits (the first digit 6–9).</summary>
public static partial class PhoneNumbers
{
    [GeneratedRegex(@"^[6-9]\d{9}$")]
    private static partial Regex TenDigits();

    /// <summary>
    /// "+91 90000-12345", "919000012345" or "9000012345" → "+919000012345"; or the reason it is not a mobile number.
    /// </summary>
    public static (string? Phone, string? Error) Normalize(string? input)
    {
        var digits = new string((input ?? "").Where(char.IsDigit).ToArray());
        if (digits.Length == 12 && digits.StartsWith("91")) digits = digits[2..];
        return TenDigits().IsMatch(digits)
            ? ("+91" + digits, null)
            : (null, "Enter a 10-digit Indian mobile number");
    }
}
