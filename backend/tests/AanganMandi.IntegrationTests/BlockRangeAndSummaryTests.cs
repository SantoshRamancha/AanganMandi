using System.Net;
using System.Text.Json.Nodes;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.IntegrationTests;

/// <summary>Hosts blocking several days at once, and the hosts' and farmers' own summaries.</summary>
[Collection(ApiCollection.Name)]
public class BlockRangeAndSummaryTests(ApiFactory api)
{
    private static string Day(int ahead) => TripService.Today.AddDays(ahead).ToString("yyyy-MM-dd");
    private static string[] Dates(JsonNode? list) => [.. list!.AsArray().Select(d => d!.GetValue<string>())];

    [Fact]
    public async Task A_range_blocks_the_open_days_skips_confirmed_ones_and_declines_waiting_requests()
    {
        var admin = await api.AdminAsync();
        var (host, spaceId) = await Scenario.LiveSpaceAsync(api, admin, "Range courtyard");
        await Scenario.ConfirmedStallAsync(await api.VerifiedFarmerAsync(), host, spaceId); // tomorrow
        var waiting = await api.VerifiedFarmerAsync();
        var trip = await Scenario.TripAsync(waiting, TripService.Today.AddDays(2));
        var request = await waiting.PostAsync($"/api/v1/farmers/me/trips/{trip}/bookings", new { spaceId });
        var requestId = request!["id"]!.GetValue<Guid>();
        var url = $"/api/v1/hosts/me/spaces/{spaceId}/blocked-dates";

        var result = await host.PostAsync($"{url}/range", new { from = Day(1), to = Day(3), note = " Travelling " });
        Assert.Equal([Day(2), Day(3)], Dates(result!["blocked"]));
        Assert.Equal([Day(1)], Dates(result["booked"]));
        Assert.Equal(1, result["declinedRequests"]!.GetValue<int>());
        var declined = await api.QueryAsync(db => db.Bookings.SingleAsync(b => b.Id == requestId));
        Assert.Equal(BookingStatus.Declined, declined.Status);
        Assert.Equal("Travelling", declined.Reason);

        var list = (await host.GetJsonAsync(url)).AsArray();
        Assert.Equal([Day(2), Day(3)], list.Select(d => d!["date"]!.GetValue<string>()));
        Assert.All(list, d => Assert.Equal("Travelling", d!["note"]!.GetValue<string>()));

        // Blocking an overlapping range again changes the note and adds the new day.
        result = await host.PostAsync($"{url}/range", new { from = Day(3), to = Day(4), note = (string?)null });
        Assert.Equal([Day(3), Day(4)], Dates(result!["blocked"]));
        Assert.Equal(3, (await host.GetJsonAsync(url)).AsArray().Count);

        Assert.Equal("block_range_order", await host.RefusedAsync(HttpMethod.Post, $"{url}/range",
            new { from = Day(5), to = Day(4) }, HttpStatusCode.BadRequest));
        Assert.Equal("block_date_too_far", await host.RefusedAsync(HttpMethod.Post, $"{url}/range",
            new { from = Day(5), to = Day(61) }, HttpStatusCode.BadRequest));
        Assert.Equal("block_date_past", await host.RefusedAsync(HttpMethod.Post, $"{url}/range",
            new { from = Day(-1), to = Day(1) }, HttpStatusCode.BadRequest));

        // Only the weekdays the space is open are blocked; a range with none of them is refused.
        var openDay = TripService.Today.AddDays(10).DayOfWeek;
        await api.DbAsync(async db => (await db.Spaces.SingleAsync(s => s.Id == spaceId)).AvailableDays = openDay.ToString());
        result = await host.PostAsync($"{url}/range", new { from = Day(8), to = Day(14) });
        Assert.Equal([Day(10)], Dates(result!["blocked"]));
        Assert.Equal("block_range_closed", await host.RefusedAsync(HttpMethod.Post, $"{url}/range",
            new { from = Day(11), to = Day(16) }, HttpStatusCode.BadRequest));

        var stranger = await api.SignInAsync("Host");
        Assert.Equal("not_found", await stranger.RefusedAsync(HttpMethod.Post, $"{url}/range",
            new { from = Day(1), to = Day(2) }, HttpStatusCode.NotFound));
    }

    [Fact]
    public async Task Hosts_see_their_earnings_and_farmers_their_stalls()
    {
        var admin = await api.AdminAsync();
        const string title = "Earnings courtyard";
        var (host, spaceId) = await Scenario.LiveSpaceAsync(api, admin, title);
        var farmer = await api.VerifiedFarmerAsync();
        var (_, held) = await Scenario.PastStallAsync(api, farmer, host, spaceId, daysAgo: 3);
        var (_, missed) = await Scenario.PastStallAsync(api, farmer, host, spaceId, daysAgo: 2);
        var (_, upcoming) = await Scenario.ConfirmedStallAsync(farmer, host, spaceId);
        await api.DbAsync(async db =>
        {
            foreach (var b in await db.Bookings.Where(b => b.SpaceId == spaceId).ToListAsync()) b.Fee = 50;
            (await db.Bookings.SingleAsync(b => b.Id == held)).ArrivedAt = DateTime.UtcNow.AddDays(-3);
        });
        await host.PostAsync($"/api/v1/hosts/me/bookings/{missed}/no-show", expected: HttpStatusCode.NoContent);

        var h = await host.GetJsonAsync("/api/v1/hosts/me/summary?days=30");
        Assert.Equal(30, h["days"]!.GetValue<int>());
        Assert.Equal(1, h["held"]!.GetValue<int>());
        Assert.Equal(1, h["noShows"]!.GetValue<int>());
        Assert.Equal(50, h["feesEarned"]!.GetValue<decimal>());
        Assert.Equal(1, h["upcoming"]!.GetValue<int>());
        Assert.Equal(50, h["feesExpected"]!.GetValue<decimal>());
        Assert.Equal(3, h["requests"]!.GetValue<int>());
        Assert.Equal(3, h["accepted"]!.GetValue<int>());
        var space = h["spaces"]!.AsArray().Single()!;
        Assert.Equal(title, space["title"]!.GetValue<string>());
        Assert.Equal(50, space["fees"]!.GetValue<decimal>());

        var f = await farmer.GetJsonAsync("/api/v1/farmers/me/summary?days=90");
        Assert.Equal(2, f["trips"]!.GetValue<int>());
        Assert.Equal(1, f["held"]!.GetValue<int>());
        Assert.Equal(1, f["noShows"]!.GetValue<int>());
        Assert.Equal(50, f["feesPaid"]!.GetValue<decimal>());
        Assert.Equal(1, f["upcoming"]!.GetValue<int>());
        Assert.Equal("custom:Tomato", f["crops"]!.AsArray().Single()!["key"]!.GetValue<string>());
        Assert.Equal(title, f["places"]!.AsArray().Single()!["key"]!.GetValue<string>());

        Assert.Equal("summary_period", await host.RefusedAsync(HttpMethod.Get, "/api/v1/hosts/me/summary?days=7", null,
            HttpStatusCode.BadRequest));
        Assert.Equal(HttpStatusCode.Forbidden, (await farmer.Http.GetAsync("/api/v1/hosts/me/summary")).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await host.Http.GetAsync("/api/v1/farmers/me/summary")).StatusCode);
        Assert.NotEqual(Guid.Empty, upcoming);
    }
}
