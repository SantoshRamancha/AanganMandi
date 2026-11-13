using AanganMandi.Application.Master;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Notifications;
using AanganMandi.Infrastructure.Persistence;
using AanganMandi.Infrastructure.Sharing;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// The public stall page behind a link a host shares with neighbours: /s/{code}. No login. Shows the farmer's first
/// name, village, crops and time; the exact address only while the farmer is checked in.
/// </summary>
[ApiController]
[ApiExplorerSettings(IgnoreApi = true)]
[Route("s")]
public class StallPageController(AppDbContext db, IOptions<NotificationOptions> options) : ControllerBase
{
    [HttpGet("{code}")]
    public async Task<IActionResult> Show(string code, [FromQuery] string? lang, CancellationToken ct)
    {
        if (!StallStatus.LooksLikeCode(code)) return NotFound();
        var row = await (
            from b in db.Bookings.AsNoTracking().IgnoreQueryFilters()
            where b.ShareCode == code && !b.IsDeleted
            join s in db.Spaces.AsNoTracking().IgnoreQueryFilters() on b.SpaceId equals s.Id
            join t in db.Trips.AsNoTracking().Include(t => t.Produce) on b.TripId equals t.Id
            join u in db.Users.AsNoTracking().IgnoreQueryFilters() on b.FarmerUserId equals u.Id
            join f in db.FarmerProfiles.AsNoTracking() on b.FarmerUserId equals f.UserId into fs
            from f in fs.DefaultIfEmpty()
            select new { b, s, t, u.Name, Village = f == null ? null : f.Village })
            .SingleOrDefaultAsync(ct);
        if (row is null) return NotFound();

        var language = StallPage.PickLanguage(lang, Request.Headers.AcceptLanguage.ToString());
        var state = row.s.IsDeleted ? StallState.Over : StallStatus.StateOf(row.b, ArrivalRules.IndiaTime(DateTime.UtcNow));
        var selling = state == StallState.SellingNow;
        var crops = await CropsAsync(row.t.Produce, language, ct);
        var view = new StallView(state, row.b.Date, row.b.From, row.b.To, FirstName(row.Name), row.Village, crops,
            row.s.Title, row.s.Locality,
            selling ? $"{row.s.Address}, {row.s.Locality}" : null,
            selling ? row.s.Location.Y : null, selling ? row.s.Location.X : null);

        // Short cache: the state changes when the farmer checks in or the slot ends.
        Response.Headers.CacheControl = "public, max-age=60";
        Response.Headers["Content-Security-Policy"] = "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'";
        Response.Headers["X-Content-Type-Options"] = "nosniff";
        Response.Headers["Referrer-Policy"] = "no-referrer";
        var html = StallPage.Render(view, language, $"{Request.Scheme}://{Request.Host}{Request.Path}", options.Value.AppUrl);
        return Content(html, "text/html; charset=utf-8");
    }

    private async Task<List<StallCrop>> CropsAsync(IEnumerable<TripProduce> produce, string lang, CancellationToken ct)
    {
        var items = produce.ToList();
        var codes = items.Select(p => p.CropCode).ToList();
        var names = await db.Crops.AsNoTracking().Where(c => codes.Contains(c.Code))
            .ToDictionaryAsync(c => c.Code, c => lang switch { "te" => c.NameTe, "hi" => c.NameHi, _ => c.NameEn }, ct);
        return items.Select(p => new StallCrop(
            CropCodes.IsCustom(p.CropCode) ? CropCodes.CustomName(p.CropCode) : names.GetValueOrDefault(p.CropCode, p.CropCode),
            p.PricePerKg)).ToList();
    }

    /// <summary>Only the first name goes on a public page.</summary>
    private static string FirstName(string? name) =>
        string.IsNullOrWhiteSpace(name) ? "–" : name.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries)[0];
}
