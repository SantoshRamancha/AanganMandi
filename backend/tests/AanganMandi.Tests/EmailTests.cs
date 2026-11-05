using AanganMandi.Application.Identity;
using AanganMandi.Infrastructure.Notifications;

namespace AanganMandi.Tests;

public class EmailTests
{
    /// <summary>A value for every placeholder any template uses.</summary>
    private static readonly Dictionary<string, string?> Values = new()
    {
        ["farmer"] = "Ramesh Reddy", ["host"] = "Lakshmi Prasad", ["space"] = "Green villa courtyard",
        ["locality"] = "Ameerpet", ["date"] = "Sat, 7 Nov 2026", ["admin"] = "Ops Admin", ["phone"] = "+919000000009",
    };

    public static TheoryData<string, string> EveryTemplateInEveryLanguage()
    {
        var data = new TheoryData<string, string>();
        foreach (var t in MailText.All)
            foreach (var lang in new[] { "en", "te", "hi" })
                data.Add(t.Key, lang);
        return data;
    }

    [Theory]
    [MemberData(nameof(EveryTemplateInEveryLanguage))]
    public void Templates_render_completely(string key, string lang)
    {
        var template = MailText.All.Single(t => t.Key == key);
        var mail = MailLayout.Render(template, lang, "Ramesh Reddy", Values,
            [new(MailText.Date, "Sat, 7 Nov 2026")], new(MailText.ReasonTitle, "Photo unclear"), "http://localhost:5090");

        Assert.DoesNotContain("{{", mail.Subject);
        Assert.DoesNotContain("{{", mail.Html);
        Assert.True(mail.Subject.Length <= 200);
        Assert.Contains($"lang=\"{lang}\"", mail.Html);
        Assert.Contains(MailText.Footer.For(lang).Split(' ')[0], mail.Html);
        Assert.Contains("Photo unclear", mail.Html);
        Assert.Contains("http://localhost:5090", mail.Html);
    }

    [Fact]
    public void Each_language_has_its_own_wording()
    {
        foreach (var t in MailText.All)
        {
            Assert.NotEqual(t.Subject.En, t.Subject.Te);
            Assert.NotEqual(t.Subject.En, t.Subject.Hi);
            Assert.NotEqual(t.Body.En, t.Body.Te);
        }
    }

    [Fact]
    public void Typed_values_are_html_encoded()
    {
        var values = new Dictionary<string, string?>(Values) { ["farmer"] = "<script>alert(1)</script>" };
        var mail = MailLayout.Render(MailText.BookingRequested, "en", "<b>Host</b>", values,
            [new(MailText.Farmer, "<i>x</i>")], new(MailText.MessageTitle, "<img src=x>"));

        Assert.DoesNotContain("<script>", mail.Html);
        Assert.DoesNotContain("<b>Host</b>", mail.Html);
        Assert.DoesNotContain("<i>x</i>", mail.Html);
        Assert.DoesNotContain("<img", mail.Html);
        Assert.Contains("&lt;script&gt;", mail.Html);
    }

    [Fact]
    public void No_button_without_an_app_address_and_greeting_without_a_name()
    {
        var mail = MailLayout.Render(MailText.FarmerApproved, "te", null, Values);
        Assert.DoesNotContain("<a href", mail.Html);
        Assert.Contains(MailText.GreetingNoName.Te, mail.Html);
    }

    [Fact]
    public void Dates_are_written_in_the_recipients_language()
    {
        var date = new DateOnly(2026, 11, 7);
        Assert.Equal("Sat, 7 Nov 2026", EmailNotifier.FormatDate(date, "en"));
        Assert.NotEqual(EmailNotifier.FormatDate(date, "en"), EmailNotifier.FormatDate(date, "te"));
        Assert.NotEqual(EmailNotifier.FormatDate(date, "en"), EmailNotifier.FormatDate(date, "hi"));
    }

    [Theory]
    [InlineData("  Ramesh@Example.COM ", "ramesh@example.com")]
    [InlineData("a.b-c@farm.co.in", "a.b-c@farm.co.in")]
    public void Valid_emails_are_tidied(string input, string expected)
    {
        var (email, error) = EmailAddresses.Normalize(input);
        Assert.Null(error);
        Assert.Equal(expected, email);
    }

    [Theory]
    [InlineData("not-an-email")]
    [InlineData("name@localhost")]
    [InlineData("Ramesh <ramesh@example.com>")]
    [InlineData("a@b.")]
    public void Invalid_emails_are_rejected(string input) => Assert.NotNull(EmailAddresses.Normalize(input).Error);

    [Fact]
    public void An_empty_email_means_none() => Assert.Equal((null, null), EmailAddresses.Normalize("  "));
}
