using AanganMandi.Api.Auth;
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
public class FarmersController(AppDbContext db, IFileStorage storage) : ControllerBase
{
    public record DetailsRequest(string Name, string Village, string District, string[] CropCodes,
        decimal? FarmSizeAcres, ProduceSource ProduceSource);
    public record EvidenceRequest(EvidenceType Type, string? Details);
    public record FarmerDto(string? Name, string? Village, string? District, string[] CropCodes, decimal? FarmSizeAcres,
        ProduceSource? ProduceSource, EvidenceType? EvidenceType, string? EvidenceDetails, bool HasEvidencePhoto,
        VerificationStatus Status, int Level, string? RejectionReason, DateTime? SubmittedAt, string[] Missing);

    private static readonly string[] AllowedImageTypes = ["image/jpeg", "image/png", "image/webp"];
    private const long MaxUploadBytes = 8 * 1024 * 1024;

    [HttpGet]
    public async Task<FarmerDto> Get(CancellationToken ct)
    {
        var userId = User.UserId();
        var user = await db.Users.SingleAsync(u => u.Id == userId, ct);
        var farmer = await LoadAsync(userId, ct);
        var hasPhoto = await HasEvidencePhotoAsync(userId, ct);
        return new FarmerDto(user.Name, farmer?.Village, farmer?.District,
            farmer?.Crops.Select(c => c.CropCode).ToArray() ?? [], farmer?.FarmSizeAcres, farmer?.ProduceSource,
            farmer?.EvidenceType, farmer?.EvidenceDetails, hasPhoto,
            farmer?.Status ?? VerificationStatus.NotStarted, farmer?.Level ?? 0, farmer?.RejectionReason,
            farmer?.SubmittedAt, Missing(user.Name, farmer, hasPhoto));
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
        var codes = req.CropCodes.Distinct().ToArray();
        if (codes.Length == 0) return Problem(statusCode: 400, title: "Choose at least one crop you grow or sell");
        var known = await db.Crops.Where(c => codes.Contains(c.Code)).CountAsync(ct);
        if (known != codes.Length) return Problem(statusCode: 400, title: "Unknown crop code");

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

    /// <summary>Uploads (or replaces) the photo of the farming evidence.</summary>
    [HttpPost("evidence/photo")]
    [RequestSizeLimit(MaxUploadBytes + 64 * 1024)]
    public async Task<IActionResult> UploadEvidencePhoto(IFormFile file, CancellationToken ct)
    {
        if (file.Length is 0 or > MaxUploadBytes)
            return Problem(statusCode: 400, title: "Photo must be under 8 MB");
        if (!AllowedImageTypes.Contains(file.ContentType))
            return Problem(statusCode: 400, title: "Only JPEG, PNG or WebP photos are accepted");

        var userId = User.UserId();
        var farmer = await GetOrCreateAsync(userId, ct);
        if (!farmer.CanEdit) return Locked(farmer);

        await using var stream = file.OpenReadStream();
        var path = await storage.SaveAsync(stream, $"kyc/{userId:N}", Extension(file.ContentType), ct);
        var old = await db.VerificationDocuments
            .Where(d => d.OwnerUserId == userId && d.Type == DocumentType.Evidence).ToListAsync(ct);
        db.VerificationDocuments.RemoveRange(old);
        db.VerificationDocuments.Add(new VerificationDocument
        {
            OwnerUserId = userId,
            Type = DocumentType.Evidence,
            FilePath = path,
            ContentType = file.ContentType,
        });
        await db.SaveChangesAsync(ct);
        return NoContent();
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

    private Task<bool> HasEvidencePhotoAsync(Guid userId, CancellationToken ct) =>
        db.VerificationDocuments.AnyAsync(d => d.OwnerUserId == userId && d.Type == DocumentType.Evidence, ct);

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
