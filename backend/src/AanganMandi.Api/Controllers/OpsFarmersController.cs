using AanganMandi.Api.Auth;
using AanganMandi.Domain.Farmers;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// Farmer verification for staff. A verifier sees and decides only the farmers assigned to them;
/// an admin sees everyone and can reassign.
/// </summary>
[ApiController]
[Authorize]
[StaffOnly]
[Route("api/v1/ops/farmers")]
public class OpsFarmersController(AppDbContext db) : ControllerBase
{
    public record FarmerRow(Guid Id, string? Name, string Phone, string? Village, string? District, EvidenceType? EvidenceType,
        DateTime? SubmittedAt, string? VerifierName);
    public record DocumentDto(DocumentType Type, string Path);
    public record VerifierOption(Guid Id, string Name, int Waiting);
    public record FarmerDetail(Guid Id, string? Name, string Phone, string? Village, string? District, string[] Crops,
        decimal? FarmSizeAcres, ProduceSource? ProduceSource, EvidenceType? EvidenceType, string? EvidenceDetails,
        string? EvidencePhoto, DocumentDto[] OlderDocuments, VerificationStatus Status, string? RejectionReason,
        DateTime? SubmittedAt, Guid? AssignedVerifierId, string? AssignedVerifierName, DateTime? AssignedAt,
        string? ReviewedByName, DateTime? ReviewedAt, bool CanDecide, bool CanAssign, VerifierOption[] Verifiers);
    public record AssignRequest(Guid VerifierId);
    public record DecisionRequest(bool Approve, string? Reason);

    [HttpGet]
    public async Task<List<FarmerRow>> List([FromQuery] VerificationStatus status = VerificationStatus.Pending, CancellationToken ct = default)
    {
        var isAdmin = StaffAccessFilter.IsAdmin(HttpContext);
        var me = User.UserId();
        // Oldest submission first, so the queue is worked in order (48 h target).
        return await (from f in db.FarmerProfiles
                      join u in db.Users on f.UserId equals u.Id
                      join v in db.Users on f.AssignedVerifierId equals (Guid?)v.Id into vs
                      from v in vs.DefaultIfEmpty()
                      where f.Status == status && (isAdmin || f.AssignedVerifierId == me)
                      orderby f.SubmittedAt
                      select new FarmerRow(f.Id, u.Name, u.Phone, f.Village, f.District, f.EvidenceType, f.SubmittedAt,
                          v == null ? null : v.Name ?? v.Phone)).ToListAsync(ct);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<FarmerDetail>> Get(Guid id, CancellationToken ct)
    {
        var farmer = await db.FarmerProfiles.Include(f => f.Crops).SingleOrDefaultAsync(f => f.Id == id, ct);
        if (farmer is null) return NotFound();
        var isAdmin = StaffAccessFilter.IsAdmin(HttpContext);
        if (!isAdmin && farmer.AssignedVerifierId != User.UserId())
            return Problem(statusCode: 403, title: "This farmer is assigned to another verifier");

        var user = await db.Users.SingleAsync(u => u.Id == farmer.UserId, ct);
        var codes = farmer.Crops.Select(c => c.CropCode).ToList();
        var crops = await db.Crops.Where(c => codes.Contains(c.Code)).Select(c => c.NameEn).ToArrayAsync(ct);
        var docs = await db.VerificationDocuments.Where(d => d.OwnerUserId == farmer.UserId).ToListAsync(ct);
        var verifiers = isAdmin ? await VerifierOptionsAsync(ct) : [];
        var pending = farmer.Status == VerificationStatus.Pending;
        return new FarmerDetail(farmer.Id, user.Name, user.Phone, farmer.Village, farmer.District, crops,
            farmer.FarmSizeAcres, farmer.ProduceSource, farmer.EvidenceType, farmer.EvidenceDetails,
            docs.FirstOrDefault(d => d.Type == DocumentType.Evidence)?.FilePath,
            docs.Where(d => d.Type != DocumentType.Evidence).Select(d => new DocumentDto(d.Type, d.FilePath)).ToArray(),
            farmer.Status, farmer.RejectionReason, farmer.SubmittedAt,
            farmer.AssignedVerifierId, await NameAsync(farmer.AssignedVerifierId, ct), farmer.AssignedAt,
            await NameAsync(farmer.ReviewedBy, ct), farmer.ReviewedAt,
            CanDecide: pending, CanAssign: pending && isAdmin,
            verifiers.Where(v => v.Id != farmer.UserId).ToArray());
    }

    [HttpPost("{id:guid}/assign")]
    [StaffOnly(AdminOnly = true)]
    public async Task<IActionResult> Assign(Guid id, AssignRequest req, CancellationToken ct)
    {
        var farmer = await db.FarmerProfiles.SingleOrDefaultAsync(f => f.Id == id, ct);
        if (farmer is null) return NotFound();
        if (farmer.Status != VerificationStatus.Pending) return Problem(statusCode: 409, title: "Only farmers waiting for review can be assigned");
        var candidates = await VerifierAssignment.CandidatesAsync(db, ct);
        if (req.VerifierId == farmer.UserId || candidates.All(c => c.UserId != req.VerifierId))
            return Problem(statusCode: 400, title: "Choose an active verifier other than the farmer");
        farmer.AssignedVerifierId = req.VerifierId;
        farmer.AssignedAt = DateTime.UtcNow;
        farmer.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpPost("{id:guid}/decision")]
    public async Task<IActionResult> Decide(Guid id, DecisionRequest req, CancellationToken ct)
    {
        var reason = string.IsNullOrWhiteSpace(req.Reason) ? null : req.Reason.Trim();
        if (!req.Approve && reason is null) return Problem(statusCode: 400, title: "Give a reason to reject; the farmer sees it");
        if (reason?.Length > 500) return Problem(statusCode: 400, title: "Keep the reason under 500 characters");

        var farmer = await db.FarmerProfiles.SingleOrDefaultAsync(f => f.Id == id, ct);
        if (farmer is null) return NotFound();
        var me = User.UserId();
        // Re-checked here, not trusted from the screen: the farmer may have been reassigned since it opened.
        if (!StaffAccessFilter.IsAdmin(HttpContext) && farmer.AssignedVerifierId != me)
            return Problem(statusCode: 403, title: "This farmer is assigned to another verifier");
        if (farmer.Status != VerificationStatus.Pending) return Problem(statusCode: 409, title: "This farmer was already reviewed");

        farmer.Status = req.Approve ? VerificationStatus.Verified : VerificationStatus.Rejected;
        farmer.Level = req.Approve ? 2 : 1;
        farmer.RejectionReason = req.Approve ? null : reason;
        farmer.ReviewedAt = DateTime.UtcNow;
        farmer.ReviewedBy = me;
        farmer.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    private async Task<List<VerifierOption>> VerifierOptionsAsync(CancellationToken ct)
    {
        var candidates = await VerifierAssignment.CandidatesAsync(db, ct);
        var ids = candidates.Select(c => c.UserId).ToList();
        var names = await db.Users.Where(u => ids.Contains(u.Id)).ToDictionaryAsync(u => u.Id, u => u.Name ?? u.Phone, ct);
        return candidates.Select(c => new VerifierOption(c.UserId, names[c.UserId], c.OpenReviews)).OrderBy(v => v.Name).ToList();
    }

    private async Task<string?> NameAsync(Guid? userId, CancellationToken ct) => userId is null ? null
        : await db.Users.Where(u => u.Id == userId).Select(u => u.Name ?? u.Phone).SingleOrDefaultAsync(ct);
}
