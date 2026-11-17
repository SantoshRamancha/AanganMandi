using AanganMandi.Domain.Common;
using AanganMandi.Infrastructure.Errors;
using Microsoft.AspNetCore.Mvc;

namespace AanganMandi.Api.Auth;

/// <summary>
/// Refusals as problem+json in the user's language: <c>title</c> is the message (from <see cref="ErrorText"/>, in the
/// request's Accept-Language), plus <c>code</c> (stable, e.g. "otp_wait") and <c>args</c> (e.g. { "seconds": 30 }).
/// Older apps that only show the title keep working.
/// </summary>
public static class ApiErrorResults
{
    public static ObjectResult Fail(this ControllerBase c, int status, ApiError error, string? detail = null)
    {
        var lang = ErrorText.LanguageOf(c.Request.Headers.AcceptLanguage.ToString());
        var result = c.Problem(statusCode: status, title: ErrorText.Render(error, lang), detail: detail);
        if (result.Value is ProblemDetails pd)
        {
            pd.Extensions["code"] = error.Code;
            if (error.Args.Count > 0) pd.Extensions["args"] = error.Args;
        }
        return result;
    }

    /// <summary><c>this.Fail(409, "trip_locked")</c> or <c>this.Fail(400, "space_max_photos", ("max", 8))</c>.</summary>
    public static ObjectResult Fail(this ControllerBase c, int status, string code, params (string Key, object? Value)[] args) =>
        c.Fail(status, ApiError.Of(code, args));
}
