namespace AanganMandi.Application.Farmers;

/// <summary>
/// Chooses who reviews a submitted farmer: the verifier who had them before (so a resubmission
/// goes back to the same person), otherwise the one with the fewest open reviews, oldest verifier first on a tie.
/// A verifier never reviews their own farmer profile.
/// </summary>
public static class VerifierPicker
{
    public record Candidate(Guid UserId, int OpenReviews, DateTime AddedAt);

    public static Guid? Pick(IEnumerable<Candidate> candidates, Guid farmerUserId, Guid? previous = null)
    {
        var eligible = candidates.Where(c => c.UserId != farmerUserId).ToList();
        if (previous is { } p && eligible.Any(c => c.UserId == p)) return p;
        return eligible.OrderBy(c => c.OpenReviews).ThenBy(c => c.AddedAt).Select(c => (Guid?)c.UserId).FirstOrDefault();
    }
}
