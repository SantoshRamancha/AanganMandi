using AanganMandi.Api.Auth;
using AanganMandi.Application.Files;
using AanganMandi.Application.Notifications;
using AanganMandi.Application.Master;
using AanganMandi.Application.Storage;
using AanganMandi.Domain.Farmers;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// MVP farmer verification (the phone is already OTP-verified at login): basic farming details,
/// one piece of farming evidence, submit. Submitting routes the farmer to a verifier, who approves
/// (Level 2) or rejects with a reason from the operations screens in the app.
/// </summary>
[ApiController]
[Authorize(Roles = "Farmer")]
[Route("api/v1/farmers/me")]
public class FarmersController(AppDbContext db, IFileStorage storage, INotifier notifier) : ControllerBase
{
    public record DetailsRequest(string Name, string Village, string District, string[] CropCodes,
        decimal? FarmSizeAcres, ProduceSource ProduceSource);
    public record EvidenceRequest(EvidenceType Type, string? Details);
    public record FarmerDto(string? Name, string? Village, string? District, string[] CropCodes, decimal? FarmSizeAcres,
        ProduceSource? ProduceSource, EvidenceType? EvidenceType, string? EvidenceDetails, bool HasEvidencePhoto,
        DateTime? EvidencePhotoAt, VerificationStatus Status, int Level, string? RejectionReason, DateTime? SubmittedAt,
        string[] Missing);
    /// <summary>Withdrawn: the change took a waiting submission back to "not submitted"; the farmer must submit again.</summary>
    public record DocumentChange(bool Withdrawn);

    private const long MaxUploadBytes = 8 * 1024 * 1024;

    [HttpGet]
    public async Task<FarmerDto> Get(CancellationToken ct)
    {
        var userId = User.UserId();
        var user = await db.Users.SingleAsync(u => u.Id == userId, ct);
        var farmer = await LoadAsync(userId, ct);
        var photo = await EvidencePhotos(userId).OrderByDescending(d => d.CreatedAt).FirstOrDefaultAsync(ct);
        return new FarmerDto(user.Name, farmer?.Village, farmer?.District,
            farmer?.Crops.Select(c => c.CropCode).ToArray() ?? [], farmer?.FarmSizeAcres, farmer?.ProduceSource,
            farmer?.EvidenceType, farmer?.EvidenceDetails, photo is not null, photo?.CreatedAt,
            farmer?.Status ?? VerificationStatus.NotStarted, farmer?.Level ?? 0, farmer?.RejectionReason,
            farmer?.SubmittedAt, Missing(user.Name, farmer, photo is not null));
    }

    [HttpPut("details")]
    public async Task<IActionResult> SaveDetails(DetailsRequest req, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(req.Name) || string.IsNullOrWhiteSpace(req.Village) || string.IsNullOrWhiteSpace(req.District))
            return Problem(statusCode: 400, title: "Name, village and district are required");
        if (req.FarmSizeAcres is <= 0 or > 1000)
            return Problem(statusCode: 400, title: "Farm size must be between 0 and 1000 acres");
        if (!Enum.IsDefined(req.ProduceSource))
            return Problem(statusCode: 400, title: "Say whether you grow your own crops");
        // Master crops by code; crops the farmer added themselves as "custom:<name>".
        var requested = req.CropCodes.Select(c => c.Trim()).ToArray();
        var master = await db.Crops.Where(c => requested.Contains(c.Code)).Select(c => c.Code).ToListAsync(ct);
        var (codes, cropError) = CropCodes.Normalize(requested, master.ToHashSet());
        if (cropError is not null) return Problem(statusCode: 400, title: cropError);
        if (codes!.Length == 0) return Problem(statusCode: 400, title: "Choose at least one crop you grow or sell");

        var userId = User.UserId();
        var farmer = await GetOrCreateAsync(userId, ct);
        if (!farmer.CanEdit) return Locked(farmer);

