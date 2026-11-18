using AanganMandi.Api.Auth;
using AanganMandi.Domain.Farmers;
using AanganMandi.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// MVP farmer verification (the phone is already OTP-verified at login): basic farming details,
/// one piece of farming evidence, submit. Submitting routes the farmer to a verifier, who approves
/// (Level 2) or rejects with a reason from the operations screens in the app. The rules are in
/// <see cref="FarmerVerificationService"/>.
/// </summary>
[ApiController]
[Authorize(Roles = "Farmer")]
[Route("api/v1/farmers/me")]
public class FarmersController(FarmerVerificationService verification) : ControllerBase
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

    [HttpGet]
    public async Task<FarmerDto> Get(CancellationToken ct)
    {
        var (name, farmer, photo, missing) = await verification.GetAsync(User.UserId(), ct);
        return new FarmerDto(name, farmer?.Village, farmer?.District,
            farmer?.Crops.Select(c => c.CropCode).ToArray() ?? [], farmer?.FarmSizeAcres, farmer?.ProduceSource,
            farmer?.EvidenceType, farmer?.EvidenceDetails, photo is not null, photo?.CreatedAt,
            farmer?.Status ?? VerificationStatus.NotStarted, farmer?.Level ?? 0, farmer?.RejectionReason,
            farmer?.SubmittedAt, missing);
    }

    [HttpPut("details")]
    public async Task<IActionResult> SaveDetails(DetailsRequest req, CancellationToken ct)
    {
        await verification.SaveDetailsAsync(User.UserId(), new FarmerDetailsInput(req.Name, req.Village, req.District,
            req.CropCodes, req.FarmSizeAcres, req.ProduceSource), ct);
        return NoContent();
    }

    [HttpPut("evidence")]
    public async Task<IActionResult> SaveEvidence(EvidenceRequest req, CancellationToken ct)
    {
        await verification.SaveEvidenceAsync(User.UserId(), req.Type, req.Details, ct);
        return NoContent();
    }

    /// <summary>The farmer's own evidence photo, for preview and download.</summary>
    [HttpGet("evidence/photo")]
    public async Task<IActionResult> GetEvidencePhoto(CancellationToken ct)
    {
        var (stream, contentType) = await verification.OpenEvidencePhotoAsync(User.UserId(), ct);
        return File(stream, contentType, $"evidence{Extension(contentType)}");
    }

    /// <summary>
    /// Uploads or replaces the evidence photo. Allowed until the farmer is verified: a replacement while waiting
    /// stays with the same verifier, who sees the new photo.
    /// </summary>
    [HttpPost("evidence/photo")]
    [RequestSizeLimit(SpaceService.MaxUploadBytes + 64 * 1024)]
    public async Task<IActionResult> UploadEvidencePhoto(IFormFile file, CancellationToken ct)
    {
        await verification.SaveEvidencePhotoAsync(User.UserId(), HostSpacesController.AsUpload(file), ct);
        return NoContent();
    }

    /// <summary>
    /// Deletes the evidence photo. A waiting submission without its evidence cannot be reviewed, so it goes back
    /// to "not submitted" (keeping its verifier for when the farmer submits again).
    /// </summary>
    [HttpDelete("evidence/photo")]
    public async Task<DocumentChange> DeleteEvidencePhoto(CancellationToken ct) =>
        new(await verification.DeleteEvidencePhotoAsync(User.UserId(), ct));

    /// <summary>
    /// Clears the farming details, crops, evidence and evidence photo so the farmer can start over. Allowed until
    /// verified; a waiting submission is withdrawn. The name stays: it belongs to the account, not the verification.
    /// </summary>
    [HttpDelete("verification")]
    public async Task<DocumentChange> ResetVerification(CancellationToken ct) => new(await verification.ResetAsync(User.UserId(), ct));

    [HttpPost("submit")]
    public async Task<IActionResult> Submit(CancellationToken ct)
    {
        await verification.SubmitAsync(User.UserId(), ct);
        return NoContent();
    }

    private static string Extension(string contentType) => contentType switch
    {
        "image/png" => ".png",
        "image/webp" => ".webp",
        _ => ".jpg",
    };
}
