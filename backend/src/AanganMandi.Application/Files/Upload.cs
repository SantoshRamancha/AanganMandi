namespace AanganMandi.Application.Files;

/// <summary>
/// An uploaded file as the services see it: its size and a way to read it (more than once: the first bytes are read
/// to tell the real image format, then the whole file is stored). The API wraps an IFormFile in one.
/// </summary>
public sealed record Upload(long Length, Func<Stream> Open);
