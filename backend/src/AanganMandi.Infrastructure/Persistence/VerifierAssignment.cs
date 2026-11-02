using AanganMandi.Application.Farmers;
using AanganMandi.Domain.Farmers;
using AanganMandi.Domain.Identity;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Infrastructure.Persistence;

/// <summary>Routes submitted farmers to verifiers. Used on submit, and when an admin adds or removes a verifier.</summary>
public static class VerifierAssignment
{
    /// <summary>Active verifiers with their count of farmers waiting for review.</summary>
    public static Task<List<VerifierPicker.Candidate>> CandidatesAsync(AppDbContext db, CancellationToken ct = default) =>
        (from r in db.UserRoles
         join u in db.Users on r.UserId equals u.Id
         where r.Role == Role.Verifier && u.Status == "Active"
         select new VerifierPicker.Candidate(r.UserId,
             db.FarmerProfiles.Count(f => f.AssignedVerifierId == r.UserId && f.Status == VerificationStatus.Pending),
             r.CreatedAt)).ToListAsync(ct);

    /// <summary>Assigns the farmer to a verifier, or leaves them unassigned (for an admin to pick up) when there is none.</summary>
    public static async Task AssignAsync(AppDbContext db, FarmerProfile farmer, CancellationToken ct = default)
    {
        farmer.AssignedVerifierId = VerifierPicker.Pick(await CandidatesAsync(db, ct), farmer.UserId, farmer.AssignedVerifierId);
        farmer.AssignedAt = DateTime.UtcNow;
    }

    /// <summary>
    /// Spreads the farmers waiting with <paramref name="fromVerifierId"/> (null: the unassigned ones) over the
    /// other active verifiers. Used when a verifier is removed, and when one is added. Caller saves.
    /// Returns how many farmers got a verifier.
    /// </summary>
    public static async Task<int> RedistributeAsync(AppDbContext db, Guid? fromVerifierId, CancellationToken ct = default)
    {
        var candidates = (await CandidatesAsync(db, ct)).Where(c => c.UserId != fromVerifierId).ToList();
        var waiting = await db.FarmerProfiles
            .Where(f => f.AssignedVerifierId == fromVerifierId && f.Status == VerificationStatus.Pending)
            .OrderBy(f => f.SubmittedAt).ToListAsync(ct);
        var assigned = 0;
        foreach (var farmer in waiting)
        {
            var pick = VerifierPicker.Pick(candidates, farmer.UserId);
            farmer.AssignedVerifierId = pick;
            farmer.AssignedAt = DateTime.UtcNow;
            var i = candidates.FindIndex(c => c.UserId == pick);
            if (i < 0) continue;
            candidates[i] = candidates[i] with { OpenReviews = candidates[i].OpenReviews + 1 };
            assigned++;
        }
        return assigned;
    }
}
