namespace AanganMandi.Application.Storage;

/// <summary>
/// Stores uploaded files (KYC proofs, space photos). Local disk, or the product's object storage bucket
/// (Storage:Provider = Object). Paths are relative, e.g. "kyc/{user}/{file}.jpg", and are what the database keeps.
/// </summary>
public interface IFileStorage
{
    /// <summary>Saves the stream under <paramref name="folder"/> and returns its relative path.</summary>
    Task<string> SaveAsync(Stream content, string folder, string extension, CancellationToken ct = default);

    /// <summary>Opens a stored file, or returns null if it does not exist. The caller disposes the stream.</summary>
    Task<Stream?> OpenReadAsync(string path, CancellationToken ct = default);

    /// <summary>Removes a stored file; a missing file is not an error.</summary>
    Task DeleteAsync(string path, CancellationToken ct = default);
}
