namespace AanganMandi.Application.Storage;

/// <summary>Stores uploaded files. Local disk in development; Azure Blob (private containers) in production.</summary>
public interface IFileStorage
{
    /// <summary>Saves the stream under <paramref name="folder"/> and returns its relative path.</summary>
    Task<string> SaveAsync(Stream content, string folder, string extension, CancellationToken ct = default);

    /// <summary>Opens a stored file, or returns null if it does not exist.</summary>
    Stream? OpenRead(string path);
}
