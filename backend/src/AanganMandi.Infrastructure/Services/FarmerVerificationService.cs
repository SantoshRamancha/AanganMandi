using AanganMandi.Application.Files;
using AanganMandi.Application.Master;
using AanganMandi.Application.Notifications;
using AanganMandi.Application.Storage;
using AanganMandi.Domain.Common;
using AanganMandi.Domain.Farmers;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Infrastructure.Services;

public sealed record FarmerDetailsInput(string Name, string Village, string District, string[] CropCodes,
    decimal? FarmSizeAcres, ProduceSource ProduceSource);

/// <summary>The farmer's own verification as the app shows it.</summary>
public sealed record FarmerVerification(string? Name, FarmerProfile? Profile, VerificationDocument? EvidencePhoto, string[] Missing);

/// <summary>
/// MVP farmer verification (the phone is already OTP-verified at login): farming details, one piece of evidence and
/// its photo, submit. Submitting routes the farmer to a verifier; the decision is in <see cref="ReviewService"/>.
/// </summary>
public class FarmerVerificationService(AppDbContext db, IFileStorage storage, INotifier notifier)
{
    public async Task<FarmerVerification> GetAsync(Guid userId, CancellationToken ct)
    {
        var user = await db.Users.SingleAsync(u => u.Id == userId, ct);
        var farmer = await LoadAsync(userId, ct);
        var photo = await EvidencePhotos(userId).OrderByDescending(d => d.CreatedAt).FirstOrDefaultAsync(ct);
        return new FarmerVerification(user.Name, farmer, photo, Missing(user.Name, farmer, photo is not null));
    }

    public async Task SaveDetailsAsync(Guid userId, FarmerDetailsInput req, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(req.Name) || string.IsNullOrWhiteSpace(req.Village) || string.IsNullOrWhiteSpace(req.District))
            throw ApiException.BadRequest("farmer_details_required");
        if (req.FarmSizeAcres is <= 0 or > 1000) throw ApiException.BadRequest("farm_size_range");
        if (!Enum.IsDefined(req.ProduceSource)) throw ApiException.BadRequest("produce_source_required");
        // Master crops by code; crops the farmer added themselves as "custom:<name>".
        var requested = (req.CropCodes ?? []).Select(c => c.Trim()).ToArray();
        var master = await db.Crops.Where(c => requested.Contains(c.Code)).Select(c => c.Code).ToListAsync(ct);
        var (codes, cropError) = CropCodes.Normalize(requested, master.ToHashSet());
        if (cropError is not null) throw ApiException.BadRequest(cropError);
        if (codes!.Length == 0) throw ApiException.BadRequest("crops_required");

