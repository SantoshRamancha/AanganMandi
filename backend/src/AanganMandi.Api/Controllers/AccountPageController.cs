using AanganMandi.Infrastructure.Sharing;
using Microsoft.AspNetCore.Mvc;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// Public "how to delete your account" page, for the Play Store's account-deletion link: /account/delete.
/// The contact address for people who cannot open the app comes from <c>Support:Email</c>.
/// </summary>
[ApiController]
[ApiExplorerSettings(IgnoreApi = true)]
[Route("account")]
public class AccountPageController(IConfiguration config) : ControllerBase
{
    [HttpGet("delete")]
    public IActionResult DeleteInfo([FromQuery] string? lang)
    {
        var language = StallPage.PickLanguage(lang, Request.Headers.AcceptLanguage.ToString());
        Response.Headers["Content-Security-Policy"] = "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'";
        Response.Headers["X-Content-Type-Options"] = "nosniff";
        Response.Headers.CacheControl = "public, max-age=3600";
        return Content(AccountDeletionPage.Render(language, config["Support:Email"]), "text/html; charset=utf-8");
    }
}