        var user = await db.Users.SingleAsync(u => u.Id == userId, ct);
        user.Name = req.Name.Trim();
        farmer.Village = req.Village.Trim();
        farmer.District = req.District.Trim();
        farmer.FarmSizeAcres = req.FarmSizeAcres;
        farmer.ProduceSource = req.ProduceSource;
        db.RemoveRange(farmer.Crops);
        farmer.Crops = codes.Select(c => new FarmerCrop { CropCode = c }).ToList();
        farmer.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpPut("evidence")]
    public async Task<IActionResult> SaveEvidence(EvidenceRequest req, CancellationToken ct)
    {
        if (!Enum.IsDefined(req.Type)) return Problem(statusCode: 400, title: "Choose the type of evidence");
        var details = string.IsNullOrWhiteSpace(req.Details) ? null : req.Details.Trim();
        if (details?.Length > 200) return Problem(statusCode: 400, title: "Keep the details under 200 characters");
        if (details is null && DetailsRequired(req.Type)) return Problem(statusCode: 400, title: DetailsPrompt(req.Type));

        var farmer = await GetOrCreateAsync(User.UserId(), ct);
        if (!farmer.CanEdit) return Locked(farmer);
        farmer.EvidenceType = req.Type;
        farmer.EvidenceDetails = details;
        farmer.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    /// <summary>The farmer's own evidence photo, for preview and download.</summary>
    [HttpGet("evidence/photo")]
    public async Task<IActionResult> GetEvidencePhoto(CancellationToken ct)
    {
        var doc = await EvidencePhotos(User.UserId()).OrderByDescending(d => d.CreatedAt).FirstOrDefaultAsync(ct);
        var stream = doc is null ? null : storage.OpenRead(doc.FilePath);
        return stream is null ? NotFound() : File(stream, doc!.ContentType, $"evidence{Extension(doc.ContentType)}");
    }

    /// <summary>
    /// Uploads or replaces the evidence photo. Allowed until the farmer is verified: a replacement while waiting
    /// stays with the same verifier, who sees the new photo.
    /// </summary>
    [HttpPost("evidence/photo")]
    [RequestSizeLimit(MaxUploadBytes + 64 * 1024)]
    public async Task<IActionResult> UploadEvidencePhoto(IFormFile file, CancellationToken ct)
    {
        if (file.Length is 0 or > MaxUploadBytes)
            return Problem(statusCode: 400, title: "Photo must be under 8 MB");
        // The real format comes from the bytes: the label the browser sends can be wrong (see ImageFormat).
        ImageFormat.Kind? kind;
        await using (var head = file.OpenReadStream()) kind = await ImageFormat.DetectAsync(head, ct);
        if (kind is null)
            return Problem(statusCode: 400, title: "Only JPEG, PNG or WebP photos are accepted");

        var userId = User.UserId();
        var farmer = await GetOrCreateAsync(userId, ct);
        if (!farmer.CanChangeDocuments) return Locked(farmer);

        await using var stream = file.OpenReadStream();
        var path = await storage.SaveAsync(stream, $"kyc/{userId:N}", kind.Extension, ct);
        var old = await EvidencePhotos(userId).ToListAsync(ct);
        db.VerificationDocuments.RemoveRange(old);
        db.VerificationDocuments.Add(new VerificationDocument
        {
            OwnerUserId = userId,
            Type = DocumentType.Evidence,
            FilePath = path,
            ContentType = kind.ContentType,
        });
        farmer.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        foreach (var d in old) storage.Delete(d.FilePath);
        return NoContent();
    }

    /// <summary>
    /// Deletes the evidence photo. A waiting submission without its evidence cannot be reviewed, so it goes back
    /// to "not submitted" (keeping its verifier for when the farmer submits again).
    /// </summary>
    [HttpDelete("evidence/photo")]
    public async Task<ActionResult<DocumentChange>> DeleteEvidencePhoto(CancellationToken ct)
    {
        var userId = User.UserId();
        var farmer = await LoadAsync(userId, ct);
        if (farmer is not null && !farmer.CanChangeDocuments) return Locked(farmer);
        var docs = await EvidencePhotos(userId).ToListAsync(ct);
        if (docs.Count == 0) return NotFound();

        db.VerificationDocuments.RemoveRange(docs);
        var withdrawn = farmer?.Status == VerificationStatus.Pending;
        if (withdrawn)
        {
            farmer!.Status = VerificationStatus.NotStarted;
            farmer.SubmittedAt = null;
        }
        if (farmer is not null) farmer.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        foreach (var d in docs) storage.Delete(d.FilePath);
        return new DocumentChange(withdrawn);
    }

    [HttpPost("submit")]
    public async Task<IActionResult> Submit(CancellationToken ct)
    {
        var userId = User.UserId();
        var user = await db.Users.SingleAsync(u => u.Id == userId, ct);
        var farmer = await GetOrCreateAsync(userId, ct);
        if (!farmer.CanEdit) return Locked(farmer);
        var missing = Missing(user.Name, farmer, await HasEvidencePhotoAsync(userId, ct));
        if (missing.Length > 0)
            return Problem(statusCode: 422, title: "Verification is incomplete", detail: string.Join(", ", missing));

        farmer.Status = VerificationStatus.Pending;
        farmer.SubmittedAt = DateTime.UtcNow;
        farmer.RejectionReason = null;
        farmer.Level = Math.Max(farmer.Level, 1);
        farmer.UpdatedAt = DateTime.UtcNow;
        await VerifierAssignment.AssignAsync(db, farmer, ct);
        await db.SaveChangesAsync(ct);
        await notifier.FarmerSubmittedAsync(userId, ct);
        return NoContent();
    }

    private static string[] Missing(string? name, FarmerProfile? f, bool hasPhoto)
    {
        var missing = new List<string>();
        if (string.IsNullOrWhiteSpace(name) || f?.Village is null || f.District is null || f.ProduceSource is null || f.Crops.Count == 0)
            missing.Add("details");
        if (f?.EvidenceType is not { } type || (f.EvidenceDetails is null && DetailsRequired(type))) missing.Add("evidence");
        if (!hasPhoto) missing.Add("evidencePhoto");
        return missing.ToArray();
    }

    /// <summary>A land record's photo speaks for itself; the others need a number or a name the verifier can check.</summary>
    private static bool DetailsRequired(EvidenceType t) => t != EvidenceType.LandRecord;

    private static string DetailsPrompt(EvidenceType t) => t switch
    {
        EvidenceType.AgriStackFarmerId => "Enter your Farmer ID number",
        EvidenceType.FpoMembership => "Enter the FPO name, or who referred you",
        _ => "Enter the officer's or organisation's name and phone number",
    };

    private Task<bool> HasEvidencePhotoAsync(Guid userId, CancellationToken ct) => EvidencePhotos(userId).AnyAsync(ct);

    private IQueryable<VerificationDocument> EvidencePhotos(Guid userId) =>
        db.VerificationDocuments.Where(d => d.OwnerUserId == userId && d.Type == DocumentType.Evidence);

    private Task<FarmerProfile?> LoadAsync(Guid userId, CancellationToken ct) =>
        db.FarmerProfiles.Include(f => f.Crops).SingleOrDefaultAsync(f => f.UserId == userId, ct);

    private async Task<FarmerProfile> GetOrCreateAsync(Guid userId, CancellationToken ct)
    {
        var farmer = await LoadAsync(userId, ct);
        if (farmer is not null) return farmer;
        farmer = new FarmerProfile { UserId = userId };
        db.FarmerProfiles.Add(farmer);
        return farmer;
    }

    private ObjectResult Locked(FarmerProfile f) => Problem(statusCode: 409,
        title: f.Status == VerificationStatus.Pending ? "Verification is under review" : "Farmer is already verified");

    private static string Extension(string contentType) => contentType switch
    {
        "image/png" => ".png",
        "image/webp" => ".webp",
        _ => ".jpg",
    };
}
