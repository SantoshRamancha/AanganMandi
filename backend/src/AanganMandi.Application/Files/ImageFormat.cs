namespace AanganMandi.Application.Files;

/// <summary>
/// What an uploaded photo really is, read from its first bytes. The label a browser or phone sends is not trusted:
/// the web image picker re-draws a photo to shrink it, so an AVIF arrives as PNG bytes still labelled image/avif.
/// </summary>
public static class ImageFormat
{
    public sealed record Kind(string ContentType, string Extension);

    public static readonly Kind Jpeg = new("image/jpeg", ".jpg");
    public static readonly Kind Png = new("image/png", ".png");
    public static readonly Kind Webp = new("image/webp", ".webp");

    /// <summary>Bytes needed to recognise every accepted format.</summary>
    public const int HeaderLength = 12;

    /// <summary>JPEG, PNG or WebP; null for anything else (HEIC, AVIF, GIF, PDF, …).</summary>
    public static Kind? Detect(ReadOnlySpan<byte> head) =>
        head is [0xFF, 0xD8, 0xFF, ..] ? Jpeg :
        head is [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, ..] ? Png :
        head.Length >= 12 && head[..4].SequenceEqual("RIFF"u8) && head[8..12].SequenceEqual("WEBP"u8) ? Webp :
        null;

    /// <summary>Reads the start of <paramref name="stream"/> (the caller owns and disposes it).</summary>
    public static async Task<Kind?> DetectAsync(Stream stream, CancellationToken ct = default)
    {
        var head = new byte[HeaderLength];
        var read = await stream.ReadAtLeastAsync(head, HeaderLength, throwOnEndOfStream: false, ct);
        return Detect(head.AsSpan(0, read));
    }
}
