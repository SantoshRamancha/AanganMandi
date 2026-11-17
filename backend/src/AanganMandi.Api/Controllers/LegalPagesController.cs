using AanganMandi.Infrastructure.Sharing;
using Microsoft.AspNetCore.Mvc;

namespace AanganMandi.Api.Controllers;

/// <summary>
/// Public terms of use and privacy policy: /legal/terms and /legal/privacy (English, with a Telugu or Hindi summary
/// on top; ?lang= or the browser's language). The app links to them from the consent screen and My profile, and the
/// Play Store needs the privacy policy link. Contact: Support:Email.
/// </summary>
[ApiController]
[ApiExplorerSettings(IgnoreApi = true)]
[Route("legal")]
public class LegalPagesController(IConfiguration config) : ControllerBase
{
    [HttpGet("terms")]
    public IActionResult Terms([FromQuery] string? lang) => Html(LegalPages.Terms(Lang(lang), config["Support:Email"]));

    [HttpGet("privacy")]
    public IActionResult Privacy([FromQuery] string? lang) => Html(LegalPages.Privacy(Lang(lang), config["Support:Email"]));

    private string Lang(string? lang) => StallPage.PickLanguage(lang, Request.Headers.AcceptLanguage.ToString());

    private ContentResult Html(string html)
    {
        Response.Headers["Content-Security-Policy"] = "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'";
        Response.Headers["X-Content-Type-Options"] = "nosniff";
        Response.Headers.CacheControl = "public, max-age=3600";
        return Content(html, "text/html; charset=utf-8");
    }
}
