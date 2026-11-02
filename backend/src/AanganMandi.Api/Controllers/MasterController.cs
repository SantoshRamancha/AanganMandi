using AanganMandi.Infrastructure.Persistence;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

[ApiController]
[Route("api/v1/master")]
public class MasterController(AppDbContext db) : ControllerBase
{
    public record CropDto(string Code, string NameEn, string NameTe, string NameHi, string? Icon, string? Category);

    /// <summary>Crop list with names in all three languages (public).</summary>
    [HttpGet("crops")]
    public async Task<IEnumerable<CropDto>> Crops(CancellationToken ct) =>
        await db.Crops.OrderBy(c => c.NameEn)
            .Select(c => new CropDto(c.Code, c.NameEn, c.NameTe, c.NameHi, c.Icon, c.Category))
            .ToListAsync(ct);
}
