using AanganMandi.Api.Auth;
using AanganMandi.Application.Storage;
using AanganMandi.Domain.Spaces;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;

namespace AanganMandi.Api.Controllers;

/// <summary>Host flow: create a draft space, add 3–8 photos and a right-to-use proof, submit for admin review.</summary>
[ApiController]
[Authorize(Roles = "Host")]
[Route("api/v1/hosts/me/spaces")]
public class HostSpacesController(AppDbContext db, IFileStorage storage) : ControllerBase
{
    public record SpaceRequest(string Title, SpaceType Type, string Address, string Locality,
        double Latitude, double Longitude, int AreaSqFt, string MaxStallSize, VehicleType MaxVehicle,
        Amenities[] Amenities, bool IsFree, decimal Fee, string? Rules, DayOfWeek[] AvailableDays,
        TimeOnly OpenFrom, TimeOnly OpenTo);
    public record SpaceDto(Guid Id, string Title, SpaceType Type, string Address, string Locality,
        double Latitude, double Longitude, int AreaSqFt, string MaxStallSize, VehicleType MaxVehicle,
        Amenities[] Amenities, bool IsFree, decimal Fee, string? Rules, DayOfWeek[] AvailableDays,
        TimeOnly OpenFrom, TimeOnly OpenTo, SpaceStatus Status, string? RejectionReason,
        string[] PhotoUrls, bool HasProof);

    private static readonly GeometryFactory Geo = NetTopologySuite.NtsGeometryServices.Instance.CreateGeometryFactory(4326);
    private static readonly string[] AllowedImageTypes = ["image/jpeg", "image/png", "image/webp"];
    private const long MaxUploadBytes = 8 * 1024 * 1024;
    private const int MinPhotos = 3, MaxPhotos = 8;

