using AanganMandi.Api.Auth;
using AanganMandi.Application.Notifications;
using AanganMandi.Domain.Farmers;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Persistence;
using AanganMandi.Infrastructure.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// Farmer verification for staff. A verifier sees and decides only the farmers assigned to them;
/// an admin sees everyone and can reassign. Decisions are in <see cref="ReviewService"/>.
/// </summary>
[ApiController]
[Authorize]
[StaffOnly]
[Route("api/v1/ops/farmers")]
public class OpsFarmersController(AppDbContext db, ReviewService reviews, RatingService ratings) : ControllerBase
{
    public record FarmerRow(Guid Id, string? Name, string Phone, string? Village, string? District, EvidenceType? EvidenceType,
        DateTime? SubmittedAt, string? VerifierName);
    public record DocumentDto(DocumentType Type, string Path);
    public record VerifierOption(Guid Id, string Name, int Waiting);
    /// <summary>The farmer's selling record: hosts' stars, stalls they came to, and their recent no-shows.</summary>
    public record SellingRecord(double? Rating, int RatingCount, int CompletedStalls, int RecentNoShows, NoShowRow[] NoShows,
        bool CanClearNoShows);
    /// <summary>One booking a host marked as a no-show; an admin can clear a wrong one.</summary>
    public record NoShowRow(Guid BookingId, DateOnly Date, string SpaceTitle, DateTime MarkedAt);
    public record FarmerDetail(Guid Id, string? Name, string Phone, string? Village, string? District, string[] Crops,
        decimal? FarmSizeAcres, ProduceSource? ProduceSource, EvidenceType? EvidenceType, string? EvidenceDetails,
        string? EvidencePhoto, DocumentDto[] OlderDocuments, VerificationStatus Status, string? RejectionReason,
        DateTime? SubmittedAt, Guid? AssignedVerifierId, string? AssignedVerifierName, DateTime? AssignedAt,
        string? ReviewedByName, DateTime? ReviewedAt, bool CanDecide, bool CanAssign, VerifierOption[] Verifiers,
        SellingRecord Record);
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
        var isAdmin = StaffAccessFilter.IsAdmin(HttpContext);
        var farmer = await reviews.GetFarmerAsync(Me, id, ct);

        var user = await db.Users.SingleAsync(u => u.Id == farmer.UserId, ct);
        // Codes, not names: the app shows them in the reviewer's language (custom crops as the farmer typed them).
        var crops = farmer.Crops.Select(c => c.CropCode).ToArray();
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
            verifiers.Where(v => v.Id != farmer.UserId).ToArray(),
            await RecordAsync(farmer.UserId, isAdmin, ct));
    }

    [HttpPost("{id:guid}/assign")]
    [StaffOnly(AdminOnly = true)]
    public async Task<IActionResult> Assign(Guid id, AssignRequest req, CancellationToken ct)
    {
        await reviews.AssignFarmerAsync(id, req.VerifierId, ct);
        return NoContent();
    }

    [HttpPost("{id:guid}/decision")]
    public async Task<IActionResult> Decide(Guid id, DecisionRequest req, CancellationToken ct)
    {
        // The assignment is re-checked there, not trusted from the screen: the farmer may have been reassigned since.
        await reviews.DecideFarmerAsync(Me, id, req.Approve, req.Reason, ct);
        return NoContent();
    }

    /// <summary>
    /// Admin: removes a wrong no-show mark from one of this farmer's bookings (for example the farmer came but could
    /// not check in), so it no longer counts against them.
    /// </summary>
    [HttpPost("{id:guid}/no-shows/{bookingId:guid}/clear")]
    [StaffOnly(AdminOnly = true)]
    public async Task<IActionResult> ClearNoShow(Guid id, Guid bookingId, CancellationToken ct)
    {
        var farmer = await reviews.GetFarmerAsync(Me, id, ct);
        if (!await db.Bookings.AnyAsync(b => b.Id == bookingId && b.FarmerUserId == farmer.UserId, ct))
            return this.Fail(404, "not_found");
        await ratings.ClearNoShowAsync(bookingId, ct);
        return NoContent();
    }

    private Staff Me => new(User.UserId(), StaffAccessFilter.IsAdmin(HttpContext));

    private async Task<SellingRecord> RecordAsync(Guid farmerUserId, bool isAdmin, CancellationToken ct)
    {
        var record = await ratings.FarmerRecordAsync(farmerUserId, ct);
        var noShows = await ratings.RecentNoShowsAsync(farmerUserId, ct);
        var spaceIds = noShows.Select(b => b.SpaceId).Distinct().ToList();
        var titles = await db.Spaces.IgnoreQueryFilters().Where(s => spaceIds.Contains(s.Id)).ToDictionaryAsync(s => s.Id, s => s.Title, ct);
        return new SellingRecord(record.Average, record.Ratings, record.Completed, record.RecentNoShows,
            noShows.Select(b => new NoShowRow(b.Id, b.Date, titles.GetValueOrDefault(b.SpaceId, ""), b.NoShowAt!.Value)).ToArray(), isAdmin);
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
