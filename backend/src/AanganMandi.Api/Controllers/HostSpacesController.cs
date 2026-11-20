using AanganMandi.Api.Auth;
using AanganMandi.Application.Files;
using AanganMandi.Domain.Spaces;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// Host flow: create a draft space, add 3–8 photos and a right-to-use proof, submit for admin review. The rules are
/// in <see cref="SpaceService"/>.
/// </summary>
[ApiController]
[Authorize(Roles = "Host")]
[Route("api/v1/hosts/me/spaces")]
public class HostSpacesController(SpaceService spaces, RatingService ratings, BlockedDateService blocked) : ControllerBase
{
    public record SpaceRequest(string Title, SpaceType Type, string Address, string Locality,
        double Latitude, double Longitude, int AreaSqFt, string MaxStallSize, VehicleType MaxVehicle,
        Amenities[] Amenities, bool IsFree, decimal Fee, string? Rules, DayOfWeek[] AvailableDays,
        TimeOnly OpenFrom, TimeOnly OpenTo);
    /// <summary>Rating: farmers' average stars for this space (null until rated), from RatingCount ratings.</summary>
    public record SpaceDto(Guid Id, string Title, SpaceType Type, string Address, string Locality,
        double Latitude, double Longitude, int AreaSqFt, string MaxStallSize, VehicleType MaxVehicle,
        Amenities[] Amenities, bool IsFree, decimal Fee, string? Rules, DayOfWeek[] AvailableDays,
        TimeOnly OpenFrom, TimeOnly OpenTo, SpaceStatus Status, string? RejectionReason,
        string[] PhotoUrls, bool HasProof, FileRef[] Photos, FileRef? Proof, double? Rating, int RatingCount);
    /// <summary>One stored photo or proof; Id is used to preview, download, replace or delete it.</summary>
    public record FileRef(Guid Id, DateTime UploadedAt);
    /// <summary>Withdrawn: the change left a waiting space incomplete, so it went back to Draft.</summary>
    public record DocumentChange(bool Withdrawn);
    /// <summary>How many upcoming bookings deleting the space cancelled.</summary>
    public record SpaceDeleted(int CancelledBookings);
    public record BlockRequest(DateOnly Date, string? Note);
    /// <summary>A day the host closed the space. DeclinedRequests: waiting requests for it declined by blocking.</summary>
    public record BlockedDateDto(DateOnly Date, string? Note, int DeclinedRequests = 0);

    private const long UploadLimit = SpaceService.MaxUploadBytes + 64 * 1024;

    [HttpGet]
    public async Task<IEnumerable<SpaceDto>> List(CancellationToken ct)
    {
        var mine = await spaces.ListAsync(User.UserId(), ct);
        var stars = await ratings.SpaceStarsAsync(mine.Select(s => s.Id).ToList(), ct);
        return mine.Select(s => ToDto(s, stars.GetValueOrDefault(s.Id)));
    }

    [HttpGet("{id:guid}")]
    public async Task<SpaceDto> Get(Guid id, CancellationToken ct) => await DtoAsync(await spaces.GetAsync(User.UserId(), id, ct), ct);

    [HttpPost]
    public async Task<ActionResult<SpaceDto>> Create(SpaceRequest req, CancellationToken ct)
    {
        var space = await spaces.CreateAsync(User.UserId(), Input(req), ct);
        return CreatedAtAction(nameof(Get), new { id = space.Id }, ToDto(space, null));
    }

    [HttpPut("{id:guid}")]
    public async Task<SpaceDto> Update(Guid id, SpaceRequest req, CancellationToken ct) =>
        await DtoAsync(await spaces.UpdateAsync(User.UserId(), id, Input(req), ct), ct);

    /// <summary>
    /// Adds a photo, or sets the proof (replacing any earlier one). Photos and proof can be changed until the space
    /// is approved; while it waits for review it stays in the queue and the reviewer sees the new file.
    /// </summary>
    [HttpPost("{id:guid}/photos")]
    [RequestSizeLimit(UploadLimit)]
    public async Task<IActionResult> AddPhoto(Guid id, IFormFile file, [FromForm] bool isProof, CancellationToken ct)
    {
        await spaces.AddFileAsync(User.UserId(), id, AsUpload(file), isProof, ct);
        return NoContent();
    }

    /// <summary>One photo or the proof, for the host to preview or download (the proof is private).</summary>
    [HttpGet("{id:guid}/photos/{photoId:guid}")]
    public async Task<IActionResult> GetPhoto(Guid id, Guid photoId, CancellationToken ct)
    {
        var (stream, path) = await spaces.OpenFileAsync(User.UserId(), id, photoId, ct);
        return File(stream, ContentType(path), Path.GetFileName(path));
    }

    /// <summary>Replaces one photo or the proof with a new file, keeping its place in the list.</summary>
    [HttpPut("{id:guid}/photos/{photoId:guid}")]
    [RequestSizeLimit(UploadLimit)]
    public async Task<IActionResult> ReplacePhoto(Guid id, Guid photoId, IFormFile file, CancellationToken ct)
    {
        await spaces.ReplaceFileAsync(User.UserId(), id, photoId, AsUpload(file), ct);
        return NoContent();
    }

