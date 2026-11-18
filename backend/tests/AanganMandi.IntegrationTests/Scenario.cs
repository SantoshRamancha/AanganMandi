using System.Net;
using System.Text.Json.Nodes;
using AanganMandi.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.IntegrationTests;

/// <summary>Steps several tests share: a live space, a trip, a confirmed stall that already happened.</summary>
public static class Scenario
{
    public static DateOnly Tomorrow => TripService.Today.AddDays(1);

    /// <summary>A host with an approved (live) space open every day 16:00–20:00, free, up to a mini truck.</summary>
    public static async Task<(TestUser Host, Guid SpaceId)> LiveSpaceAsync(ApiFactory api, TestUser admin, string title = "Green villa courtyard")
    {
        var host = await api.SignInAsync("Host");
        var space = await host.PostAsync("/api/v1/hosts/me/spaces", new
        {
            title, type = "Courtyard", address = "Plot 12, Road 3", locality = "Madhapur",
            latitude = 17.4486, longitude = 78.3908, areaSqFt = 400, maxStallSize = "10x10 ft", maxVehicle = "MiniTruck",
            amenities = new[] { "Water" }, isFree = true, fee = 0, rules = (string?)null,
            availableDays = Enum.GetNames<DayOfWeek>(), openFrom = "16:00:00", openTo = "20:00:00",
        }, HttpStatusCode.Created);
        var id = space!["id"]!.GetValue<Guid>();
        for (var i = 0; i < 3; i++) await host.UploadPhotoAsync($"/api/v1/hosts/me/spaces/{id}/photos", isProof: false);
        await host.UploadPhotoAsync($"/api/v1/hosts/me/spaces/{id}/photos", isProof: true);
        await host.PostAsync($"/api/v1/hosts/me/spaces/{id}/submit", expected: HttpStatusCode.NoContent);
        await admin.PostAsync($"/api/v1/ops/spaces/{id}/decision", new { approve = true }, HttpStatusCode.NoContent);
        return (host, id);
    }

    public static async Task<Guid> TripAsync(TestUser farmer, DateOnly? date = null)
    {
        var trip = await farmer.PostAsync("/api/v1/farmers/me/trips", new
        {
            date = (date ?? Tomorrow).ToString("yyyy-MM-dd"), vehicle = "Auto", preferredArea = (string?)null,
            notes = (string?)null, produce = new[] { new { cropCode = "custom:Tomato", quantityKg = 50, pricePerKg = 30 } },
        }, HttpStatusCode.Created);
        return trip!["id"]!.GetValue<Guid>();
    }

    /// <summary>Farmer requests the space for a new trip tomorrow and the host accepts. Returns (trip, booking).</summary>
    public static async Task<(Guid TripId, Guid BookingId)> ConfirmedStallAsync(TestUser farmer, TestUser host, Guid spaceId)
    {
        var tripId = await TripAsync(farmer);
        var booking = await farmer.PostAsync($"/api/v1/farmers/me/trips/{tripId}/bookings", new { spaceId, message = "Coming with tomatoes" });
        var bookingId = booking!["id"]!.GetValue<Guid>();
        await host.PostAsync($"/api/v1/hosts/me/bookings/{bookingId}/accept", expected: HttpStatusCode.NoContent);
        return (tripId, bookingId);
    }

    /// <summary>
    /// A confirmed stall that took place <paramref name="daysAgo"/> days ago: made for tomorrow through the API, then
    /// moved into the past in the database (the API rightly refuses past dates).
    /// </summary>
    public static async Task<(Guid TripId, Guid BookingId)> PastStallAsync(ApiFactory api, TestUser farmer, TestUser host,
        Guid spaceId, int daysAgo = 1)
    {
        var (tripId, bookingId) = await ConfirmedStallAsync(farmer, host, spaceId);
        var past = TripService.Today.AddDays(-daysAgo);
        await api.DbAsync(async db =>
        {
            (await db.Trips.SingleAsync(t => t.Id == tripId)).Date = past;
            (await db.Bookings.SingleAsync(b => b.Id == bookingId)).Date = past;
        });
        return (tripId, bookingId);
    }

    public static JsonNode? Find(JsonNode list, Guid id) => list.AsArray().FirstOrDefault(x => x!["id"]!.GetValue<Guid>() == id);
}
