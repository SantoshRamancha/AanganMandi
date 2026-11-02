using AanganMandi.Api.Auth;
using AanganMandi.Application.Identity;
using AanganMandi.Domain.Identity;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

[ApiController]
[Route("api/v1/auth")]
public class AuthController(IOtpService otp, AppDbContext db, TokenService tokens) : ControllerBase
{
    public record OtpRequest(string Phone);
    public record OtpVerify(string Phone, string Code);

    /// <summary>DevCode is the OTP itself, only while testing without SMS (Otp:ShowDevCode); otherwise null.</summary>
    public record OtpRequested(string? DevCode);

    [HttpPost("otp/request")]
    public async Task<ActionResult<OtpRequested>> RequestOtp(OtpRequest req, CancellationToken ct) =>
        Accepted(new OtpRequested(await otp.SendAsync(req.Phone, ct)));

    [HttpPost("otp/verify")]
    public async Task<ActionResult<TokenResponse>> Verify(OtpVerify req, CancellationToken ct)
    {
        if (!await otp.VerifyAsync(req.Phone, req.Code, ct))
            return Problem(statusCode: 401, title: "Invalid or expired OTP");

        var user = await db.Users.Include(u => u.Roles).SingleOrDefaultAsync(u => u.Phone == req.Phone, ct);
        if (user is null)
        {
            var lang = Request.Headers.AcceptLanguage.ToString();
            user = new User { Phone = req.Phone, PreferredLanguage = lang is "te" or "hi" ? lang : "en" };
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
            : Problem(statusCode: 401, title: "Session expired. Please log in again.");
}
