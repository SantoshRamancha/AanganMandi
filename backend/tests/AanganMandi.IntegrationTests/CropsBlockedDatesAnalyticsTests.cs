using System.Net;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.IntegrationTests;

/// <summary>Buyers looking for crops, hosts blocking days, and the admin analytics.</summary>
[Collection(ApiCollection.Name)]
public class CropsBlockedDatesAnalyticsTests(ApiFactory api)
{
    private static object Area(int radiusKm = 1) => new { latitude = 17.4486, longitude = 78.3908, radiusKm, alertsOn = false };

    [Fact]
    public async Task A_buyer_sees_only_farmers_selling_the_crops_they_look_for()
    {
        var admin = await api.AdminAsync();
        var (host, spaceId) = await Scenario.LiveSpaceAsync(api, admin, "Crop courtyard");
        var farmer = await api.VerifiedFarmerAsync();
        var (_, bookingId) = await Scenario.ConfirmedStallAsync(farmer, host, spaceId); // brings "custom:Tomato"

        var buyer = await api.SignInAsync("Buyer");
        Assert.Equal("buyer_area_required", await buyer.RefusedAsync(HttpMethod.Put, "/api/v1/buyers/me/crops",
            new { crops = new[] { "TOMATO" } }, HttpStatusCode.Conflict));
        await buyer.PutAsync("/api/v1/buyers/me/area", Area(), HttpStatusCode.OK);

        async Task<bool> Listed(string query = "") => (await buyer.GetJsonAsync("/api/v1/buyers/me/nearby" + query)).AsArray()
            .Any(s => s!["bookingId"]!.GetValue<Guid>() == bookingId);

        Assert.True(await Listed());
        Assert.False(await Listed("?crops=ONION"));
        // The farmer typed "Tomato" by hand; it still matches the Tomato in the crop list.
        var match = (await buyer.GetJsonAsync("/api/v1/buyers/me/nearby?crops=ONION&crops=TOMATO")).AsArray()
            .Single(s => s!["bookingId"]!.GetValue<Guid>() == bookingId)!;
        Assert.Equal("custom:Tomato", match["matched"]!.AsArray().Single()!.GetValue<string>());

        // Saved crops filter the list (and the alerts) until cleared; ?crops= asks for any.
        var saved = await buyer.PutAsync("/api/v1/buyers/me/crops", new { crops = new[] { "ONION", "custom:Drumstick" } },
            HttpStatusCode.OK);
        Assert.Equal(["ONION", "custom:Drumstick"], saved!["area"]!["crops"]!.AsArray().Select(c => c!.GetValue<string>()));
        Assert.False(await Listed());
        Assert.True(await Listed("?crops="));
        await buyer.PutAsync("/api/v1/buyers/me/crops", new { crops = Array.Empty<string>() }, HttpStatusCode.OK);
        Assert.True(await Listed());

        Assert.Equal("crops_too_many", await buyer.RefusedAsync(HttpMethod.Put, "/api/v1/buyers/me/crops",
            new { crops = Enumerable.Range(1, 11).Select(i => $"custom:Crop {(char)('a' + i)}").ToArray() }, HttpStatusCode.BadRequest));
        Assert.Equal("crop_unknown", await buyer.RefusedAsync(HttpMethod.Put, "/api/v1/buyers/me/crops",
            new { crops = new[] { "NOT_A_CROP" } }, HttpStatusCode.BadRequest));
    }

