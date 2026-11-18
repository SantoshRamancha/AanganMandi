using AanganMandi.Application.Notifications;
using AanganMandi.Domain.Common;
using AanganMandi.Domain.Farmers;
using AanganMandi.Domain.Spaces;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Infrastructure.Services;

/// <summary>Who is acting in Operations: a verifier sees and decides only their own farmers; an admin, everyone.</summary>
public sealed record Staff(Guid UserId, bool IsAdmin);

/// <summary>
/// Staff decisions: approve or reject farmers (by their assigned verifier or an admin), reassign a farmer (admin),
/// and approve or reject spaces (any staff).
/// </summary>
public class ReviewService(AppDbContext db, INotifier notifier)
{
    /// <summary>The farmer, if <paramref name="staff"/> may see them (re-checked on every call: assignments change).</summary>
    public async Task<FarmerProfile> GetFarmerAsync(Staff staff, Guid farmerProfileId, CancellationToken ct)
    {
        var farmer = await db.FarmerProfiles.Include(f => f.Crops).SingleOrDefaultAsync(f => f.Id == farmerProfileId, ct)
            ?? throw ApiException.NotFound();
        if (!staff.IsAdmin && farmer.AssignedVerifierId != staff.UserId) throw ApiException.Forbidden("farmer_other_verifier");
        return farmer;
    }

    /// <summary>Admin: hands a waiting farmer to another verifier (never to themselves as a farmer).</summary>
    public async Task AssignFarmerAsync(Guid farmerProfileId, Guid verifierId, CancellationToken ct)
    {
        var farmer = await db.FarmerProfiles.SingleOrDefaultAsync(f => f.Id == farmerProfileId, ct) ?? throw ApiException.NotFound();
        if (farmer.Status != VerificationStatus.Pending) throw ApiException.Conflict("farmer_not_waiting");
        var candidates = await VerifierAssignment.CandidatesAsync(db, ct);
        if (verifierId == farmer.UserId || candidates.All(c => c.UserId != verifierId))
            throw ApiException.BadRequest("verifier_invalid");
        farmer.AssignedVerifierId = verifierId;
        farmer.AssignedAt = farmer.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        await notifier.FarmerAssignedAsync(farmer.UserId, ct);
    }

    /// <summary>Approve (Level 2, can sell) or reject with a reason the farmer sees.</summary>
    public async Task DecideFarmerAsync(Staff staff, Guid farmerProfileId, bool approve, string? reason, CancellationToken ct)
    {
        reason = DecisionReason(approve, reason, "reject_reason_farmer");
        var farmer = await db.FarmerProfiles.SingleOrDefaultAsync(f => f.Id == farmerProfileId, ct) ?? throw ApiException.NotFound();
        if (!staff.IsAdmin && farmer.AssignedVerifierId != staff.UserId) throw ApiException.Forbidden("farmer_other_verifier");
        if (farmer.Status != VerificationStatus.Pending) throw ApiException.Conflict("farmer_already_reviewed");

        farmer.Status = approve ? VerificationStatus.Verified : VerificationStatus.Rejected;
        farmer.Level = approve ? 2 : 1;
        farmer.RejectionReason = approve ? null : reason;
        farmer.ReviewedAt = DateTime.UtcNow;
        farmer.ReviewedBy = staff.UserId;
        farmer.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        await notifier.FarmerDecidedAsync(farmer.UserId, ct);
    }

    /// <summary>Approve (live: farmers can book it) or reject with a reason the host sees.</summary>
    public async Task DecideSpaceAsync(Guid spaceId, bool approve, string? reason, CancellationToken ct)
    {
        reason = DecisionReason(approve, reason, "reject_reason_host");
        var s = await db.Spaces.SingleOrDefaultAsync(x => x.Id == spaceId, ct) ?? throw ApiException.NotFound();
        if (s.Status != SpaceStatus.PendingReview) throw ApiException.Conflict("space_already_reviewed");
        s.Status = approve ? SpaceStatus.Live : SpaceStatus.Rejected;
        s.RejectionReason = approve ? null : reason;
        s.ReviewedAt = s.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        await notifier.SpaceDecidedAsync(s.Id, ct);
    }

    /// <summary>A rejection needs a reason (up to 500 characters); an approval ignores it.</summary>
    private static string? DecisionReason(bool approve, string? reason, string requiredCode)
    {
        reason = string.IsNullOrWhiteSpace(reason) ? null : reason.Trim();
        if (!approve && reason is null) throw ApiException.BadRequest(requiredCode);
        if (reason?.Length > 500) throw ApiException.BadRequest("reason_too_long", ("max", 500));
        return reason;
    }
}
