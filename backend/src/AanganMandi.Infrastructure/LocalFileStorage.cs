using AanganMandi.Application.Storage;

namespace AanganMandi.Infrastructure;

/// <summary>Development storage on local disk. Paths are relative ("kyc/{user}/{file}.jpg") and never leave the root.</summary>
public class LocalFileStorage(string root) : IFileStorage
{
    public async Task<string> SaveAsync(Stream content, string folder, string extension, CancellationToken ct = default)
    {
        var relative = $"{folder.Trim('/')}/{Guid.NewGuid():N}{extension}";
        var full = Resolve(relative);
        Directory.CreateDirectory(Path.GetDirectoryName(full)!);
        await using var file = File.Create(full);
        await content.CopyToAsync(file, ct);
        return relative;
    }

    public Stream? OpenRead(string path)
    {
        var full = Resolve(path);
        return File.Exists(full) ? File.OpenRead(full) : null;
    }

    private string Resolve(string relative)
    {
        var full = Path.GetFullPath(Path.Combine(root, relative));
        if (!full.StartsWith(Path.GetFullPath(root), StringComparison.OrdinalIgnoreCase))
            throw new UnauthorizedAccessException("Path escapes the storage root.");
        return full;
    }
}
