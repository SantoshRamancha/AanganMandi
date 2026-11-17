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
/// A code lasts 5 minutes and allows <see cref="MaxAttempts"/> tries, so a typo does not throw it away but guessing
/// is still hopeless (5 tries out of a million codes).
/// </summary>
public class DevOtpService(ILogger<DevOtpService> logger, IConfiguration config, Func<DateTime>? clock = null) : IOtpService
{
    public const int MaxAttempts = 5;
    public static readonly TimeSpan Lifetime = TimeSpan.FromMinutes(5);

    private sealed class Pending(string code, DateTime expires)
    {
        public string Code { get; } = code;
        public DateTime Expires { get; } = expires;
        public int Attempts;
    }

    private readonly ConcurrentDictionary<string, Pending> _codes = new();
    private readonly Func<DateTime> _now = clock ?? (() => DateTime.UtcNow);

    public Task<string?> SendAsync(string phone, CancellationToken ct = default)
    {
        var testPhones = config.GetSection("TestLogins:Phones").GetChildren().Select(c => c.Value);
        var testOtp = config["TestLogins:Otp"];
        var code = testOtp is not null && testPhones.Contains(phone)
            ? testOtp
            : RandomNumberGenerator.GetInt32(0, 1_000_000).ToString("D6");
        _codes[phone] = new Pending(code, _now().Add(Lifetime));
        logger.LogInformation("DEV OTP for {Phone}: {Code}", phone, code);
        var show = bool.TryParse(config["Otp:ShowDevCode"], out var on) && on;
        return Task.FromResult(show ? code : null);
    }

    public Task<bool> VerifyAsync(string phone, string code, CancellationToken ct = default)
    {
        if (!_codes.TryGetValue(phone, out var p)) return Task.FromResult(false);
        if (p.Expires <= _now() || Interlocked.Increment(ref p.Attempts) > MaxAttempts)
        {
            _codes.TryRemove(phone, out _);
            return Task.FromResult(false);
        }
        if (!CryptographicOperations.FixedTimeEquals(
                System.Text.Encoding.ASCII.GetBytes(p.Code), System.Text.Encoding.ASCII.GetBytes(code ?? "")))
            return Task.FromResult(false);
        _codes.TryRemove(phone, out _); // a code works once
        return Task.FromResult(true);
    }
}