    /// <summary>
    /// Deletes one photo or the proof. If a waiting space drops below the minimum photos or loses its proof,
    /// it cannot be reviewed, so it goes back to Draft and the host submits again.
    /// </summary>
    [HttpDelete("{id:guid}/photos/{photoId:guid}")]
    public async Task<DocumentChange> DeletePhoto(Guid id, Guid photoId, CancellationToken ct) =>
        new(await spaces.DeleteFileAsync(User.UserId(), id, photoId, ct));

    /// <summary>
    /// Deletes the space, whatever its status. It leaves search and the review queue, its photos and proof are
    /// removed from storage, and every waiting or confirmed booking for today or later is cancelled with the farmer
    /// told why. Past bookings keep showing the space's name.
    /// </summary>
    [HttpDelete("{id:guid}")]
    public async Task<SpaceDeleted> Delete(Guid id, CancellationToken ct) => new(await spaces.DeleteAsync(User.UserId(), id, ct));

    /// <summary>The days from today on that the host closed the space, earliest first.</summary>
    [HttpGet("{id:guid}/blocked-dates")]
    public async Task<IEnumerable<BlockedDateDto>> BlockedDates(Guid id, CancellationToken ct) =>
        (await blocked.ListAsync(User.UserId(), id, ct)).Select(d => new BlockedDateDto(d.Date, d.Note));

    /// <summary>
    /// Closes the space for one day (up to 60 days ahead). Refused when a farmer is confirmed that day; waiting requests
    /// for it are declined with the note (or "The host is not available that day") and the farmers are told.
    /// </summary>
    [HttpPost("{id:guid}/blocked-dates")]
    public async Task<BlockedDateDto> Block(Guid id, BlockRequest req, CancellationToken ct)
    {
        var (d, declined) = await blocked.BlockAsync(User.UserId(), id, req.Date, req.Note, ct);
        return new BlockedDateDto(d.Date, d.Note, declined);
    }

    /// <summary>Opens the day again.</summary>
    [HttpDelete("{id:guid}/blocked-dates/{date}")]
    public async Task<IActionResult> Unblock(Guid id, DateOnly date, CancellationToken ct)
    {
        await blocked.UnblockAsync(User.UserId(), id, date, ct);
        return NoContent();
    }

    [HttpPost("{id:guid}/submit")]
    public async Task<IActionResult> Submit(Guid id, CancellationToken ct)
    {
        await spaces.SubmitAsync(User.UserId(), id, ct);
        return NoContent();
    }

    // ---------------------------------------------------------------------------------------------

    internal static Upload AsUpload(IFormFile file) => new(file.Length, file.OpenReadStream);

    private static SpaceInput Input(SpaceRequest r) => new(r.Title, r.Type, r.Address, r.Locality, r.Latitude, r.Longitude,
        r.AreaSqFt, r.MaxStallSize, r.MaxVehicle, r.Amenities, r.IsFree, r.Fee, r.Rules, r.AvailableDays, r.OpenFrom, r.OpenTo);

    private static string ContentType(string path) => Path.GetExtension(path).ToLowerInvariant() switch
    {
        ".png" => "image/png",
        ".webp" => "image/webp",
        _ => "image/jpeg",
    };

    private async Task<SpaceDto> DtoAsync(Space s, CancellationToken ct) =>
        ToDto(s, (await ratings.SpaceStarsAsync([s.Id], ct)).GetValueOrDefault(s.Id));

    private SpaceDto ToDto(Space s, StarSummary? stars) => new(s.Id, s.Title, s.Type, s.Address, s.Locality, s.Location.Y, s.Location.X,
        s.AreaSqFt, s.MaxStallSize, s.MaxVehicle,
        Enum.GetValues<Amenities>().Where(a => a != Amenities.None && s.Amenities.HasFlag(a)).ToArray(),
        s.IsFree, s.Fee, s.Rules,
        s.AvailableDays.Split(',', StringSplitOptions.RemoveEmptyEntries).Select(Enum.Parse<DayOfWeek>).ToArray(),
        s.OpenFrom, s.OpenTo, s.Status, s.RejectionReason,
        s.Photos.Where(p => !p.IsRightToUseProof).OrderBy(p => p.CreatedAt)
            .Select(p => Url.Content($"~/api/v1/files/{p.FilePath}")).ToArray(),
        s.Photos.Any(p => p.IsRightToUseProof),
        s.Photos.Where(p => !p.IsRightToUseProof).OrderBy(p => p.CreatedAt).Select(p => new FileRef(p.Id, p.UpdatedAt)).ToArray(),
        s.Photos.Where(p => p.IsRightToUseProof).Select(p => new FileRef(p.Id, p.UpdatedAt)).FirstOrDefault(),
        stars?.Average, stars?.Count ?? 0);
}
