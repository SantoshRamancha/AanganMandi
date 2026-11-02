using AanganMandi.Application.Farmers;
using static AanganMandi.Application.Farmers.VerifierPicker;

namespace AanganMandi.Tests;

public class VerifierPickerTests
{
    private static readonly Guid Farmer = Guid.NewGuid();
    private static readonly Guid A = Guid.NewGuid(), B = Guid.NewGuid(), C = Guid.NewGuid();
    private static readonly DateTime Day1 = new(2026, 11, 1), Day2 = new(2026, 11, 2);

    [Fact]
    public void Picks_the_verifier_with_fewest_open_reviews() =>
        Assert.Equal(B, Pick([new(A, 3, Day1), new(B, 1, Day2), new(C, 2, Day1)], Farmer));

    [Fact]
    public void Breaks_ties_by_the_longest_serving_verifier() =>
        Assert.Equal(A, Pick([new(B, 0, Day2), new(A, 0, Day1)], Farmer));

    [Fact]
    public void Resubmission_goes_back_to_the_previous_verifier_even_if_busier() =>
        Assert.Equal(A, Pick([new(A, 5, Day1), new(B, 0, Day1)], Farmer, previous: A));

    [Fact]
    public void Previous_verifier_who_was_removed_is_skipped() =>
        Assert.Equal(B, Pick([new(B, 0, Day1)], Farmer, previous: A));

    [Fact]
    public void Verifier_never_reviews_their_own_farmer_profile() =>
        Assert.Equal(B, Pick([new(Farmer, 0, Day1), new(B, 4, Day2)], Farmer, previous: Farmer));

    [Fact]
    public void No_verifiers_leaves_the_farmer_unassigned() =>
        Assert.Null(Pick([], Farmer));
}
