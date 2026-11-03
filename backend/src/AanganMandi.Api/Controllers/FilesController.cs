using AanganMandi.Application.Storage;
using Microsoft.AspNetCore.Mvc;

namespace AanganMandi.Api.Controllers;

/// <summary>Serves public space photos only. KYC and proof files (kyc/...) are never served by the API.</summary>
[ApiController]
[Route("api/v1/files")]
public class FilesController(IFileStorage storage) : ControllerBase
{
    [HttpGet("spaces/{**rest}")]
    [ResponseCache(Duration = 86400)]
    public IActionResult SpacePhoto(string rest)
    {
        var stream = storage.OpenRead($"spaces/{rest}");
        if (stream is null) return NotFound();
        var type = Path.GetExtension(rest).ToLowerInvariant() switch
        {
            ".png" => "image/png",
            ".webp" => "image/webp",
            _ => "image/jpeg",
        };
        return File(stream, type);
    }
}
