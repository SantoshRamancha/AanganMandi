using AanganMandi.Api.Auth;
using AanganMandi.Application.Identity;
using AanganMandi.Domain.Identity;
using AanganMandi.Infrastructure;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// Phone + OTP login. Limits: per phone a 30-second wait between OTPs and 5 per hour (<see cref="OtpThrottle"/>);
/// per IP address the "otp" rate limiter; per code 5 tries (<see cref="DevOtpService"/>).
/// </summary>
[ApiController]
[Route("api/v1/auth")]
public class AuthController(IOtpService otp, OtpThrottle throttle, AppDbContext db, TokenService tokens) : ControllerBase
{
    public record OtpRequest(string Phone);
    public record OtpVerify(string Phone, string Code);

    /// <summary>DevCode is the OTP itself, only while testing without SMS (Otp:ShowDevCode); otherwise null.</summary>
    public record OtpRequested(string? DevCode);

    [HttpPost("otp/request")]
    [EnableRateLimiting("otp")]
    public async Task<ActionResult<OtpRequested>> RequestOtp(OtpRequest req, CancellationToken ct)
    {
        var (phone, error) = PhoneNumbers.Normalize(req.Phone);
        if (phone is null) return this.Fail(400, error!);
        if (throttle.TrySend(phone) is { } wait)
        {
            var seconds = (int)Math.Ceiling(wait.TotalSeconds);
            Response.Headers.RetryAfter = seconds.ToString();
            return seconds <= 60
                ? this.Fail(429, "otp_wait", ("seconds", seconds))
                : this.Fail(429, "otp_too_many", ("minutes", (int)Math.Ceiling(wait.TotalMinutes)));
        }
        return Accepted(new OtpRequested(await otp.SendAsync(phone, ct)));
    }

    [HttpPost("otp/verify")]
    [EnableRateLimiting("otp")]
    public async Task<ActionResult<TokenResponse>> Verify(OtpVerify req, CancellationToken ct)
    {
        var (phone, error) = PhoneNumbers.Normalize(req.Phone);
        if (phone is null) return this.Fail(400, error!);
        if (!await otp.VerifyAsync(phone, req.Code, ct))
            return this.Fail(401, "otp_wrong");

        var user = await db.Users.Include(u => u.Roles).SingleOrDefaultAsync(u => u.Phone == phone, ct);
        if (user is null)
        {
            var lang = Request.Headers.AcceptLanguage.ToString();
            user = new User { Phone = phone, PreferredLanguage = lang is "te" or "hi" ? lang : "en" };
            db.Users.Add(user);
            await db.SaveChangesAsync(ct);
        }
        return await tokens.IssueAsync(user, ct);
    }

    public record RefreshRequest(string RefreshToken);

    [HttpPost("refresh")]
    public async Task<ActionResult<TokenResponse>> Refresh(RefreshRequest req, CancellationToken ct) =>
        await tokens.RefreshAsync(req.RefreshToken, ct) is { } response
            ? response
            : this.Fail(401, "session_expired");
}
