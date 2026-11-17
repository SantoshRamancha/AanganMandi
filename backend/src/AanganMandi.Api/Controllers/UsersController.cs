using AanganMandi.Api.Auth;
using AanganMandi.Application.Identity;
using AanganMandi.Domain.Identity;
using AanganMandi.Infrastructure.Accounts;
using AanganMandi.Infrastructure.Sharing;
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
    /// <summary>TermsAccepted: the current terms and privacy policy (TermsVersion) are accepted.</summary>
    public record ProfileDto(string? Name, string Phone, string? Email, string Language, Role[] Roles, DateTime MemberSince,
        bool TermsAccepted, string TermsVersion);
    public record ConsentRequest(string Version);
    public record EmailRequest(string? Email);

    /// <summary>
    /// Deletes the signed-in user's account and personal data (<see cref="AccountDeletion"/>). The app logs out
    /// afterwards. Staff accounts are refused: an admin removes them, so their waiting farmers are reassigned.
    /// </summary>
    [HttpDelete]
    public async Task<IActionResult> DeleteAccount([FromServices] AccountDeletion deletion, CancellationToken ct) =>
        await deletion.DeleteAsync(User.UserId(), ct) switch
        {
            AccountDeletionResult.Deleted => NoContent(),
            AccountDeletionResult.StaffAccount => this.Fail(409, "staff_account_delete"),
            _ => NotFound(),
        };

    /// <summary>The signed-in user's own account details, for the profile screen.</summary>
    [HttpGet]
    public async Task<ProfileDto> Get(CancellationToken ct)
    {
        var user = await db.Users.AsNoTracking().Include(u => u.Roles).SingleAsync(u => u.Id == User.UserId(), ct);
        return new ProfileDto(user.Name, user.Phone, user.Email, user.PreferredLanguage,
            user.Roles.Select(r => r.Role).Order().ToArray(), user.CreatedAt,
            user.TermsVersion == LegalPages.Version, LegalPages.Version);
    }

    /// <summary>
    /// Records that the user accepted the terms and privacy policy of <paramref name="req"/>.Version, which must be the
    /// current one (an app showing older texts is refused, so nobody accepts words they were not shown).
    /// </summary>
    [HttpPost("consent")]
    public async Task<IActionResult> Consent(ConsentRequest req, CancellationToken ct)
    {
        if (req.Version != LegalPages.Version) return this.Fail(409, "consent_version_outdated");
        var user = await db.Users.SingleAsync(u => u.Id == User.UserId(), ct);
        user.TermsVersion = LegalPages.Version;
        user.TermsAcceptedAt = user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    /// <summary>Sets the email address for updates (verification, spaces, bookings); empty removes it.</summary>
    [HttpPut("email")]
    public async Task<IActionResult> SetEmail(EmailRequest req, CancellationToken ct)
    {
        var (email, error) = EmailAddresses.Normalize(req.Email);
        if (error is not null) return this.Fail(400, error);
        var user = await db.Users.SingleAsync(u => u.Id == User.UserId(), ct);
        user.Email = email;
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    /// <summary>Adds Farmer, Host or Buyer to the signed-in user and returns new tokens carrying it.</summary>
    [HttpPost("role")]
    public async Task<ActionResult<TokenResponse>> AddRole(RoleRequest req, CancellationToken ct)
    {
        if (req.Role is not (Role.Farmer or Role.Host or Role.Buyer))
            return this.Fail(400, "role_not_allowed");
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
            return this.Fail(400, "language_invalid");
        var user = await db.Users.SingleAsync(u => u.Id == User.UserId(), ct);
        user.PreferredLanguage = req.Language;
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return NoContent();
    }
}
