using AanganMandi.Domain.Identity;
using AanganMandi.Infrastructure.Persistence;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.EntityFrameworkCore;

namespace AanganMandi.Api.Auth;

/// <summary>
/// Staff (Verifier or Admin) endpoints. Roles are read from the database on every call rather than from the
/// 15-minute token, so a verifier added by an admin gets access on their next login, and a removed one loses it at once.
/// Staff roles are never self-chosen: the app's role screen only offers Farmer, Host and Buyer.
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class StaffOnlyAttribute : Attribute, IFilterFactory
{
    public bool AdminOnly { get; init; }
    public bool IsReusable => false;

    public IFilterMetadata CreateInstance(IServiceProvider services) =>
        new StaffAccessFilter(services.GetRequiredService<AppDbContext>(), AdminOnly);
}

public class StaffAccessFilter(AppDbContext db, bool adminOnly) : IAsyncActionFilter
{
    private const string IsAdminKey = "staff.isAdmin";

    public static bool IsAdmin(HttpContext http) => http.Items[IsAdminKey] is true;

    public async Task OnActionExecutionAsync(ActionExecutingContext ctx, ActionExecutionDelegate next)
    {
        var userId = ctx.HttpContext.User.UserId();
        var roles = await db.UserRoles
            .Where(r => r.UserId == userId && (r.Role == Role.Verifier || r.Role == Role.Admin))
            .Select(r => r.Role).ToListAsync(ctx.HttpContext.RequestAborted);
        var isAdmin = roles.Contains(Role.Admin);
        if (roles.Count == 0 || (adminOnly && !isAdmin))
        {
            ctx.Result = new ObjectResult(new ProblemDetails
            {
                Status = 403,
                Title = roles.Count == 0 ? "You no longer have staff access" : "Only an admin can do this",
            }) { StatusCode = 403 };
            return;
        }
        ctx.HttpContext.Items[IsAdminKey] = isAdmin;
        await next();
    }
}
