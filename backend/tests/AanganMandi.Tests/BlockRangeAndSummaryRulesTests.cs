using AanganMandi.Application.Analytics;
using AanganMandi.Domain.Spaces;
using Xunit;

namespace AanganMandi.Tests;

public class BlockRangeRulesTests
{
    private static readonly DateOnly Today = new(2026, 11, 20);

    [Fact]
    public void A_range_from_today_up_to_the_limit_can_be_blocked()
    {
        Assert.Null(BlockedDateRules.CheckRange(Today, Today, Today, null));
        Assert.Null(BlockedDateRules.CheckRange(Today, Today.AddDays(BlockedDateRules.MaxDaysAhead), Today, "Travelling"));
    }

    [Fact]
    public void A_backwards_past_too_far_or_long_noted_range_is_refused()
    {
        Assert.Equal("block_range_order", BlockedDateRules.CheckRange(Today.AddDays(3), Today.AddDays(2), Today, null)!.Code);
        Assert.Equal("block_date_past", BlockedDateRules.CheckRange(Today.AddDays(-1), Today, Today, null)!.Code);
        Assert.Equal("block_date_too_far",
            BlockedDateRules.CheckRange(Today, Today.AddDays(BlockedDateRules.MaxDaysAhead + 1), Today, null)!.Code);
        Assert.Equal("block_note_long", BlockedDateRules.CheckRange(Today, Today, Today, new string('x', 101))!.Code);
    }

    [Fact]
    public void Days_lists_every_day_including_both_ends()
    {
        Assert.Equal([Today, Today.AddDays(1), Today.AddDays(2)], BlockedDateRules.Days(Today, Today.AddDays(2)));
        Assert.Equal([Today], BlockedDateRules.Days(Today, Today));
    }
}

public class SummaryRulesTests
{
    private static readonly DateOnly Today = new(2026, 11, 20);
    private static StallRow Row(int daysAgo, decimal fee, bool held = false, bool noShow = false) =>
        new(Guid.Empty, Guid.Empty, Today.AddDays(-daysAgo), fee, held, noShow);

    [Fact]
    public void Tally_counts_held_stalls_no_shows_and_only_the_held_fees()
    {
        var t = SummaryRules.Tally([Row(3, 50, held: true), Row(2, 50, noShow: true), Row(1, 40, held: true), Row(1, 99)]);
        Assert.Equal(new StallTally(2, 1, 90), t);
        Assert.Equal(new StallTally(0, 0, 0), SummaryRules.Tally([]));
    }

    [Fact]
    public void Upcoming_is_today_or_later_and_not_held_or_missed_yet()
    {
        Assert.True(SummaryRules.IsUpcoming(Row(0, 0), Today));
        Assert.True(SummaryRules.IsUpcoming(Row(-2, 0), Today));
        Assert.False(SummaryRules.IsUpcoming(Row(0, 0, held: true), Today));
        Assert.False(SummaryRules.IsUpcoming(Row(1, 0), Today));
    }

    [Fact]
    public void Top_groups_ignoring_case_and_orders_by_count_then_name()
    {
        var top = SummaryRules.Top(["Onion", "tomato", "Tomato ", "Brinjal", "onion", "TOMATO", " "], count: 2);
        Assert.Equal([("tomato", 3), ("Onion", 2)], top);
    }
}
