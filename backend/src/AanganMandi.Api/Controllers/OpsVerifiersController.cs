using AanganMandi.Api.Auth;
using AanganMandi.Application.Identity;
using AanganMandi.Application.Notifications;
using AanganMandi.Domain.Farmers;
using AanganMandi.Domain.Identity;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// Admins add and remove verifiers. This is the only way to get the Verifier role; admins themselves
/// are created on the server (dev seed), never through the app.
/// </summary>
[ApiController]
[Authorize]
[StaffOnly(AdminOnly = true)]
[Route("api/v1/ops/verifiers")]
public class OpsVerifiersController(AppDbContext db, INotifier notifier) : ControllerBase
{
    public record VerifierRow(Guid UserId, string? Name, string Phone, DateTime AddedAt, int Waiting, int Reviewed);
    /// <summary>Email is optional; when given, the new verifier gets a welcome email and one for each farmer assigned.</summary>
    public record AddRequest(string Name, string Phone, string? Email = null);
    /// <summary>Assigned: waiting farmers who got a verifier. Unassigned: those left with nobody.</summary>
    public record Result(int Assigned, int Unassigned);

    [HttpGet]
    public Task<List<VerifierRow>> List(CancellationToken ct) =>
        (from r in db.UserRoles
         join u in db.Users on r.UserId equals u.Id
         where r.Role == Role.Verifier
         orderby r.CreatedAt
         select new VerifierRow(u.Id, u.Name, u.Phone, r.CreatedAt,
             db.FarmerProfiles.Count(f => f.AssignedVerifierId == u.Id && f.Status == VerificationStatus.Pending),
             db.FarmerProfiles.Count(f => f.ReviewedBy == u.Id))).ToListAsync(ct);

    [HttpPost]
    public async Task<ActionResult<Result>> Add(AddRequest req, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(req.Name)) return Problem(statusCode: 400, title: "Enter the verifier's name");
        var digits = new string(req.Phone.Where(char.IsDigit).ToArray());
        if (digits.Length == 12 && digits.StartsWith("91")) digits = digits[2..];
        if (digits.Length != 10) return Problem(statusCode: 400, title: "Enter a 10-digit mobile number");
        var phone = "+91" + digits;
        var (email, emailError) = EmailAddresses.Normalize(req.Email);
        if (emailError is not null) return Problem(statusCode: 400, title: emailError);

        // An existing app user (say, a host) keeps their account and gains the Verifier role.
        var user = await db.Users.Include(u => u.Roles).SingleOrDefaultAsync(u => u.Phone == phone, ct);
        if (user?.Roles.Any(r => r.Role == Role.Verifier) == true)
            return Problem(statusCode: 409, title: $"{phone} is already a verifier");
        if (user is null)
        {
            user = new User { Phone = phone, Name = req.Name.Trim() };
            db.Users.Add(user);
        }
        user.Name ??= req.Name.Trim();
        user.Email ??= email;
        user.Roles.Add(new UserRole { Role = Role.Verifier });
        await db.SaveChangesAsync(ct);

        // Farmers who submitted while nobody could take them get picked up now.
        var assigned = await VerifierAssignment.RedistributeAsync(db, fromVerifierId: null, ct);
        await db.SaveChangesAsync(ct);
        await notifier.VerifierAddedAsync(user.Id, User.UserId(), ct);
        return Ok(new Result(assigned, 0));
    }

    [HttpDelete("{userId:guid}")]
    public async Task<ActionResult<Result>> Remove(Guid userId, CancellationToken ct)
    {
        var roles = await db.UserRoles.Where(r => r.UserId == userId && r.Role == Role.Verifier).ToListAsync(ct);
        if (roles.Count == 0) return NotFound();
        var waiting = await db.FarmerProfiles.CountAsync(f => f.AssignedVerifierId == userId && f.Status == VerificationStatus.Pending, ct);
        db.UserRoles.RemoveRange(roles);
        await db.SaveChangesAsync(ct);
        // The removed verifier is no longer a candidate, so their queue spreads over everyone else.
        var moved = await VerifierAssignment.RedistributeAsync(db, userId, ct);
        await db.SaveChangesAsync(ct);
        return Ok(new Result(moved, waiting - moved));
    }
}
