using AanganMandi.Domain.Trips;

namespace AanganMandi.Tests;

/// <summary>Checking in on the booking day, and marking a no-show.</summary>
public class ArrivalRulesTests
{
    private static readonly DateOnly Day = new(2026, 11, 14);

    private static Booking Confirmed() => new()
    {
        Status = BookingStatus.Accepted, Date = Day, From = new TimeOnly(16, 0), To = new TimeOnly(20, 0),
    };

    private static DateTime At(int hour, int minute, int dayOffset = 0) =>
        Day.AddDays(dayOffset).ToDateTime(new TimeOnly(hour, minute));

    [Fact]
    public void Distance_is_in_metres()
    {
        // Ameerpet metro to Ameerpet bus stop: roughly 450 m apart.
        var d = ArrivalRules.DistanceMeters(17.4375, 78.4482, 17.4365, 78.4440);
        Assert.InRange(d, 400, 500);
        Assert.Equal(0, ArrivalRules.DistanceMeters(17.4, 78.4, 17.4, 78.4), 3);
    }

    [Theory]
    [InlineData(15, 0)]   // an hour early, to set up
    [InlineData(16, 30)]
    [InlineData(19, 59)]
    public void A_confirmed_farmer_at_the_space_can_check_in_during_the_slot(int h, int m) =>
        Assert.Null(ArrivalRules.CheckArrival(Confirmed(), At(h, m), 120));

    [Fact]
    public void Check_in_is_refused_when_too_far_and_says_how_far()
    {
        var error = ArrivalRules.CheckArrival(Confirmed(), At(16, 0), 734);
        Assert.Equal("too_far", error?.Code);
        Assert.Equal(730, error!.Args["meters"]);
        Assert.Contains("730 m", Infrastructure.Errors.ErrorText.Render(error, "en"));
    }

    [Fact]
    public void Check_in_is_refused_outside_the_day_and_the_window()
    {
        var early = ArrivalRules.CheckArrival(Confirmed(), At(14, 59), 10);
        Assert.Equal("checkin_not_open", early?.Code);
        Assert.Equal("15:00", early!.Args["time"]);
        Assert.Equal("slot_ended", ArrivalRules.CheckArrival(Confirmed(), At(20, 0), 10)?.Code);
        Assert.Equal("checkin_day_passed", ArrivalRules.CheckArrival(Confirmed(), At(16, 0, dayOffset: 1), 10)?.Code);
        Assert.Equal("checkin_future_day", ArrivalRules.CheckArrival(Confirmed(), At(16, 0, dayOffset: -1), 10)?.Code);
    }

    [Fact]
    public void Only_a_confirmed_booking_checks_in_and_only_once()
    {
        var requested = Confirmed();
        requested.Status = BookingStatus.Requested;
        Assert.NotNull(ArrivalRules.CheckArrival(requested, At(16, 0), 10));
        var arrived = Confirmed();
        arrived.ArrivedAt = DateTime.UtcNow;
        Assert.NotNull(ArrivalRules.CheckArrival(arrived, At(16, 0), 10));
    }

    [Fact]
    public void A_no_show_can_be_marked_only_after_the_slot_without_a_check_in()
    {
        Assert.False(ArrivalRules.CanMarkNoShow(Confirmed(), At(19, 59)));
        Assert.True(ArrivalRules.CanMarkNoShow(Confirmed(), At(20, 0)));
        Assert.True(ArrivalRules.CanMarkNoShow(Confirmed(), At(9, 0, dayOffset: 1)));

        var arrived = Confirmed();
        arrived.ArrivedAt = DateTime.UtcNow;
        Assert.False(ArrivalRules.CanMarkNoShow(arrived, At(21, 0)));
        var marked = Confirmed();
        marked.NoShowAt = DateTime.UtcNow;
        Assert.False(ArrivalRules.CanMarkNoShow(marked, At(21, 0)));
    }

    [Fact]
    public void Every_stored_time_comes_back_as_utc_and_goes_out_with_a_z()
    {
        var fromDb = new DateTime(2026, 11, 12, 6, 47, 0, DateTimeKind.Unspecified);
        var read = Infrastructure.Persistence.UtcDateTimes.FromStore(fromDb);
        Assert.Equal(DateTimeKind.Utc, read.Kind);
        Assert.Equal(fromDb.Ticks, read.Ticks);   // same moment, only marked
        Assert.EndsWith("Z", System.Text.Json.JsonSerializer.Serialize(read).Trim('"'));

        var local = new DateTime(2026, 11, 12, 12, 17, 0, DateTimeKind.Local);
        Assert.Equal(local.ToUniversalTime(), Infrastructure.Persistence.UtcDateTimes.ToStore(local));
    }

    [Theory]
    [InlineData(734, 730)]
    [InlineData(1260, 1300)]
    public void Distances_are_rounded_for_people(double m, int shown) => Assert.Equal(shown, ArrivalRules.RoundedMeters(m));
}
