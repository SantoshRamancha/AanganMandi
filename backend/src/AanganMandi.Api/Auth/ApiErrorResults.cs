using AanganMandi.Domain.Common;
using AanganMandi.Infrastructure.Errors;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Mvc.Infrastructure;

namespace AanganMandi.Api.Auth;

/// <summary>
/// Refusals as problem+json in the user's language: <c>title</c> is the message (from <see cref="ErrorText"/>, in the
/// request's Accept-Language), plus <c>code</c> (stable, e.g. "otp_wait") and <c>args</c> (e.g. { "seconds": 30 }).
/// Older apps that only show the title keep working.
/// </summary>
public static class ApiErrorResults
{
    public static ObjectResult Fail(this ControllerBase c, int status, ApiError error, string? detail = null) =>
        Problem(c.HttpContext, status, error, detail);

    /// <summary><c>this.Fail(409, "trip_locked")</c> or <c>this.Fail(400, "space_max_photos", ("max", 8))</c>.</summary>
    public static ObjectResult Fail(this ControllerBase c, int status, string code, params (string Key, object? Value)[] args) =>
        c.Fail(status, ApiError.Of(code, args));

    public static ObjectResult Problem(HttpContext http, int status, ApiError error, string? detail = null)
    {
        var lang = ErrorText.LanguageOf(http.Request.Headers.AcceptLanguage.ToString());
        var factory = http.RequestServices.GetRequiredService<ProblemDetailsFactory>();
        var pd = factory.CreateProblemDetails(http, statusCode: status, title: ErrorText.Render(error, lang), detail: detail);
        pd.Extensions["code"] = error.Code;
        if (error.Args.Count > 0) pd.Extensions["args"] = error.Args;
        return new ObjectResult(pd) { StatusCode = status, ContentTypes = { "application/problem+json" } };
    }
}

/// <summary>Turns an <see cref="ApiException"/> from a service into the refusal the user sees.</summary>
public sealed class ApiExceptionFilter : IExceptionFilter
{
    public void OnException(ExceptionContext context)
    {
        if (context.Exception is not ApiException e) return;
        context.Result = ApiErrorResults.Problem(context.HttpContext, e.Status, e.Error,
            e.Error.Code == "verification_incomplete" ? e.Error.Args.GetValueOrDefault("missing") as string : null);
        context.ExceptionHandled = true;
    }
}
