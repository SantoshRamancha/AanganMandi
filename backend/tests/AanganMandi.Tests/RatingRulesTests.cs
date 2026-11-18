using AanganMandi.Domain.Trips;

namespace AanganMandi.Tests;

/// <summary>When a stall can be rated, and when no-shows stop a farmer from requesting slots.</summary>
public class RatingRulesTests
{
    private static Booking Stall(BookingStatus status = BookingStatus.Accepted, DateTime? noShow = null) => new()
    {
        Date = new DateOnly(2026, 11, 20),
        From = new TimeOnly(16, 0),
        To = new TimeOnly(20, 0),
        Status = status,
        NoShowAt = noShow,
    };

    private static DateTime India(int day, int hour, int minute = 0) => new(2026, 11, day, hour, minute, 0);

    [Fact]
    public void Both_sides_can_rate_once_the_slot_has_ended()
    {
        Assert.False(RatingRules.CanRate(Stall(), RatingSide.Farmer, India(20, 19, 59)));
        Assert.Equal("rating_too_early", RatingRules.WhyNot(Stall(), RatingSide.Host, India(20, 12))!.Code);
        Assert.True(RatingRules.CanRate(Stall(), RatingSide.Farmer, India(20, 20)));
        Assert.True(RatingRules.CanRate(Stall(), RatingSide.Host, India(21, 9)));
    }

    [Fact]
    public void Ratings_close_after_the_window()
    {
        Assert.True(RatingRules.CanRate(Stall(), RatingSide.Host, India(20, 20).AddDays(RatingRules.WindowDays)));
        var late = RatingRules.WhyNot(Stall(), RatingSide.Host, India(20, 20).AddDays(RatingRules.WindowDays + 1));
        Assert.Equal("rating_too_late", late!.Code);
        Assert.Equal(RatingRules.WindowDays, late.Args["days"]);
    }

    [Theory]
    [InlineData(BookingStatus.Requested)]
    [InlineData(BookingStatus.Declined)]
    [InlineData(BookingStatus.Cancelled)]
    public void Only_confirmed_stalls_are_rated(BookingStatus status) =>
        Assert.Equal("rating_not_confirmed", RatingRules.WhyNot(Stall(status), RatingSide.Farmer, India(22, 9))!.Code);

    [Fact]
    public void A_farmer_who_did_not_come_cannot_rate_but_the_host_can_rate_them()
    {
        var missed = Stall(noShow: new DateTime(2026, 11, 20, 15, 0, 0, DateTimeKind.Utc));
        Assert.Equal("rating_no_show", RatingRules.WhyNot(missed, RatingSide.Farmer, India(21, 9))!.Code);
        Assert.True(RatingRules.CanRate(missed, RatingSide.Host, India(21, 9)));
    }

    [Theory]
    [InlineData(0, null, "rating_stars")]
    [InlineData(6, null, "rating_stars")]
    [InlineData(1, null, null)]
    [InlineData(5, "  Clean space, kind host  ", null)]
    public void Stars_are_one_to_five(int stars, string? comment, string? error) =>
        Assert.Equal(error, RatingRules.CheckInput(stars, comment)?.Code);

    [Fact]
    public void Comments_have_a_limit()
    {
        Assert.Null(RatingRules.CheckInput(4, new string('a', RatingRules.MaxComment)));
        Assert.Equal("rating_comment_long", RatingRules.CheckInput(4, new string('a', RatingRules.MaxComment + 1))!.Code);
    }

    [Fact]
    public void Too_many_recent_no_shows_block_new_requests()
    {
        Assert.Null(NoShowPolicy.CheckCanBook(0));
        Assert.Null(NoShowPolicy.CheckCanBook(NoShowPolicy.Limit - 1));
        var blocked = NoShowPolicy.CheckCanBook(NoShowPolicy.Limit);
        Assert.Equal("too_many_no_shows", blocked!.Code);
        Assert.Equal(NoShowPolicy.Limit, blocked.Args["count"]);
        Assert.Equal(NoShowPolicy.WindowDays, blocked.Args["days"]);
        var now = new DateTime(2026, 11, 18, 0, 0, 0, DateTimeKind.Utc);
        Assert.Equal(now.AddDays(-90), NoShowPolicy.WindowStart(now));
    }

    [Fact]
    public void Averages_round_to_one_decimal()
    {
        Assert.Equal(StarSummary.None, StarSummary.Of([]));
        Assert.Equal(new StarSummary(4.3, 3), StarSummary.Of([5, 4, 4]));
    }
}
