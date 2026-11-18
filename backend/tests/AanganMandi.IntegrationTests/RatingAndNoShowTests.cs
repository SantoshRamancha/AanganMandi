using System.Net;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.IntegrationTests;

/// <summary>Ratings after a stall, and no-shows: counted, shown to hosts, blocking at the limit, cleared by an admin.</summary>
[Collection(ApiCollection.Name)]
public class RatingAndNoShowTests(ApiFactory api)
{
    [Fact]
    public async Task After_the_stall_each_side_rates_the_other_once_and_the_averages_show()
    {
        var admin = await api.AdminAsync();
        var (host, spaceId) = await Scenario.LiveSpaceAsync(api, admin, "Rated courtyard");
        var farmer = await api.VerifiedFarmerAsync();

        // Not before it happened.
        var (_, upcoming) = await Scenario.ConfirmedStallAsync(farmer, host, spaceId);
        Assert.Equal("rating_too_early", await farmer.RefusedAsync(HttpMethod.Post, $"/api/v1/bookings/{upcoming}/rating",
            new { stars = 5 }, HttpStatusCode.Conflict));
        await api.DbAsync(async db => (await db.Bookings.SingleAsync(b => b.Id == upcoming)).Date = Scenario.Tomorrow.AddDays(20));

        var (tripId, bookingId) = await Scenario.PastStallAsync(api, farmer, host, spaceId);
        var trip = await farmer.GetJsonAsync($"/api/v1/farmers/me/trips/{tripId}");
        Assert.True(trip["booking"]!["canRate"]!.GetValue<bool>());

        var given = await farmer.PostAsync($"/api/v1/bookings/{bookingId}/rating", new { stars = 4, comment = "  Clean and easy to reach " });
        Assert.Equal("Farmer", given!["by"]!.GetValue<string>());
        Assert.Equal("Clean and easy to reach", given["comment"]!.GetValue<string>());
        Assert.Equal("rating_already_given", await farmer.RefusedAsync(HttpMethod.Post, $"/api/v1/bookings/{bookingId}/rating",
            new { stars = 1 }, HttpStatusCode.Conflict));
        Assert.Equal("rating_stars", await host.RefusedAsync(HttpMethod.Post, $"/api/v1/bookings/{bookingId}/rating",
            new { stars = 9 }, HttpStatusCode.BadRequest));
        await host.PostAsync($"/api/v1/bookings/{bookingId}/rating", new { stars = 5 });

        // Someone else's booking is not theirs to rate.
        var stranger = await api.SignInAsync("Buyer");
        Assert.Equal("not_found", await stranger.RefusedAsync(HttpMethod.Post, $"/api/v1/bookings/{bookingId}/rating",
            new { stars = 3 }, HttpStatusCode.NotFound));

        trip = await farmer.GetJsonAsync($"/api/v1/farmers/me/trips/{tripId}");
        Assert.False(trip["booking"]!["canRate"]!.GetValue<bool>());
        Assert.Equal(4, trip["booking"]!["myStars"]!.GetValue<int>());

        var other = await api.VerifiedFarmerAsync();
        var card = Scenario.Find(await other.GetJsonAsync($"/api/v1/farmers/me/trips/{await Scenario.TripAsync(other)}/spaces"), spaceId)!;
        Assert.Equal(4.0, card["rating"]!.GetValue<double>());
        Assert.Equal(1, card["ratingCount"]!.GetValue<int>());

        var past = Scenario.Find(await host.GetJsonAsync("/api/v1/hosts/me/bookings?view=past"), bookingId)!;
        Assert.Equal(5.0, past["farmer"]!["rating"]!.GetValue<double>());
        Assert.Equal(5, past["myStars"]!.GetValue<int>());

        var hostRecord = await host.GetJsonAsync("/api/v1/users/me/record");
        Assert.Equal(4.0, hostRecord["asHost"]!["rating"]!.GetValue<double>());
        var farmerRecord = await farmer.GetJsonAsync("/api/v1/users/me/record");
        Assert.Equal(5.0, farmerRecord["asFarmer"]!["rating"]!.GetValue<double>());
    }