        var farmer = await GetOrCreateAsync(userId, ct);
        if (!farmer.CanEdit) throw Locked(farmer);

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
    }

    public async Task SaveEvidenceAsync(Guid userId, EvidenceType type, string? details, CancellationToken ct)
    {
        if (!Enum.IsDefined(type)) throw ApiException.BadRequest("evidence_type_required");
        details = string.IsNullOrWhiteSpace(details) ? null : details.Trim();
        if (details?.Length > 200) throw ApiException.BadRequest("details_too_long", ("max", 200));
        if (details is null && DetailsRequired(type)) throw ApiException.BadRequest(DetailsPrompt(type));

        var farmer = await GetOrCreateAsync(userId, ct);
        if (!farmer.CanEdit) throw Locked(farmer);
        farmer.EvidenceType = type;
        farmer.EvidenceDetails = details;
        farmer.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
    }

    /// <summary>The farmer's own evidence photo, for preview and download.</summary>
    public async Task<(Stream Content, string ContentType)> OpenEvidencePhotoAsync(Guid userId, CancellationToken ct)
    {
        var doc = await EvidencePhotos(userId).OrderByDescending(d => d.CreatedAt).FirstOrDefaultAsync(ct)
            ?? throw ApiException.NotFound();
        var stream = await storage.OpenReadAsync(doc.FilePath, ct) ?? throw ApiException.NotFound();
        return (stream, doc.ContentType);
    }

    /// <summary>
    /// Uploads or replaces the evidence photo. Allowed until the farmer is verified: a replacement while waiting stays
    /// with the same verifier, who sees the new photo.
    /// </summary>
    public async Task SaveEvidencePhotoAsync(Guid userId, Upload file, CancellationToken ct)
    {
        var kind = await SpaceService.CheckUploadAsync(file, ct);
        var farmer = await GetOrCreateAsync(userId, ct);
        if (!farmer.CanChangeDocuments) throw Locked(farmer);

        string path;
        await using (var stream = file.Open()) path = await storage.SaveAsync(stream, $"kyc/{userId:N}", kind.Extension, ct);
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
        foreach (var d in old) await storage.DeleteAsync(d.FilePath, ct);
    }

    /// <summary>
    /// Deletes the evidence photo. A waiting submission without its evidence cannot be reviewed, so it goes back to
    /// "not submitted" (returns true), keeping its verifier for when the farmer submits again.
    /// </summary>
    public async Task<bool> DeleteEvidencePhotoAsync(Guid userId, CancellationToken ct)
    {
        var farmer = await LoadAsync(userId, ct);
        if (farmer is not null && !farmer.CanChangeDocuments) throw Locked(farmer);
        var docs = await EvidencePhotos(userId).ToListAsync(ct);
        if (docs.Count == 0) throw ApiException.NotFound();

        db.VerificationDocuments.RemoveRange(docs);
        var withdrawn = farmer?.Status == VerificationStatus.Pending;
        if (withdrawn)
        {
            farmer!.Status = VerificationStatus.NotStarted;
            farmer.SubmittedAt = null;
        }
        if (farmer is not null) farmer.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        foreach (var d in docs) await storage.DeleteAsync(d.FilePath, ct);
        return withdrawn;
    }

    /// <summary>
    /// Clears the details, crops, evidence and its photo so the farmer can start over. Allowed until verified; a
    /// waiting submission is withdrawn (returns true). The name stays: it belongs to the account.
    /// </summary>
    public async Task<bool> ResetAsync(Guid userId, CancellationToken ct)
    {
        var farmer = await LoadAsync(userId, ct);
        if (farmer is not null && !farmer.CanReset) throw Locked(farmer);
        var docs = await EvidencePhotos(userId).ToListAsync(ct);

        var withdrawn = farmer?.Status == VerificationStatus.Pending;
        if (farmer is not null)
        {
            db.RemoveRange(farmer.Crops);
            farmer.ResetVerification();
        }
        db.VerificationDocuments.RemoveRange(docs);
        await db.SaveChangesAsync(ct);
        foreach (var d in docs) await storage.DeleteAsync(d.FilePath, ct);
        return withdrawn;
    }

    public async Task SubmitAsync(Guid userId, CancellationToken ct)
    {
        var user = await db.Users.SingleAsync(u => u.Id == userId, ct);
        var farmer = await GetOrCreateAsync(userId, ct);
        if (!farmer.CanEdit) throw Locked(farmer);
        var missing = Missing(user.Name, farmer, await EvidencePhotos(userId).AnyAsync(ct));
        if (missing.Length > 0)
            throw ApiException.Unprocessable("verification_incomplete", ("missing", string.Join(", ", missing)));

        farmer.Status = VerificationStatus.Pending;
        farmer.SubmittedAt = DateTime.UtcNow;
        farmer.RejectionReason = null;
        farmer.Level = Math.Max(farmer.Level, 1);
        farmer.UpdatedAt = DateTime.UtcNow;
        await VerifierAssignment.AssignAsync(db, farmer, ct);
        await db.SaveChangesAsync(ct);
        await notifier.FarmerSubmittedAsync(userId, ct);
    }

    // ---------------------------------------------------------------------------------------------

    /// <summary>What still blocks submitting: "details", "evidence", "evidencePhoto".</summary>
    public static string[] Missing(string? name, FarmerProfile? f, bool hasPhoto)
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
        EvidenceType.AgriStackFarmerId => "farmer_id_required",
        EvidenceType.FpoMembership => "fpo_required",
        _ => "referee_required",
    };

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

    private static ApiException Locked(FarmerProfile f) =>
        ApiException.Conflict(f.Status == VerificationStatus.Pending ? "verification_under_review" : "farmer_already_verified");
}
