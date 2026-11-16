namespace AanganMandi.Infrastructure;

/// <summary>Which browser origins may call the API (Cors:AllowedOrigins, plus localhost in Development).</summary>
public static class CorsOrigins
{
    /// <summary>
    /// True when <paramref name="origin"/> exactly matches a configured origin (scheme, host and port; a trailing
    /// slash in the setting is ignored), or is a localhost address and <paramref name="allowLoopback"/> is on.
    /// </summary>
    public static bool IsAllowed(string origin, IEnumerable<string> allowed, bool allowLoopback)
    {
        if (!Uri.TryCreate(origin, UriKind.Absolute, out var uri)) return false;
        if (allowLoopback && uri.IsLoopback) return true;
        return allowed.Any(a => Uri.TryCreate(a.TrimEnd('/'), UriKind.Absolute, out var ok)
            && string.Equals(ok.Scheme, uri.Scheme, StringComparison.OrdinalIgnoreCase)
            && string.Equals(ok.Host, uri.Host, StringComparison.OrdinalIgnoreCase)
            && ok.Port == uri.Port);
    }
}
