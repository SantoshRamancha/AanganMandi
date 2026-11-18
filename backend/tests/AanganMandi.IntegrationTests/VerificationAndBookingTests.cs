using System.Net;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.IntegrationTests;

/// <summary>The main journeys end to end: a farmer gets verified; a farmer books a host's space and the host confirms.</summary>
[Collection(ApiCollection.Name)]
public class VerificationAndBookingTests(ApiFactory api)
{
    [Fact]
    public async Task A_farmer_submits_verification_and_an_admin_approves_it()
    {
        var admin = await api.AdminAsync();
        var farmer = await api.SignInAsync("Farmer");

        await farmer.PutAsync("/api/v1/farmers/me/details", new
        {
            name = "Ramesh Reddy", village = "Nelakondapalli", district = "Medak", cropCodes = new[] { "custom:Tomato" },
            farmSizeAcres = 2.5, produceSource = "OwnFarm",
        });
        await farmer.PutAsync("/api/v1/farmers/me/evidence", new { type = "LandRecord", details = (string?)null });
        Assert.Equal("verification_incomplete",
            await farmer.RefusedAsync(HttpMethod.Post, "/api/v1/farmers/me/submit", null, HttpStatusCode.UnprocessableEntity));
        await farmer.UploadPhotoAsync("/api/v1/farmers/me/evidence/photo");
        await farmer.PostAsync("/api/v1/farmers/me/submit", expected: HttpStatusCode.NoContent);

        var waiting = await farmer.GetJsonAsync("/api/v1/farmers/me");
        Assert.Equal("Pending", waiting["status"]!.GetValue<string>());
        // Not verified yet: no trips.
        Assert.Equal("not_verified", await farmer.RefusedAsync(HttpMethod.Post, "/api/v1/farmers/me/trips", new
        {
            date = Scenario.Tomorrow.ToString("yyyy-MM-dd"), vehicle = "Auto", produce = new[] { new { cropCode = "custom:Tomato" } },
        }, HttpStatusCode.Forbidden));

        var profileId = await api.QueryAsync(db => db.FarmerProfiles.Where(f => f.UserId == farmer.Id).Select(f => f.Id).SingleAsync());
        await admin.PostAsync($"/api/v1/ops/farmers/{profileId}/decision", new { approve = true }, HttpStatusCode.NoContent);
        Assert.Equal("farmer_already_reviewed", await admin.RefusedAsync(HttpMethod.Post,
            $"/api/v1/ops/farmers/{profileId}/decision", new { approve = true }, HttpStatusCode.Conflict));

        var verified = await farmer.GetJsonAsync("/api/v1/farmers/me");
        Assert.Equal("Verified", verified["status"]!.GetValue<string>());
        Assert.Equal(2, verified["level"]!.GetValue<int>());
        await Scenario.TripAsync(farmer);
    }

    [Fact]
    public async Task A_farmer_books_a_space_the_host_confirms_and_both_see_each_others_phone()
    {
        var admin = await api.AdminAsync();
        var (host, spaceId) = await Scenario.LiveSpaceAsync(api, admin);
        var farmer = await api.VerifiedFarmerAsync("Lakshmi");
        var tripId = await Scenario.TripAsync(farmer);

        var spaces = await farmer.GetJsonAsync($"/api/v1/farmers/me/trips/{tripId}/spaces");
        var card = Scenario.Find(spaces, spaceId)!;
        Assert.Null(card["rating"]?.GetValue<double?>());
        Assert.Equal(0, card["ratingCount"]!.GetValue<int>());

        var booking = await farmer.PostAsync($"/api/v1/farmers/me/trips/{tripId}/bookings", new { spaceId, message = "Tomatoes" });
        var bookingId = booking!["id"]!.GetValue<Guid>();
        Assert.Null(booking["host"]?.AsObject());                       // no address or phone before the host accepts

        var requests = await host.GetJsonAsync("/api/v1/hosts/me/bookings?view=requests");
        var request = Scenario.Find(requests, bookingId)!;
        Assert.Equal("Lakshmi", request["farmer"]!["name"]!.GetValue<string>());
        Assert.Null(request["farmer"]!["phone"]?.GetValue<string>());
        Assert.Equal(0, request["farmer"]!["recentNoShows"]!.GetValue<int>());

        // Another host cannot touch it.
        var otherHost = await api.SignInAsync("Host");
        Assert.Equal("not_found", await otherHost.RefusedAsync(HttpMethod.Post, $"/api/v1/hosts/me/bookings/{bookingId}/accept", null, HttpStatusCode.NotFound));

        await host.PostAsync($"/api/v1/hosts/me/bookings/{bookingId}/accept", expected: HttpStatusCode.NoContent);

        var trip = await farmer.GetJsonAsync($"/api/v1/farmers/me/trips/{tripId}");
        Assert.Equal("Accepted", trip["booking"]!["status"]!.GetValue<string>());
        Assert.Equal(host.Phone, trip["booking"]!["host"]!["phone"]!.GetValue<string>());
        var upcoming = await host.GetJsonAsync("/api/v1/hosts/me/bookings?view=upcoming");
        Assert.Equal(farmer.Phone, Scenario.Find(upcoming, bookingId)!["farmer"]!["phone"]!.GetValue<string>());

        // The date is fixed while booked; the slot is taken for everyone else.
        Assert.Equal("trip_cancel_booking_first", await farmer.RefusedAsync(HttpMethod.Put, $"/api/v1/farmers/me/trips/{tripId}", new
        {
            date = Scenario.Tomorrow.AddDays(1).ToString("yyyy-MM-dd"), vehicle = "Auto", produce = new[] { new { cropCode = "custom:Tomato" } },
        }, HttpStatusCode.Conflict));
        var second = await api.VerifiedFarmerAsync();
        var secondTrip = await Scenario.TripAsync(second);
        Assert.Null(Scenario.Find(await second.GetJsonAsync($"/api/v1/farmers/me/trips/{secondTrip}/spaces"), spaceId));
        Assert.Equal("space_taken", await second.RefusedAsync(HttpMethod.Post, $"/api/v1/farmers/me/trips/{secondTrip}/bookings",
            new { spaceId }, HttpStatusCode.Conflict));
    }

    [Fact]
    public async Task A_problem_report_reaches_the_admin_and_the_answer_reaches_the_reporter()
    {
        var admin = await api.AdminAsync();
        var (host, spaceId) = await Scenario.LiveSpaceAsync(api, admin);
        var farmer = await api.VerifiedFarmerAsync();
        var (_, bookingId) = await Scenario.ConfirmedStallAsync(farmer, host, spaceId);

        var report = await host.PostAsync("/api/v1/reports", new
        {
            category = "Behaviour", message = "The farmer blocked the gate for an hour", bookingId,
        });
        var reportId = report!["id"]!.GetValue<Guid>();
        Assert.NotNull(Scenario.Find(await admin.GetJsonAsync("/api/v1/ops/reports"), reportId));

        await admin.PostAsync($"/api/v1/ops/reports/{reportId}/resolve", new { resolution = "We spoke to the farmer" }, HttpStatusCode.NoContent);
        var mine = Scenario.Find(await host.GetJsonAsync("/api/v1/reports/mine"), reportId)!;
        Assert.Equal("Resolved", mine["status"]!.GetValue<string>());
        Assert.Equal("We spoke to the farmer", mine["resolution"]!.GetValue<string>());
    }
}
