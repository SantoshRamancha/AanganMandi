using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using AanganMandi.Domain.Common;
using AanganMandi.Infrastructure.Errors;

namespace AanganMandi.IntegrationTests;

/// <summary>Signing in, who may call what, and refusals in the user's language.</summary>
[Collection(ApiCollection.Name)]
public class AuthAndErrorTests(ApiFactory api)
{
    [Fact]
    public async Task Otp_sign_in_creates_the_account_and_the_token_opens_the_profile()
    {
        var user = await api.SignInAsync("Buyer");
        var me = await user.GetJsonAsync("/api/v1/users/me");
        Assert.Equal(user.Phone, me["phone"]!.GetValue<string>());
        Assert.Contains("Buyer", me["roles"]!.AsArray().Select(r => r!.GetValue<string>()));
    }

    [Fact]
    public async Task A_wrong_otp_is_refused_in_the_language_of_the_app()
    {
        var http = api.CreateClient();
        http.DefaultRequestHeaders.AcceptLanguage.ParseAdd("te");
        var phone = TestUsers.NewPhone();
        var sent = await (await http.PostAsJsonAsync("/api/v1/auth/otp/request", new { phone })).Content.ReadFromJsonAsync<JsonNode>();
        var right = sent!["devCode"]!.GetValue<string>();
        var wrong = new string(right.Select(c => c == '9' ? '0' : (char)(c + 1)).ToArray());

        var res = await http.PostAsJsonAsync("/api/v1/auth/otp/verify", new { phone, code = wrong });
        var problem = (await res.Content.ReadFromJsonAsync<JsonNode>())!;

        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
        Assert.Equal("otp_wrong", problem["code"]!.GetValue<string>());
        Assert.Equal(ErrorText.Render(new ApiError("otp_wrong"), "te"), problem["title"]!.GetValue<string>());
    }

    [Fact]
    public async Task Without_a_token_nothing_private_opens()
    {
        var res = await api.CreateClient().GetAsync("/api/v1/users/me");
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task Each_role_only_reaches_its_own_screens()
    {
        var buyer = await api.SignInAsync("Buyer");
        Assert.Equal(HttpStatusCode.Forbidden, (await buyer.Http.GetAsync("/api/v1/farmers/me/trips")).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await buyer.Http.GetAsync("/api/v1/hosts/me/spaces")).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await buyer.Http.GetAsync("/api/v1/ops/reports")).StatusCode);
    }

    [Fact]
    public async Task Missing_things_are_refused_with_a_code_and_a_translated_message()
    {
        var farmer = await api.SignInAsync("Farmer", language: "hi");
        var problem = await farmer.SendAsync(HttpMethod.Get, $"/api/v1/farmers/me/trips/{Guid.NewGuid()}", null, HttpStatusCode.NotFound);
        Assert.Equal("not_found", problem!["code"]!.GetValue<string>());
        Assert.Equal(ErrorText.Render(new ApiError("not_found"), "hi"), problem["title"]!.GetValue<string>());
    }

    [Fact]
    public async Task Refusals_from_the_services_keep_their_values()
    {
        var farmer = await api.VerifiedFarmerAsync();
        var problem = await farmer.SendAsync(HttpMethod.Post, "/api/v1/farmers/me/trips", new
        {
            date = Scenario.Tomorrow.ToString("yyyy-MM-dd"), vehicle = "Auto", notes = new string('x', 201),
            produce = new[] { new { cropCode = "custom:Tomato" } },
        }, HttpStatusCode.BadRequest);
        Assert.Equal("notes_too_long", problem!["code"]!.GetValue<string>());
        Assert.Equal(200, problem["args"]!["max"]!.GetValue<int>());
    }
}
