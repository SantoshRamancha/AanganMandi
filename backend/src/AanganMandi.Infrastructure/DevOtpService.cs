using System.Collections.Concurrent;
using System.Security.Cryptography;
using AanganMandi.Application.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace AanganMandi.Infrastructure;

/// <summary>
/// Development only: writes the OTP to the API log instead of sending an SMS.
/// Phones listed under TestLogins:Phones always get the fixed TestLogins:Otp, so QA can log in without the console.
/// With Otp:ShowDevCode on, the code is also returned so the app can show it on screen.
/// </summary>
public class DevOtpService(ILogger<DevOtpService> logger, IConfiguration config) : IOtpService
{
    private static readonly ConcurrentDictionary<string, (string Code, DateTime Expires)> Codes = new();

    public Task<string?> SendAsync(string phone, CancellationToken ct = default)
    {
        var testPhones = config.GetSection("TestLogins:Phones").GetChildren().Select(c => c.Value);
        var testOtp = config["TestLogins:Otp"];
        var code = testOtp is not null && testPhones.Contains(phone)
            ? testOtp
            : RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
        Codes[phone] = (code, DateTime.UtcNow.AddMinutes(5));
        logger.LogInformation("DEV OTP for {Phone}: {Code}", phone, code);
        var show = bool.TryParse(config["Otp:ShowDevCode"], out var on) && on;
        return Task.FromResult(show ? code : null);
    }

    public Task<bool> VerifyAsync(string phone, string code, CancellationToken ct = default) =>
        Task.FromResult(Codes.TryRemove(phone, out var c) && c.Code == code && c.Expires > DateTime.UtcNow);
}
