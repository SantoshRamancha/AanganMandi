using AanganMandi.Application.Analytics;
using AanganMandi.Application.Master;
using AanganMandi.Domain.Spaces;
using Xunit;

namespace AanganMandi.Tests;

public class CropMatchTests
{
    private static readonly Dictionary<string, string[]> Names = new()
    {
        ["tomato"] = ["Tomato", "టమాటా", "टमाटर"],
        ["onion"] = ["Onion", "ఉల్లిపాయ", "प्याज़"],
    };

    [Theory]
    [InlineData("tomato", "tomato", true)]
    [InlineData("onion", "tomato", false)]
    // A crop the farmer typed in matches the master crop of that name, in any language, ignoring case.
    [InlineData("custom:tomato", "tomato", true)]
    [InlineData("custom:టమాటా", "tomato", true)]
    [InlineData("tomato", "custom:Tomato", true)]
    // Two typed-in crops match by name.
    [InlineData("custom:Drumstick", "custom:drumstick ", true)]
    [InlineData("custom:Drumstick", "custom:Drum", false)]
    public void Matches_by_code_or_name(string produce, string wanted, bool expected) =>
        Assert.Equal(expected, CropMatch.Matches(produce, [wanted], Names));

    [Fact]
    public void Matching_returns_the_produce_that_matched_and_nothing_when_looking_for_any()
    {
        string[] produce = ["onion", "custom:Drumstick", "tomato"];
        Assert.Equal(["custom:Drumstick", "tomato"], CropMatch.Matching(produce, ["tomato", "custom:drumstick"], Names));
        Assert.Empty(CropMatch.Matching(produce, [], Names));
    }

    [Fact]
    public void Saved_list_round_trips_and_empty_is_null()
    {
        Assert.Null(CropMatch.Join([]));
        Assert.Equal("tomato,custom:Drumstick", CropMatch.Join(["tomato", "custom:Drumstick"]));
        Assert.Equal(["tomato", "custom:Drumstick"], CropMatch.Split("tomato, custom:Drumstick"));
        Assert.Empty(CropMatch.Split(null));
    }
}

public class BlockedDateRulesTests
{
    private static readonly DateOnly Today = new(2026, 11, 19);

    [Fact]
    public void Today_up_to_the_limit_can_be_blocked()
    {
        Assert.Null(BlockedDateRules.Check(Today, Today, null));
        Assert.Null(BlockedDateRules.Check(Today.AddDays(BlockedDateRules.MaxDaysAhead), Today, "Wedding at home"));
    }

    [Fact]
    public void Past_too_far_and_long_notes_are_refused()
    {
        Assert.Equal("block_date_past", BlockedDateRules.Check(Today.AddDays(-1), Today, null)!.Code);
        var far = BlockedDateRules.Check(Today.AddDays(BlockedDateRules.MaxDaysAhead + 1), Today, null)!;
        Assert.Equal("block_date_too_far", far.Code);
        Assert.Equal("block_note_long", BlockedDateRules.Check(Today, Today, new string('x', 101))!.Code);
        Assert.Null(BlockedDateRules.Check(Today, Today, " " + new string('x', 100) + " "));
    }
}

public class AnalyticsRulesTests
{
    [Fact]
    public void A_period_ends_today_and_counts_today()
    {
        var today = new DateOnly(2026, 11, 19);
        Assert.Equal((new DateOnly(2026, 11, 13), today), AnalyticsRules.Range(7, today));
        Assert.Equal(30, AnalyticsRules.Days(AnalyticsRules.Range(30, today).From, today).Count());
    }

    [Fact]
    public void India_days_start_at_18_30_utc_the_evening_before()
    {
        var start = AnalyticsRules.StartUtc(new DateOnly(2026, 11, 19));
        Assert.Equal(new DateTime(2026, 11, 18, 18, 30, 0, DateTimeKind.Utc), start);
        Assert.Equal(new DateOnly(2026, 11, 19), AnalyticsRules.IndiaDate(start));
        Assert.Equal(new DateOnly(2026, 11, 18), AnalyticsRules.IndiaDate(start.AddSeconds(-1)));
    }

    [Theory]
    [InlineData(0, 0, null)]
    [InlineData(1, 3, 33)]
    [InlineData(2, 3, 67)]
    [InlineData(5, 5, 100)]
    public void Percent_is_whole_and_null_without_a_whole(int part, int whole, int? expected) =>
        Assert.Equal(expected, AnalyticsRules.Percent(part, whole));
}
