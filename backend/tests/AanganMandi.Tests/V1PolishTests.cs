using AanganMandi.Domain.Support;
using AanganMandi.Infrastructure.Sharing;

namespace AanganMandi.Tests;

/// <summary>Problem reports and the legal pages.</summary>
public class V1PolishTests
{
    [Fact]
    public void A_report_needs_a_category_and_a_real_description()
    {
        Assert.Null(ProblemReport.Check(ReportCategory.NoShow, "The farmer never came to my gate.", 0));
        Assert.Equal("report_category_required", ProblemReport.Check((ReportCategory)99, "The farmer never came.", 0)?.Code);
        Assert.Equal("report_message_short", ProblemReport.Check(ReportCategory.Other, "   bad   ", 0)?.Code);
        Assert.Equal("report_message_long", ProblemReport.Check(ReportCategory.Other, new string('x', 1001), 0)?.Code);
    }

    [Fact]
    public void Reports_are_limited_per_day()
    {
        Assert.Null(ProblemReport.Check(ReportCategory.AppProblem, "The app closes when I upload.", ProblemReport.MaxPerDay - 1));
        Assert.Equal("report_too_many", ProblemReport.Check(ReportCategory.AppProblem, "The app closes when I upload.", ProblemReport.MaxPerDay)?.Code);
    }

    [Theory]
    [InlineData("en")]
    [InlineData("te")]
    [InlineData("hi")]
    public void The_terms_and_privacy_policy_render_with_version_draft_note_and_contact(string lang)
    {
        var terms = LegalPages.Terms(lang, "support@aanganmandi.in");
        var privacy = LegalPages.Privacy(lang, "support@aanganmandi.in");
        foreach (var html in new[] { terms, privacy })
        {
            Assert.Contains($"lang=\"{lang}\"", html);
            Assert.Contains(LegalPages.Version, html);
            Assert.Contains("support@aanganmandi.in", html);
            Assert.Contains("class=\"draft\"", html);
        }
        Assert.Contains("Digital Personal Data Protection Act", privacy);
        Assert.Contains("Hyderabad", terms);
        // Telugu and Hindi readers get a summary in their language on top.
        Assert.Equal(lang != "en", terms.Contains("class=\"summary\""));
    }

    [Fact]
    public void Without_a_contact_address_the_pages_point_to_the_app()
    {
        Assert.Contains("Report a problem", LegalPages.Privacy("en", null));
        Assert.DoesNotContain("Write to", LegalPages.Privacy("en", null));
    }
}
