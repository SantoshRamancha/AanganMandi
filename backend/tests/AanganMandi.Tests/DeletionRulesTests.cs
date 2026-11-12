using AanganMandi.Domain.Farmers;
using AanganMandi.Domain.Trips;

namespace AanganMandi.Tests;

/// <summary>What deleting a space cancels, and what resetting a farmer's verification clears.</summary>
public class DeletionRulesTests
{
    private static readonly DateOnly Today = new(2026, 11, 10);

    [Theory]
    [InlineData(BookingStatus.Requested, 0, true)]
    [InlineData(BookingStatus.Accepted, 3, true)]
    [InlineData(BookingStatus.Accepted, -1, false)]   // already happened: stays in the past list
    [InlineData(BookingStatus.Requested, -1, false)]
    [InlineData(BookingStatus.Declined, 2, false)]
    [InlineData(BookingStatus.Cancelled, 2, false)]
    public void Deleting_a_space_cancels_only_waiting_or_confirmed_bookings_from_today(BookingStatus status, int days, bool cancelled) =>
        Assert.Equal(cancelled, new Booking { Status = status, Date = Today.AddDays(days) }.IsUpcoming(Today));

    [Theory]
    [InlineData(VerificationStatus.NotStarted, true)]
    [InlineData(VerificationStatus.Pending, true)]
    [InlineData(VerificationStatus.Rejected, true)]
    [InlineData(VerificationStatus.Verified, false)]
    public void Verification_can_be_reset_until_verified(VerificationStatus status, bool allowed) =>
        Assert.Equal(allowed, new FarmerProfile { Status = status }.CanReset);

    [Fact]
    public void Reset_clears_details_and_evidence_but_keeps_the_verifier()
    {
        var verifier = Guid.NewGuid();
        var farmer = new FarmerProfile
        {
            Village = "Kondapur", Mandal = "Serilingampally", District = "Rangareddy", FarmSizeAcres = 2.5m,
            ProduceSource = ProduceSource.OwnFarm, EvidenceType = EvidenceType.AgriStackFarmerId, EvidenceDetails = "123",
            Crops = [new FarmerCrop { CropCode = "tomato" }],
            Status = VerificationStatus.Pending, Level = 1, RejectionReason = "old", SubmittedAt = DateTime.UtcNow,
            AssignedVerifierId = verifier,
        };

        farmer.ResetVerification();

        Assert.Null(farmer.Village);
        Assert.Null(farmer.Mandal);
        Assert.Null(farmer.District);
        Assert.Null(farmer.FarmSizeAcres);
        Assert.Null(farmer.ProduceSource);
        Assert.Null(farmer.EvidenceType);
        Assert.Null(farmer.EvidenceDetails);
        Assert.Empty(farmer.Crops);
        Assert.Equal(VerificationStatus.NotStarted, farmer.Status);
        Assert.Equal(0, farmer.Level);
        Assert.Null(farmer.RejectionReason);
        Assert.Null(farmer.SubmittedAt);
        Assert.Equal(verifier, farmer.AssignedVerifierId);
    }
}
