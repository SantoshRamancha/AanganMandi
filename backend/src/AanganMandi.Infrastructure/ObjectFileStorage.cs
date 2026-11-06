using AanganMandi.Application.Storage;
using StorageProvider;

namespace AanganMandi.Infrastructure;

/// <summary>
/// Storage in the product's object storage bucket (Storage:Provider = Object), through StorageProvider.
/// The database keeps the same relative paths as on disk ("spaces/{id}/{file}.jpg"); in the bucket they sit under
/// <paramref name="keyPrefix"/> when one is set (e.g. "dev"), so development files never mix with production ones.
/// The bucket is private: the API streams every file, and KYC proofs stay behind the staff-only endpoints.
/// </summary>
public class ObjectFileStorage(IStorageProvider bucket, string? keyPrefix) : IFileStorage
{
    private readonly string _prefix = string.IsNullOrWhiteSpace(keyPrefix) ? "" : StorageKey.Combine(keyPrefix);

    public async Task<string> SaveAsync(Stream content, string folder, string extension, CancellationToken ct = default)
    {
        var relative = StorageKey.Combine(folder, $"{Guid.NewGuid():N}{extension}");
        await bucket.UploadAsync(Key(relative), content, ContentTypes.ForPath(relative), ct);
        return relative;
    }

    public async Task<Stream?> OpenReadAsync(string path, CancellationToken ct = default) =>
        (await bucket.DownloadAsync(Key(path), ct))?.Content;

    public Task DeleteAsync(string path, CancellationToken ct = default) => bucket.DeleteAsync(Key(path), ct);

    /// <summary>The bucket key for a stored relative path; rejects "..", absolute paths and backslashes.</summary>
    public string Key(string relative)
    {
        StorageKey.Validate(relative);
        return _prefix.Length == 0 ? relative : $"{_prefix}/{relative}";
    }
}

/// <summary>Content type from a stored file's extension (uploads are saved as .jpg, .png or .webp).</summary>
public static class ContentTypes
{
    public static string ForPath(string path) => Path.GetExtension(path).ToLowerInvariant() switch
    {
        ".png" => "image/png",
        ".webp" => "image/webp",
        ".pdf" => "application/pdf",
        _ => "image/jpeg",
    };
}