    [HttpGet]
    public async Task<IEnumerable<SpaceDto>> List(CancellationToken ct)
    {
        var spaces = await db.Spaces.Include(s => s.Photos).Where(s => s.HostUserId == User.UserId())
            .OrderByDescending(s => s.CreatedAt).ToListAsync(ct);
        return spaces.Select(ToDto);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<SpaceDto>> Get(Guid id, CancellationToken ct)
    {
        var space = await FindAsync(id, ct);
        return space is null ? NotFound() : ToDto(space);
    }

    [HttpPost]
    public async Task<ActionResult<SpaceDto>> Create(SpaceRequest req, CancellationToken ct)
    {
        if (Validate(req) is { } error) return error;
        var space = new Space
        {
            HostUserId = User.UserId(),
            Title = req.Title.Trim(),
            Address = req.Address.Trim(),
            Locality = req.Locality.Trim(),
            Location = Geo.CreatePoint(new Coordinate(req.Longitude, req.Latitude)),
            AvailableDays = "",
        };
        Apply(space, req);
        db.Spaces.Add(space);
        await db.SaveChangesAsync(ct);
        return CreatedAtAction(nameof(Get), new { id = space.Id }, ToDto(space));
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<SpaceDto>> Update(Guid id, SpaceRequest req, CancellationToken ct)
    {
        var space = await FindAsync(id, ct);
        if (space is null) return NotFound();
        if (space.Status is SpaceStatus.PendingReview) return Problem(statusCode: 409, title: "Space is under review");
        if (Validate(req) is { } error) return error;
        Apply(space, req);
        // Any change to a live or rejected space sends it back through review.
        if (space.Status is SpaceStatus.Live or SpaceStatus.Rejected) space.Status = SpaceStatus.Draft;
        await db.SaveChangesAsync(ct);
        return ToDto(space);
    }

    [HttpPost("{id:guid}/photos")]
    [RequestSizeLimit(MaxUploadBytes + 64 * 1024)]
    public async Task<IActionResult> AddPhoto(Guid id, IFormFile file, [FromForm] bool isProof, CancellationToken ct)
    {
        var space = await FindAsync(id, ct);
        if (space is null) return NotFound();
        if (space.Status is SpaceStatus.PendingReview) return Problem(statusCode: 409, title: "Space is under review");
        if (file.Length is 0 or > MaxUploadBytes) return Problem(statusCode: 400, title: "Photo must be under 8 MB");
        if (!AllowedImageTypes.Contains(file.ContentType))
            return Problem(statusCode: 400, title: "Only JPEG, PNG or WebP photos are accepted");
        if (!isProof && space.Photos.Count(p => !p.IsRightToUseProof) >= MaxPhotos)
            return Problem(statusCode: 400, title: $"A space can have at most {MaxPhotos} photos");

        // Proof documents are private (kyc/); space photos are public (spaces/).
        var folder = isProof ? $"kyc/spaces/{space.Id:N}" : $"spaces/{space.Id:N}";
        await using var stream = file.OpenReadStream();
        var path = await storage.SaveAsync(stream, folder, file.ContentType == "image/png" ? ".png" : ".jpg", ct);
        if (isProof) db.SpacePhotos.RemoveRange(space.Photos.Where(p => p.IsRightToUseProof));
        db.SpacePhotos.Add(new SpacePhoto { SpaceId = space.Id, FilePath = path, IsRightToUseProof = isProof });
        if (space.Status is SpaceStatus.Live or SpaceStatus.Rejected) space.Status = SpaceStatus.Draft;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpPost("{id:guid}/submit")]
    public async Task<IActionResult> Submit(Guid id, CancellationToken ct)
    {
        var space = await FindAsync(id, ct);
        if (space is null) return NotFound();
        if (space.Status is not (SpaceStatus.Draft or SpaceStatus.Rejected))
            return Problem(statusCode: 409, title: "Space is already submitted");
        var photos = space.Photos.Count(p => !p.IsRightToUseProof);
        if (photos < MinPhotos)
            return Problem(statusCode: 422, title: $"Add at least {MinPhotos} photos of the space");
        if (!space.Photos.Any(p => p.IsRightToUseProof))
            return Problem(statusCode: 422, title: "Add a photo of your ownership, rent document or society letter");
        space.Status = SpaceStatus.PendingReview;
        space.RejectionReason = null;
        space.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    private Task<Space?> FindAsync(Guid id, CancellationToken ct) =>
        db.Spaces.Include(s => s.Photos).SingleOrDefaultAsync(s => s.Id == id && s.HostUserId == User.UserId(), ct);

    private ObjectResult? Validate(SpaceRequest r)
    {
        string? error =
            string.IsNullOrWhiteSpace(r.Title) ? "Give the space a name" :
            string.IsNullOrWhiteSpace(r.Address) || string.IsNullOrWhiteSpace(r.Locality) ? "Address and locality are required" :
            r.Latitude is < -90 or > 90 || r.Longitude is < -180 or > 180 || (r.Latitude == 0 && r.Longitude == 0) ? "Capture the space location" :
            r.AreaSqFt is < 50 or > 100_000 ? "Usable area must be between 50 and 100,000 sq ft" :
            !r.IsFree && r.Fee is <= 0 or > 100_000 ? "Enter a fee per slot, or mark the space as free" :
            r.AvailableDays.Length == 0 ? "Choose at least one day" :
            (r.OpenTo - r.OpenFrom).TotalHours is < 2 or > 6 ? "Each slot must be 2 to 6 hours long" :
            null;
        return error is null ? null : Problem(statusCode: 400, title: error);
    }

    private static void Apply(Space s, SpaceRequest r)
    {
        s.Title = r.Title.Trim();
        s.Type = r.Type;
        s.Address = r.Address.Trim();
        s.Locality = r.Locality.Trim();
        s.Location = Geo.CreatePoint(new Coordinate(r.Longitude, r.Latitude));
        s.AreaSqFt = r.AreaSqFt;
        s.MaxStallSize = string.IsNullOrWhiteSpace(r.MaxStallSize) ? "10x10 ft" : r.MaxStallSize.Trim();
        s.MaxVehicle = r.MaxVehicle;
        s.Amenities = r.Amenities.Aggregate(Amenities.None, (all, a) => all | a);
        s.IsFree = r.IsFree;
        s.Fee = r.IsFree ? 0 : r.Fee;
        s.Rules = r.Rules?.Trim();
        s.AvailableDays = string.Join(',', r.AvailableDays.Distinct().Order());
        s.OpenFrom = r.OpenFrom;
        s.OpenTo = r.OpenTo;
        s.UpdatedAt = DateTime.UtcNow;
    }

    private SpaceDto ToDto(Space s) => new(s.Id, s.Title, s.Type, s.Address, s.Locality, s.Location.Y, s.Location.X,
        s.AreaSqFt, s.MaxStallSize, s.MaxVehicle,
        Enum.GetValues<Amenities>().Where(a => a != Amenities.None && s.Amenities.HasFlag(a)).ToArray(),
        s.IsFree, s.Fee, s.Rules,
        s.AvailableDays.Split(',', StringSplitOptions.RemoveEmptyEntries).Select(Enum.Parse<DayOfWeek>).ToArray(),
        s.OpenFrom, s.OpenTo, s.Status, s.RejectionReason,
        s.Photos.Where(p => !p.IsRightToUseProof).OrderBy(p => p.CreatedAt)
            .Select(p => Url.Content($"~/api/v1/files/{p.FilePath}")).ToArray(),
        s.Photos.Any(p => p.IsRightToUseProof));
}
