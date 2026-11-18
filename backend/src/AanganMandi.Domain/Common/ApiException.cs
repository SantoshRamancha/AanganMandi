namespace AanganMandi.Domain.Common;

/// <summary>
/// A refusal raised by a service: the HTTP status and the <see cref="ApiError"/> the user sees (in their language).
/// The API turns it into the same problem+json as a controller's <c>this.Fail(...)</c>, so services hold the rules and
/// controllers only translate requests and responses.
/// </summary>
public sealed class ApiException(int status, ApiError error) : Exception(error.ToString())
{
    public int Status { get; } = status;
    public ApiError Error { get; } = error;

    public static ApiException BadRequest(string code, params (string Key, object? Value)[] args) => new(400, ApiError.Of(code, args));
    public static ApiException BadRequest(ApiError error) => new(400, error);
    public static ApiException Forbidden(string code) => new(403, new ApiError(code));
    /// <summary>The thing does not exist, or belongs to someone else (never told apart, so ids can't be probed).</summary>
    public static ApiException NotFound() => new(404, new ApiError("not_found"));
    public static ApiException Conflict(string code, params (string Key, object? Value)[] args) => new(409, ApiError.Of(code, args));
    public static ApiException Conflict(ApiError error) => new(409, error);
    public static ApiException Unprocessable(string code, params (string Key, object? Value)[] args) => new(422, ApiError.Of(code, args));
    public static ApiException Unprocessable(ApiError error) => new(422, error);
}
