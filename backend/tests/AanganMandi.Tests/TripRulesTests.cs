using AanganMandi.Application.Trips;
using AanganMandi.Domain.Spaces;

namespace AanganMandi.Tests;

public class TripRulesTests
{
    private static readonly DateOnly Today = new(2026, 11, 3); // a Tuesday

    [Fact]
    public void Today_is_the_India_date()
    {
        // 20:00 UTC is already 01:30 the next day in India.
        Assert.Equal(new DateOnly(2026, 11, 4), TripRules.TodayInIndia(new DateTime(2026, 11, 3, 20, 0, 0, DateTimeKind.Utc)));
        Assert.Equal(new DateOnly(2026, 11, 3), TripRules.TodayInIndia(new DateTime(2026, 11, 3, 10, 0, 0, DateTimeKind.Utc)));
    }

    [Fact]
    public void Trip_dates_from_today_to_60_days_ahead()
    {
        Assert.Null(TripRules.CheckDate(Today, Today));
        Assert.Null(TripRules.CheckDate(Today.AddDays(60), Today));
        Assert.NotNull(TripRules.CheckDate(Today.AddDays(-1), Today));
        Assert.NotNull(TripRules.CheckDate(Today.AddDays(61), Today));
    }

    [Theory]
    [InlineData(VehicleType.MiniTruck, VehicleType.Auto, true)]
    [InlineData(VehicleType.Auto, VehicleType.Auto, true)]
    [InlineData(VehicleType.Auto, VehicleType.MiniTruck, false)]
    [InlineData(VehicleType.TwoWheeler, VehicleType.Tractor, false)]
    [InlineData(VehicleType.Tractor, VehicleType.TwoWheeler, true)]
    public void Vehicle_must_fit(VehicleType spaceMax, VehicleType trip, bool fits) =>
        Assert.Equal(fits, TripRules.VehicleFits(spaceMax, trip));

    [Fact]
    public void Open_only_on_listed_weekdays()
    {
        Assert.True(TripRules.OpenOn("Monday,Tuesday", Today));
        Assert.True(TripRules.OpenOn("Tuesday", Today));
        Assert.False(TripRules.OpenOn("Saturday,Sunday", Today));
        Assert.False(TripRules.OpenOn("", Today));
    }
}
