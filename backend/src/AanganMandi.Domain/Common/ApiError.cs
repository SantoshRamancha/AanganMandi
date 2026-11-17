namespace AanganMandi.Domain.Common;

/// <summary>
/// Why a request was refused: a stable <see cref="Code"/> (e.g. "otp_wait") and the values in its message
/// (e.g. seconds = 30). The words, in English, Telugu and Hindi, come from the API's error catalogue (ErrorText), so
/// rules stay free of wording and every refusal reaches the user in their app language. The API sends the code and
/// values as well, for an app that wants to react to a particular refusal.
/// </summary>
public sealed record ApiError(string Code, IReadOnlyDictionary<string, object?> Args)
{
    private static readonly IReadOnlyDictionary<string, object?> None = new Dictionary<string, object?>();

    public ApiError(string code) : this(code, None) { }

    /// <summary><c>ApiError.Of("otp_wait", ("seconds", 30))</c>.</summary>
    public static ApiError Of(string code, params (string Key, object? Value)[] args) =>
        new(code, args.ToDictionary(a => a.Key, a => a.Value));

    public override string ToString() =>
        Args.Count == 0 ? Code : $"{Code}({string.Join(", ", Args.Select(a => $"{a.Key}={a.Value}"))})";
}
