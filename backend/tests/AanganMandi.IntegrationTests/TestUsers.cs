using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Serialization;
using AanganMandi.Domain.Farmers;
using AanganMandi.Infrastructure.Accounts;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.IntegrationTests;

/// <summary>A signed-in user: an HttpClient with their access token, plus who they are.</summary>
public sealed class TestUser(HttpClient http, Guid id, string phone)
{
    public HttpClient Http { get; } = http;
    public Guid Id { get; } = id;
    public string Phone { get; } = phone;

    public static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web)
    {
        Converters = { new JsonStringEnumConverter() },
    };

    public async Task<JsonNode> GetJsonAsync(string url)
    {
        using var res = await Http.GetAsync(url);
        return await ReadAsync(res, HttpStatusCode.OK);
    }

    /// <summary>Posts (or puts) <paramref name="body"/> as JSON and checks the status; returns the JSON reply, if any.</summary>
    public async Task<JsonNode?> SendAsync(HttpMethod method, string url, object? body, HttpStatusCode expected)
    {
        using var req = new HttpRequestMessage(method, url) { Content = body is null ? null : JsonContent.Create(body, options: Json) };
        using var res = await Http.SendAsync(req);
        return res.StatusCode == HttpStatusCode.NoContent && expected == HttpStatusCode.NoContent
            ? null
            : await ReadAsync(res, expected);
    }

    public Task<JsonNode?> PostAsync(string url, object? body = null, HttpStatusCode expected = HttpStatusCode.OK) =>
        SendAsync(HttpMethod.Post, url, body ?? new { }, expected);

    public Task<JsonNode?> PutAsync(string url, object body, HttpStatusCode expected = HttpStatusCode.NoContent) =>
        SendAsync(HttpMethod.Put, url, body, expected);

    /// <summary>Expects a refusal: returns the problem's code (e.g. "trip_locked").</summary>
    public async Task<string?> RefusedAsync(HttpMethod method, string url, object? body, HttpStatusCode expected)
    {
        var problem = await SendAsync(method, url, body ?? new { }, expected);
        return problem?["code"]?.GetValue<string>();
    }

    public async Task UploadPhotoAsync(string url, bool? isProof = null)
    {
        using var form = new MultipartFormDataContent();
        var file = new ByteArrayContent(TinyJpeg);
        file.Headers.ContentType = new MediaTypeHeaderValue("image/jpeg");
        form.Add(file, "file", "photo.jpg");
        if (isProof is { } proof) form.Add(new StringContent(proof ? "true" : "false"), "isProof");
        using var res = await Http.PostAsync(url, form);
        Assert.True(res.StatusCode == HttpStatusCode.NoContent, $"{url}: {(int)res.StatusCode} {await res.Content.ReadAsStringAsync()}");
    }

    private static async Task<JsonNode> ReadAsync(HttpResponseMessage res, HttpStatusCode expected)
    {
        var text = await res.Content.ReadAsStringAsync();
        Assert.True(res.StatusCode == expected, $"{res.RequestMessage?.Method} {res.RequestMessage?.RequestUri}: expected {(int)expected}, got {(int)res.StatusCode} {text}");
        return JsonNode.Parse(text.Length == 0 ? "{}" : text)!;
    }

    /// <summary>The start of a JPEG: enough for the API's format check (it reads the first bytes, not the picture).</summary>
    private static readonly byte[] TinyJpeg = [0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10, (byte)'J', (byte)'F', (byte)'I', (byte)'F', 0, 1, 1, 0, 0, 1, 0xFF, 0xD9];
}

/// <summary>Signs in test users through the real OTP flow (the dev code is returned while Otp:ShowDevCode is on).</summary>
public static class TestUsers
{
    private static int _next;

    /// <summary>Unique test numbers in the 90000 range (never a real person's).</summary>
    public static string NewPhone() => $"90000{Interlocked.Increment(ref _next):D5}";

    public static async Task<TestUser> SignInAsync(this ApiFactory api, string? role = null, string? phone = null,
        string language = "en")
    {
        phone ??= NewPhone();
        var http = api.CreateClient();
        http.DefaultRequestHeaders.AcceptLanguage.ParseAdd(language);
        var otp = await http.PostAsJsonAsync("/api/v1/auth/otp/request", new { phone });
        Assert.Equal(HttpStatusCode.Accepted, otp.StatusCode);
        var code = (await otp.Content.ReadFromJsonAsync<JsonNode>())!["devCode"]!.GetValue<string>();
        var login = await http.PostAsJsonAsync("/api/v1/auth/otp/verify", new { phone, code });
        Assert.Equal(HttpStatusCode.OK, login.StatusCode);
        var tokens = (await login.Content.ReadFromJsonAsync<JsonNode>())!;
        Authorize(http, tokens);

        if (role is "Farmer" or "Host" or "Buyer")
        {
            var withRole = await http.PostAsJsonAsync("/api/v1/users/me/role", new { role });
            Assert.Equal(HttpStatusCode.OK, withRole.StatusCode);
            Authorize(http, (await withRole.Content.ReadFromJsonAsync<JsonNode>())!);
        }
        var id = await api.QueryAsync(db => db.Users.Where(u => u.Phone == "+91" + phone).Select(u => u.Id).SingleAsync());
        return new TestUser(http, id, "+91" + phone);
    }

    /// <summary>An admin (made the way the create-admin command does), signed in.</summary>
    public static async Task<TestUser> AdminAsync(this ApiFactory api)
    {
        var phone = NewPhone();
        await api.DbAsync(db => AdminSetup.MakeAdminAsync(db, phone, "Test Admin", default));
        return await api.SignInAsync(phone: phone);
    }

    /// <summary>A farmer already verified (Level 2), for tests about selling rather than verification.</summary>
    public static async Task<TestUser> VerifiedFarmerAsync(this ApiFactory api, string name = "Test Farmer")
    {
        var farmer = await api.SignInAsync("Farmer");
        await api.DbAsync(async db =>
        {
            (await db.Users.SingleAsync(u => u.Id == farmer.Id)).Name = name;
            db.FarmerProfiles.Add(new FarmerProfile
            {
                UserId = farmer.Id, Village = "Nelakondapalli", District = "Medak", Status = VerificationStatus.Verified,
                Level = 2, ProduceSource = ProduceSource.OwnFarm, ReviewedAt = DateTime.UtcNow,
            });
        });
        return farmer;
    }

    private static void Authorize(HttpClient http, JsonNode tokens) =>
        http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", tokens["accessToken"]!.GetValue<string>());
}
