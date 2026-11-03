using AanganMandi.Api.Auth;
using AanganMandi.Domain.Identity;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/v1/users/me")]
public class UsersController(AppDbContext db, TokenService tokens) : ControllerBase
{
    public record RoleRequest(Role Role);
    public record LanguageRequest(string Language);
    public record ProfileDto(string? Name, string Phone, string Language, Role[] Roles, DateTime MemberSince);

    /// <summary>The signed-in user's own account details, for the profile screen.</summary>
    [HttpGet]
    public async Task<ProfileDto> Get(CancellationToken ct)
    {
        var user = await db.Users.AsNoTracking().Include(u => u.Roles).SingleAsync(u => u.Id == User.UserId(), ct);
        return new ProfileDto(user.Name, user.Phone, user.PreferredLanguage,
            user.Roles.Select(r => r.Role).Order().ToArray(), user.CreatedAt);
    }

    /// <summary>Adds Farmer, Host or Buyer to the signed-in user and returns new tokens carrying it.</summary>
    [HttpPost("role")]
    public async Task<ActionResult<TokenResponse>> AddRole(RoleRequest req, CancellationToken ct)
    {
        if (req.Role is not (Role.Farmer or Role.Host or Role.Buyer))
            return Problem(statusCode: 400, title: "Only Farmer, Host or Buyer can be chosen in the app");
        var user = await db.Users.Include(u => u.Roles).SingleAsync(u => u.Id == User.UserId(), ct);
        if (user.Roles.All(r => r.Role != req.Role))
        {
            user.Roles.Add(new UserRole { Role = req.Role });
            await db.SaveChangesAsync(ct);
        }
        return await tokens.IssueAsync(user, ct);
    }

    [HttpPut("language")]
    public async Task<IActionResult> SetLanguage(LanguageRequest req, CancellationToken ct)
    {
        if (req.Language is not ("en" or "te" or "hi"))
            return Problem(statusCode: 400, title: "Language must be en, te or hi");
        var user = await db.Users.SingleAsync(u => u.Id == User.UserId(), ct);
        user.PreferredLanguage = req.Language;
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }
}
