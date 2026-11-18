using System.Text.RegularExpressions;
using AanganMandi.Domain.Common;
using AanganMandi.Infrastructure.Errors;

namespace AanganMandi.Tests;

/// <summary>Every refusal reaches the user in their language.</summary>
public class ErrorTextTests
{
    /// <summary>A value for every placeholder any error uses.</summary>
    private static readonly (string, object?)[] AllArgs =
    [
        ("seconds", 30), ("minutes", 40), ("radii", "1, 2, 5"), ("max", 200), ("min", 3), ("mb", 8), ("days", 60),
        ("time", "15:00"), ("meters", 730), ("phone", "+919000000009"), ("missing", "details"), ("count", 3),
    ];

    public static TheoryData<string, string> EveryCodeInEveryLanguage()
    {
        var data = new TheoryData<string, string>();
        foreach (var code in ErrorText.All.Keys)
            foreach (var lang in new[] { "en", "te", "hi" })
                data.Add(code, lang);
        return data;
    }

    [Theory]
    [MemberData(nameof(EveryCodeInEveryLanguage))]
    public void Every_error_renders_completely(string code, string lang)
    {
        var text = ErrorText.Render(ApiError.Of(code, AllArgs), lang);
        Assert.DoesNotContain("{{", text);
        Assert.False(string.IsNullOrWhiteSpace(text));
    }

    [Fact]
    public void Telugu_and_hindi_are_really_translated()
    {
        foreach (var (code, text) in ErrorText.All)
        {
            Assert.True(text.Te != text.En, $"{code} has no Telugu");
            Assert.True(text.Hi != text.En, $"{code} has no Hindi");
        }
    }

    [Fact]
    public void Values_are_filled_in_and_the_language_comes_from_the_header()
    {
        Assert.Equal("Please wait 30 seconds before asking for a new OTP",
            ErrorText.Render(ApiError.Of("otp_wait", ("seconds", 30)), "en"));
        Assert.Contains("30", ErrorText.Render(ApiError.Of("otp_wait", ("seconds", 30)), "te"));
        Assert.Equal("te", ErrorText.LanguageOf("te"));
        Assert.Equal("hi", ErrorText.LanguageOf("hi-IN,hi;q=0.9,en;q=0.8"));
        Assert.Equal("en", ErrorText.LanguageOf("fr-FR"));
        Assert.Equal("en", ErrorText.LanguageOf(null));
        Assert.Equal("made_up_code", ErrorText.Render(new ApiError("made_up_code"), "en"));   // missing = visible
    }

    /// <summary>
    /// Every code the API can send has words: scans the controllers and rule files for snake_case codes passed to
    /// Fail(...), ApiError or ApiException (controllers, rules and the services), so a typo or a new code without a
    /// translation fails here, not in front of a user.
    /// </summary>
    [Fact]
    public void Every_code_used_in_the_source_has_words()
    {
        var src = FindSourceFolder();
        var files = Directory.GetFiles(Path.Combine(src, "AanganMandi.Api"), "*.cs", SearchOption.AllDirectories)
            .Concat(Directory.GetFiles(Path.Combine(src, "AanganMandi.Application"), "*.cs", SearchOption.AllDirectories))
            .Concat(Directory.GetFiles(Path.Combine(src, "AanganMandi.Domain"), "*.cs", SearchOption.AllDirectories))
            .Concat(Directory.GetFiles(Path.Combine(src, "AanganMandi.Infrastructure", "Services"), "*.cs"))
            .Where(f => !f.Contains($"{Path.DirectorySeparatorChar}obj{Path.DirectorySeparatorChar}")
                && !f.Contains($"{Path.DirectorySeparatorChar}bin{Path.DirectorySeparatorChar}"));
        // Codes appear as Fail(400, "x_y"), new ApiError("x_y"), ApiError.Of("x_y", ...), new("x_y") in rules,
        // or as plain "x_y" strings chosen in a ternary or switch.
        var codeLiteral = new Regex("\"([a-z]+(?:_[a-z]+)+)\"");
        var used = new HashSet<string>();
        foreach (var file in files)
        {
            var text = File.ReadAllText(file);
            if (!text.Contains("Fail(") && !text.Contains("ApiError") && !text.Contains("ApiException")) continue;
            foreach (Match m in codeLiteral.Matches(text)) used.Add(m.Groups[1].Value);
        }
        // snake_case strings in those files that are not error codes.
        used.ExceptWith(["copy_uploads", "access_token", "refresh_token"]);
        var missing = used.Where(c => !ErrorText.All.ContainsKey(c)).Order().ToList();
        Assert.True(missing.Count == 0, "Codes without words in ErrorText: " + string.Join(", ", missing));
        Assert.True(used.Count > 60, $"Only {used.Count} codes found: is the scan still finding the controllers?");
        Assert.Contains("trip_locked", used);          // moved to TripService: the services are scanned too
        Assert.Contains("too_many_no_shows", used);
    }

    private static string FindSourceFolder()
    {
        var dir = new DirectoryInfo(AppContext.BaseDirectory);
        while (dir is not null && !Directory.Exists(Path.Combine(dir.FullName, "src", "AanganMandi.Api"))) dir = dir.Parent;
        return dir is null ? throw new DirectoryNotFoundException("backend/src not found above the test folder") : Path.Combine(dir.FullName, "src");
    }
}
