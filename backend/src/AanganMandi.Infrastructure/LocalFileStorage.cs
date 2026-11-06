using AanganMandi.Application.Storage;

namespace AanganMandi.Infrastructure;

/// <summary>Storage on local disk (Storage:Provider = Local). Paths are relative ("kyc/{user}/{file}.jpg") and never leave the root.</summary>
public class LocalFileStorage(string root) : IFileStorage
{
    public string Root { get; } = Path.GetFullPath(root);

    public async Task<string> SaveAsync(Stream content, string folder, string extension, CancellationToken ct = default)
    {
        var relative = $"{folder.Trim('/')}/{Guid.NewGuid():N}{extension}";
        var full = Resolve(relative);
        Directory.CreateDirectory(Path.GetDirectoryName(full)!);
        await using var file = File.Create(full);
        await content.CopyToAsync(file, ct);
        return relative;
    }

    public Task<Stream?> OpenReadAsync(string path, CancellationToken ct = default)
    {
        var full = Resolve(path);
        return Task.FromResult<Stream?>(File.Exists(full) ? File.OpenRead(full) : null);
    }

    public Task DeleteAsync(string path, CancellationToken ct = default)
    {
        var full = Resolve(path);
        if (File.Exists(full)) File.Delete(full);
        return Task.CompletedTask;
    }

    private string Resolve(string relative)
    {
        var full = Path.GetFullPath(Path.Combine(Root, relative));
        if (!full.StartsWith(Path.TrimEndingDirectorySeparator(Root) + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase))
            throw new UnauthorizedAccessException("Path escapes the storage root.");
        return full;
    }
}