    [Fact]
    public async Task A_blocked_day_declines_its_requests_hides_the_space_and_cannot_hide_a_confirmed_farmer()
    {
        var admin = await api.AdminAsync();
        var (host, spaceId) = await Scenario.LiveSpaceAsync(api, admin, "Blocked courtyard");
        var waiting = await api.VerifiedFarmerAsync();
        var waitingTrip = await Scenario.TripAsync(waiting);
        var request = await waiting.PostAsync($"/api/v1/farmers/me/trips/{waitingTrip}/bookings", new { spaceId });
        var requestId = request!["id"]!.GetValue<Guid>();
        var blockUrl = $"/api/v1/hosts/me/spaces/{spaceId}/blocked-dates";
        var day = Scenario.Tomorrow.ToString("yyyy-MM-dd");

        var blocked = await host.PostAsync(blockUrl, new { date = day, note = "  Family function " });
        Assert.Equal(1, blocked!["declinedRequests"]!.GetValue<int>());
        Assert.Equal("Family function", blocked["note"]!.GetValue<string>());
        var declined = await api.QueryAsync(db => db.Bookings.SingleAsync(b => b.Id == requestId));
        Assert.Equal(BookingStatus.Declined, declined.Status);
        Assert.Equal("Family function", declined.Reason);

        // Blocking again only changes the note.
        await host.PostAsync(blockUrl, new { date = day, note = (string?)null });
        var list = (await host.GetJsonAsync(blockUrl)).AsArray();
        Assert.Equal(day, list.Single()!["date"]!.GetValue<string>());
        Assert.Null(list.Single()!["note"]);

        // Farmers neither find nor can request the space that day.
        var other = await api.VerifiedFarmerAsync();
        var trip = await Scenario.TripAsync(other);
        Assert.Null(Scenario.Find(await other.GetJsonAsync($"/api/v1/farmers/me/trips/{trip}/spaces"), spaceId));
        Assert.Equal("space_closed_that_day", await other.RefusedAsync(HttpMethod.Post,
            $"/api/v1/farmers/me/trips/{trip}/bookings", new { spaceId }, HttpStatusCode.Conflict));

        Assert.Equal("block_date_past", await host.RefusedAsync(HttpMethod.Post, blockUrl,
            new { date = TripService.Today.AddDays(-1).ToString("yyyy-MM-dd") }, HttpStatusCode.BadRequest));
        var stranger = await api.SignInAsync("Host");
        Assert.Equal("not_found", await stranger.RefusedAsync(HttpMethod.Post, blockUrl, new { date = day }, HttpStatusCode.NotFound));

        // Open again: the farmer can request; once confirmed the day cannot be blocked.
        Assert.Equal(HttpStatusCode.NoContent, (await host.Http.DeleteAsync($"{blockUrl}/{day}")).StatusCode);
        Assert.Empty((await host.GetJsonAsync(blockUrl)).AsArray());
        Assert.NotNull(Scenario.Find(await other.GetJsonAsync($"/api/v1/farmers/me/trips/{trip}/spaces"), spaceId));
        var booking = await other.PostAsync($"/api/v1/farmers/me/trips/{trip}/bookings", new { spaceId });
        await host.PostAsync($"/api/v1/hosts/me/bookings/{booking!["id"]}/accept", expected: HttpStatusCode.NoContent);
        Assert.Equal("block_date_booked", await host.RefusedAsync(HttpMethod.Post, blockUrl, new { date = day }, HttpStatusCode.Conflict));
    }

    [Fact]
    public async Task Admins_see_analytics_for_a_period_and_nobody_else_does()
    {
        var admin = await api.AdminAsync();
        var (host, spaceId) = await Scenario.LiveSpaceAsync(api, admin, "Analytics courtyard");
        var farmer = await api.VerifiedFarmerAsync();
        var (_, held) = await Scenario.PastStallAsync(api, farmer, host, spaceId);
        await api.DbAsync(async db => (await db.Bookings.SingleAsync(b => b.Id == held)).ArrivedAt = DateTime.UtcNow.AddDays(-1));
        var (_, missed) = await Scenario.PastStallAsync(api, farmer, host, spaceId, daysAgo: 2);
        await host.PostAsync($"/api/v1/hosts/me/bookings/{missed}/no-show", expected: HttpStatusCode.NoContent);

        var a = await admin.GetJsonAsync("/api/v1/ops/analytics?days=7");
        Assert.Equal(7, a["days"]!.GetValue<int>());
        Assert.Equal(TripService.Today.ToString("yyyy-MM-dd"), a["to"]!.GetValue<string>());
        var daily = a["daily"]!.AsArray();
        Assert.Equal(7, daily.Count);
        Assert.True(a["stalls"]!["confirmed"]!.GetValue<int>() >= 2);
        Assert.True(a["stalls"]!["held"]!.GetValue<int>() >= 1);
        Assert.True(a["stalls"]!["noShows"]!.GetValue<int>() >= 1);
        Assert.True(a["requests"]!["made"]!.GetValue<int>() >= 2);
        Assert.True(a["people"]!["spacesLive"]!.GetValue<int>() >= 1);
        var yesterday = daily.Single(d => d!["date"]!.GetValue<string>() == TripService.Today.AddDays(-1).ToString("yyyy-MM-dd"))!;
        Assert.True(yesterday["held"]!.GetValue<int>() >= 1);
        Assert.Contains(a["topAreas"]!.AsArray(), t => t!["key"]!.GetValue<string>() == "Madhapur");
        Assert.Contains(a["topCrops"]!.AsArray(), t => t!["key"]!.GetValue<string>() == "custom:Tomato");

        Assert.Equal("analytics_period", await admin.RefusedAsync(HttpMethod.Get, "/api/v1/ops/analytics?days=5", null,
            HttpStatusCode.BadRequest));
        Assert.Equal(HttpStatusCode.Forbidden, (await host.Http.GetAsync("/api/v1/ops/analytics")).StatusCode);
        var verifier = await api.SignInAsync();
        await api.DbAsync(db =>
        {
            db.UserRoles.Add(new Domain.Identity.UserRole { UserId = verifier.Id, Role = Domain.Identity.Role.Verifier });
            return Task.CompletedTask;
        });
        Assert.Equal(HttpStatusCode.Forbidden, (await verifier.Http.GetAsync("/api/v1/ops/analytics")).StatusCode);
    }
}
