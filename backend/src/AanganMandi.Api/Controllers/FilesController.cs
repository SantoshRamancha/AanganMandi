using AanganMandi.Application.Storage;
using AanganMandi.Infrastructure;
using Microsoft.AspNetCore.Mvc;

namespace AanganMandi.Api.Controllers;

/// <summary>Serves public space photos only. KYC and proof files (kyc/...) are never served by the API.</summary>
[ApiController]
[Route("api/v1/files")]
public class FilesController(IFileStorage storage) : ControllerBase
{
    [HttpGet("spaces/{**rest}")]
    [ResponseCache(Duration = 86400)]
    public async Task<IActionResult> SpacePhoto(string rest, CancellationToken ct)
    {
        if (rest.Contains("..") || rest.Contains('\\')) return NotFound();
        var stream = await storage.OpenReadAsync($"spaces/{rest}", ct);
        return stream is null ? NotFound() : File(stream, ContentTypes.ForPath(rest));
    }
}
