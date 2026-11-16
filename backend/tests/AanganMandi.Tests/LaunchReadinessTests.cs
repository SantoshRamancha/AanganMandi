using AanganMandi.Application.Identity;
using AanganMandi.Infrastructure;
using AanganMandi.Infrastructure.Accounts;
using AanganMandi.Infrastructure.Logging;
using AanganMandi.Infrastructure.Sharing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Serilog.Events;
using Serilog.Parsing;

namespace AanganMandi.Tests;

/// <summary>OTP limits, phone numbers, CORS, error alerts and account deletion.</summary>
public class LaunchReadinessTests
{
    [Theory]
    [InlineData("+91 90000 12345", "+919000012345")]
    [InlineData("919000012345", "+919000012345")]
    [InlineData("9000012345", "+919000012345")]
    [InlineData("+919000000001", "+919000000001")]
    public void Indian_mobile_numbers_are_tidied(string input, string expected) =>
        Assert.Equal(expected, PhoneNumbers.Normalize(input).Phone);

    [Theory]
    [InlineData("12345")]
    [InlineData("5848012345")]   // mobiles start with 6–9
    [InlineData("+1 415 555 0100")]
    [InlineData("")]
    public void Other_numbers_are_refused(string input) => Assert.NotNull(PhoneNumbers.Normalize(input).Error);

    [Fact]
    public void Otp_requests_wait_30_seconds_and_stop_at_5_an_hour()
    {
        var now = new DateTime(2026, 11, 16, 10, 0, 0, DateTimeKind.Utc);
        var throttle = new OtpThrottle(() => now);
        Assert.Null(throttle.TrySend("+919000012345"));
        Assert.InRange(throttle.TrySend("+919000012345")!.Value.TotalSeconds, 29, 30);   // too soon
        Assert.Null(throttle.TrySend("+919000000001"));                                   // other numbers unaffected

        for (var i = 1; i < OtpThrottle.MaxPerHour; i++)
        {
            now = now.AddSeconds(31);
            Assert.Null(throttle.TrySend("+919000012345"));
        }
        now = now.AddSeconds(31);
        var wait = throttle.TrySend("+919000012345");
        Assert.NotNull(wait);
        Assert.True(wait!.Value > TimeSpan.FromMinutes(50));   // the hour since the first one
        now = now.AddHours(1);
        Assert.Null(throttle.TrySend("+919000012345"));
    }

    [Fact]
    public async Task An_otp_allows_a_typo_but_only_five_tries_and_works_once()
    {
        var now = new DateTime(2026, 11, 16, 10, 0, 0, DateTimeKind.Utc);
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["TestLogins:Otp"] = "123456", ["TestLogins:Phones:0"] = "+919000000001",
        }).Build();
        var otp = new DevOtpService(NullLogger<DevOtpService>.Instance, config, () => now);

        await otp.SendAsync("+919000000001");
        Assert.False(await otp.VerifyAsync("+919000000001", "123465"));   // typo
        Assert.True(await otp.VerifyAsync("+919000000001", "123456"));
        Assert.False(await otp.VerifyAsync("+919000000001", "123456"));   // used up

        await otp.SendAsync("+919000000001");
        for (var i = 0; i < DevOtpService.MaxAttempts; i++) Assert.False(await otp.VerifyAsync("+919000000001", "000000"));
        Assert.False(await otp.VerifyAsync("+919000000001", "123456"));   // locked after 5 wrong tries

        await otp.SendAsync("+919000000001");
        now = now.Add(DevOtpService.Lifetime);
        Assert.False(await otp.VerifyAsync("+919000000001", "123456"));   // expired
    }

    [Theory]
    [InlineData("https://app.aanganmandi.in", false, true)]
    [InlineData("https://app.aanganmandi.in:443", false, true)]
    [InlineData("http://app.aanganmandi.in", false, false)]       // scheme must match
    [InlineData("https://evil.example", false, false)]
    [InlineData("http://localhost:5090", false, false)]           // localhost only in Development
    [InlineData("http://localhost:5090", true, true)]
    [InlineData("not a url", true, false)]
    public void Cors_allows_only_the_configured_web_app(string origin, bool development, bool allowed) =>
        Assert.Equal(allowed, CorsOrigins.IsAllowed(origin, ["https://app.aanganmandi.in/"], development));

    private static LogEvent Event(LogEventLevel level, string message, string source, Exception? ex = null) =>
        new(DateTimeOffset.Parse("2026-11-16T05:00:00Z"), level, ex, new MessageTemplateParser().Parse(message),
            [new LogEventProperty("SourceContext", new ScalarValue(source))]);

    [Fact]
    public async Task Only_errors_reach_the_alert_queue_and_never_the_alerts_own_failures()
    {
        var sink = new ErrorAlertSink();
        sink.Emit(Event(LogEventLevel.Warning, "slow", "X"));
        sink.Emit(Event(LogEventLevel.Error, "Could not send the error alert email", typeof(ErrorAlertService).FullName!));
        sink.Emit(Event(LogEventLevel.Error, "boom", "AanganMandi.Api.Controllers.HostSpacesController"));
        sink.Emit(Event(LogEventLevel.Fatal, "down", "Program"));

        var got = new List<string>();
        while (sink.Reader.TryRead(out var e)) got.Add(e.RenderMessage());
        Assert.Equal(["boom", "down"], got);
        await Task.CompletedTask;
    }

    [Fact]
    public void The_alert_email_lists_each_error_in_india_time_and_encodes_it()
    {
        var (subject, html) = ErrorAlertService.Compose(
            [Event(LogEventLevel.Error, "Upload failed for <script>", "AanganMandi.X", new InvalidOperationException("bucket down"))],
            moreNotListed: 3, environment: "Production");
        Assert.Equal("[Aangan Mandi Production] 4 errors in the API", subject);
        Assert.Contains("16 Nov 10:30:00", html);          // 05:00 UTC = 10:30 India
        Assert.Contains("InvalidOperationException: bucket down", html);
        Assert.Contains("&lt;script&gt;", html);
        Assert.DoesNotContain("<script>", html);
        Assert.Contains("3 more", html);
    }

    [Fact]
    public void Deleted_accounts_get_a_phone_that_is_never_a_real_number()
    {
        var a = AccountDeletion.AnonymousPhone();
        Assert.Equal(15, a.Length);
        Assert.StartsWith("x", a);
        Assert.Null(PhoneNumbers.Normalize(a).Phone);   // nobody can log in with it
        Assert.NotEqual(a, AccountDeletion.AnonymousPhone());
    }

    [Fact]
    public void The_deletion_page_explains_the_steps_and_the_contact_when_set()
    {
        var html = AccountDeletionPage.Render("en", "support@aanganmandi.in");
        Assert.Contains("Delete my account", html);
        Assert.Contains("What is deleted", html);
        Assert.Contains("support@aanganmandi.in", html);
        Assert.DoesNotContain("Can't open the app", AccountDeletionPage.Render("hi", null));
        Assert.Contains("lang=\"te\"", AccountDeletionPage.Render("te", null));
    }
}
