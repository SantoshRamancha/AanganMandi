using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Sharing;

namespace AanganMandi.Tests;

/// <summary>The public stall page a host shares with neighbours.</summary>
public class StallPageTests
{
    private static readonly DateOnly Day = new(2026, 11, 14);
    private static DateTime At(int h, int m = 0, int dayOffset = 0) => Day.AddDays(dayOffset).ToDateTime(new TimeOnly(h, m));

    private static Booking Confirmed() => new()
    {
        Status = BookingStatus.Accepted, Date = Day, From = new TimeOnly(16, 0), To = new TimeOnly(20, 0),
    };

    private static StallView View(StallState state, string? address = null) => new(state, Day, new TimeOnly(16, 0),
        new TimeOnly(20, 0), "Ramesh", "Nelakondapalli", [new StallCrop("Tomato", 30), new StallCrop("Onion", null)],
        "Green villa courtyard", "Ameerpet", address, address is null ? null : 17.43, address is null ? null : 78.44);

    [Fact]
    public void Codes_are_random_and_well_formed()
    {
        var a = StallStatus.NewCode();
        var b = StallStatus.NewCode();
        Assert.NotEqual(a, b);
        Assert.True(StallStatus.LooksLikeCode(a));
        Assert.False(StallStatus.LooksLikeCode("short"));
        Assert.False(StallStatus.LooksLikeCode("abc/../xyz"));
        Assert.False(StallStatus.LooksLikeCode("O0l1IO0l1I")); // look-alike letters are never used
    }

    [Fact]
    public void State_follows_the_booking_day()
    {
        Assert.Equal(StallState.Upcoming, StallStatus.StateOf(Confirmed(), At(9, 0, dayOffset: -1)));
        Assert.Equal(StallState.Upcoming, StallStatus.StateOf(Confirmed(), At(16, 30)));
        var arrived = Confirmed();
        arrived.ArrivedAt = DateTime.UtcNow;
        Assert.Equal(StallState.SellingNow, StallStatus.StateOf(arrived, At(16, 30)));
        Assert.Equal(StallState.Over, StallStatus.StateOf(arrived, At(20, 0)));
        Assert.Equal(StallState.Over, StallStatus.StateOf(Confirmed(), At(9, 0, dayOffset: 1)));

        var cancelled = Confirmed();
        cancelled.Status = BookingStatus.Cancelled;
        Assert.Equal(StallState.Over, StallStatus.StateOf(cancelled, At(16, 30)));
        var noShow = Confirmed();
        noShow.NoShowAt = DateTime.UtcNow;
        Assert.Equal(StallState.Over, StallStatus.StateOf(noShow, At(9, 0)));
    }

    [Fact]
    public void Upcoming_page_shows_the_area_but_never_the_address()
    {
        var html = StallPage.Render(View(StallState.Upcoming), "en", "http://x/s/abc", null);
        Assert.Contains("Fresh produce in Ameerpet", html);
        Assert.Contains("og:title", html);
        Assert.Contains("Ramesh, from Nelakondapalli", html);
        Assert.Contains("Tomato ₹30/kg", html);
        Assert.Contains("exact place shows here", html);
        Assert.DoesNotContain("google.com/maps", html);
    }

    [Fact]
    public void Selling_now_page_shows_the_address_and_a_map_link()
    {
        var html = StallPage.Render(View(StallState.SellingNow, "1 Road, Ameerpet"), "en", "http://x/s/abc", "http://app");
        Assert.Contains("Selling now", html);
        Assert.Contains("1 Road, Ameerpet", html);
        Assert.Contains("https://www.google.com/maps?q=17.43,78.44", html);
        Assert.Contains("http://app", html);
    }

    [Fact]
    public void Over_page_shows_no_stall_details()
    {
        var html = StallPage.Render(View(StallState.Over), "te", "http://x/s/abc", null);
        Assert.Contains("lang=\"te\"", html);
        Assert.DoesNotContain("Ramesh", html);
        Assert.DoesNotContain("Tomato", html);
    }

    [Fact]
    public void Everything_typed_by_users_is_encoded()
    {
        var view = View(StallState.Upcoming) with { SpaceTitle = "<script>alert(1)</script>", FarmerFirstName = "\"><b>x" };
        var html = StallPage.Render(view, "en", "http://x/s/abc", null);
        Assert.DoesNotContain("<script>alert", html);
        Assert.DoesNotContain("\"><b>x", html);
    }

    [Theory]
    [InlineData("te", null, "te")]
    [InlineData("xx", "hi-IN,hi;q=0.9,en;q=0.8", "hi")]
    [InlineData(null, "en-GB,te;q=0.5", "en")]
    [InlineData(null, "fr-FR", "en")]
    public void Language_comes_from_the_link_then_the_browser(string? query, string? accept, string expected) =>
        Assert.Equal(expected, StallPage.PickLanguage(query, accept));
}
