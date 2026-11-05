using System.Net.Mail;

namespace AanganMandi.Application.Identity;

public static class EmailAddresses
{
    /// <summary>
    /// Trims and lower-cases a typed email address. Empty means "no email" (null, no error).
    /// Returns an error for anything that is not a plain name@domain.tld address.
    /// </summary>
    public static (string? Email, string? Error) Normalize(string? input)
    {
        var email = input?.Trim().ToLowerInvariant();
        if (string.IsNullOrEmpty(email)) return (null, null);
        var valid = email.Length <= 256
            && MailAddress.TryCreate(email, out var parsed)
            && parsed.Address == email // no display names or comments
            && parsed.Host.Contains('.') && !parsed.Host.EndsWith('.');
        return valid ? (email, null) : (null, "Enter a valid email address, like name@example.com");
    }
}