    [Fact]
    public async Task No_shows_are_shown_to_hosts_block_new_requests_at_the_limit_and_an_admin_can_clear_one()
    {
        var admin = await api.AdminAsync();
        var (host, spaceId) = await Scenario.LiveSpaceAsync(api, admin, "No-show courtyard");
        var farmer = await api.VerifiedFarmerAsync();

        var missed = new List<Guid>();
        for (var daysAgo = 1; daysAgo <= 3; daysAgo++)
        {
            var (_, bookingId) = await Scenario.PastStallAsync(api, farmer, host, spaceId, daysAgo);
            await host.PostAsync($"/api/v1/hosts/me/bookings/{bookingId}/no-show", expected: HttpStatusCode.NoContent);
            missed.Add(bookingId);
        }

        // The farmer cannot rate a stall they missed; the host still can rate them.
        Assert.Equal("rating_no_show", await farmer.RefusedAsync(HttpMethod.Post, $"/api/v1/bookings/{missed[0]}/rating",
            new { stars = 5 }, HttpStatusCode.Conflict));
        await host.PostAsync($"/api/v1/bookings/{missed[0]}/rating", new { stars = 1, comment = "Did not come" });

        var record = await farmer.GetJsonAsync("/api/v1/users/me/record");
        Assert.Equal(3, record["asFarmer"]!["recentNoShows"]!.GetValue<int>());
        Assert.Equal(3, record["asFarmer"]!["noShowLimit"]!.GetValue<int>());

        // At the limit no new requests.
        var tripId = await Scenario.TripAsync(farmer);
        var blocked = await farmer.SendAsync(HttpMethod.Post, $"/api/v1/farmers/me/trips/{tripId}/bookings", new { spaceId }, HttpStatusCode.Conflict);
        Assert.Equal("too_many_no_shows", blocked!["code"]!.GetValue<string>());
        Assert.Equal(3, blocked["args"]!["count"]!.GetValue<int>());

        // Hosts see the record on other requests; admins see the bookings behind it and clear a wrong one.
        var profileId = await api.QueryAsync(db => db.FarmerProfiles.Where(f => f.UserId == farmer.Id).Select(f => f.Id).SingleAsync());
        var detail = await admin.GetJsonAsync($"/api/v1/ops/farmers/{profileId}");
        Assert.Equal(3, detail["record"]!["recentNoShows"]!.GetValue<int>());
        Assert.Equal(3, detail["record"]!["noShows"]!.AsArray().Count);
        Assert.Equal(1.0, detail["record"]!["rating"]!.GetValue<double>());

        var verifier = await api.SignInAsync();
        await api.DbAsync(db =>
        {
            db.UserRoles.Add(new Domain.Identity.UserRole { UserId = verifier.Id, Role = Domain.Identity.Role.Verifier });
            return Task.CompletedTask;
        });
        Assert.Equal(HttpStatusCode.Forbidden,
            (await verifier.Http.PostAsync($"/api/v1/ops/farmers/{profileId}/no-shows/{missed[1]}/clear", null)).StatusCode);

        await admin.PostAsync($"/api/v1/ops/farmers/{profileId}/no-shows/{missed[1]}/clear", expected: HttpStatusCode.NoContent);
        Assert.Equal("no_show_not_marked", await admin.RefusedAsync(HttpMethod.Post,
            $"/api/v1/ops/farmers/{profileId}/no-shows/{missed[1]}/clear", null, HttpStatusCode.Conflict));

        var booked = await farmer.PostAsync($"/api/v1/farmers/me/trips/{tripId}/bookings", new { spaceId });
        Assert.Equal("Requested", booked!["status"]!.GetValue<string>());
        var request = Scenario.Find(await host.GetJsonAsync("/api/v1/hosts/me/bookings?view=requests"), booked["id"]!.GetValue<Guid>())!;
        Assert.Equal(2, request["farmer"]!["recentNoShows"]!.GetValue<int>());
    }

    [Fact]
    public async Task A_farmer_who_checked_in_cannot_be_marked_as_a_no_show()
    {
        var admin = await api.AdminAsync();
        var (host, spaceId) = await Scenario.LiveSpaceAsync(api, admin, "Arrival courtyard");
        var farmer = await api.VerifiedFarmerAsync();
        var (_, bookingId) = await Scenario.PastStallAsync(api, farmer, host, spaceId);
        await api.DbAsync(async db => (await db.Bookings.SingleAsync(b => b.Id == bookingId)).ArrivedAt = DateTime.UtcNow.AddDays(-1));

        Assert.Equal("no_show_checked_in", await host.RefusedAsync(HttpMethod.Post, $"/api/v1/hosts/me/bookings/{bookingId}/no-show",
            null, HttpStatusCode.Conflict));
        var request = Scenario.Find(await host.GetJsonAsync("/api/v1/hosts/me/bookings?view=past"), bookingId)!;
        Assert.Equal(1, request["farmer"]!["completedStalls"]!.GetValue<int>());
    }
}
