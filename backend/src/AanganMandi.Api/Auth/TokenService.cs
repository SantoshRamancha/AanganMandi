using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using AanganMandi.Domain.Identity;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace AanganMandi.Api.Auth;

public record TokenResponse(string AccessToken, string RefreshToken, string[] Roles, string PreferredLanguage, string? Name);

/// <summary>15-minute JWT access tokens plus 30-day refresh tokens, rotated on every refresh.</summary>
public class TokenService(IConfiguration config, AppDbContext db)
{
    private static readonly TimeSpan RefreshLifetime = TimeSpan.FromDays(30);

    public async Task<TokenResponse> IssueAsync(User user, CancellationToken ct = default)
    {
        var roles = user.Roles.Select(r => r.Role.ToString()).ToArray();
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(config["Jwt:Key"]!));
        var token = new JwtSecurityToken(
            issuer: config["Jwt:Issuer"],
            audience: config["Jwt:Issuer"],
            claims: [
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim("phone", user.Phone),
                .. roles.Select(r => new Claim(ClaimTypes.Role, r)),
            ],
            expires: DateTime.UtcNow.AddMinutes(15),
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));

        var refresh = Convert.ToBase64String(RandomNumberGenerator.GetBytes(48));
        db.RefreshTokens.Add(new RefreshToken { UserId = user.Id, TokenHash = Hash(refresh), ExpiresAt = DateTime.UtcNow + RefreshLifetime });
        await db.SaveChangesAsync(ct);
        return new TokenResponse(new JwtSecurityTokenHandler().WriteToken(token), refresh, roles, user.PreferredLanguage, user.Name);
    }

    /// <summary>Revokes the presented refresh token and issues a new pair, or returns null if it is invalid.</summary>
    public async Task<TokenResponse?> RefreshAsync(string refreshToken, CancellationToken ct = default)
    {
        var hash = Hash(refreshToken);
        var stored = await db.RefreshTokens.SingleOrDefaultAsync(t => t.TokenHash == hash, ct);
        if (stored is null || stored.RevokedAt is not null || stored.ExpiresAt < DateTime.UtcNow) return null;
        stored.RevokedAt = DateTime.UtcNow;
        var user = await db.Users.Include(u => u.Roles).SingleOrDefaultAsync(u => u.Id == stored.UserId, ct);
        return user is null ? null : await IssueAsync(user, ct);
    }

    private static string Hash(string token) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));
}

public static class ClaimsPrincipalExtensions
{
    /// <summary>The signed-in user's id (JWT "sub", mapped to NameIdentifier by the JWT handler).</summary>
    public static Guid UserId(this ClaimsPrincipal user) =>
        Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier) ?? user.FindFirstValue(JwtRegisteredClaimNames.Sub)!);
}
