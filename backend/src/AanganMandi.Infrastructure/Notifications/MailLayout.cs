using System.Net;
using System.Text;
using Kinichit.Communication;

namespace AanganMandi.Infrastructure.Notifications;

/// <summary>A label and its value (already in the recipient's language) for the details table.</summary>
public sealed record MailDetail(L Label, string Value);

/// <summary>A highlighted box, e.g. the rejection reason or the farmer's message.</summary>
public sealed record MailNote(L Title, string Text);

public sealed record RenderedMail(string Subject, string Html);

/// <summary>
/// The one HTML layout every email uses: brand header, heading, greeting, paragraphs, details table, note box, button, footer.
/// Tables and inline styles only, so it looks the same in Gmail, Outlook and phone mail apps.
/// </summary>
public static class MailLayout
{
    private const string Brand = "#2E7D32", BrandDark = "#1B5E20", Page = "#F1F4EC", Muted = "#5C6356", Line = "#DFE5D6";

    /// <param name="values">Placeholder values for the template's subject, heading and body (HTML-encoded here).</param>
    public static RenderedMail Render(MailTemplate template, string lang, string? recipientName,
        IReadOnlyDictionary<string, string?> values, IReadOnlyList<MailDetail>? details = null, MailNote? note = null,
        string? appUrl = null)
    {
        static string E(string? s) => WebUtility.HtmlEncode(s ?? "");
        var subject = MessageTemplate.Render(template.Subject.For(lang), values);
        if (subject.Length > 200) subject = subject[..199] + "…"; // the email queue's Subject column holds 200
        var heading = MessageTemplate.Render(template.Heading.For(lang), values, htmlEncode: true);
        var greeting = string.IsNullOrWhiteSpace(recipientName)
            ? E(MailText.GreetingNoName.For(lang))
            : MessageTemplate.Render(MailText.Greeting.For(lang), new Dictionary<string, string?> { ["name"] = recipientName }, htmlEncode: true);
        var paragraphs = template.Body.For(lang).Split("\n\n")
            .Select(p => MessageTemplate.Render(p, values, htmlEncode: true));

        var h = new StringBuilder();
        h.Append($"""
            <!doctype html>
            <html lang="{lang}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
            <title>{E(subject)}</title></head>
            <body style="margin:0;padding:0;background:{Page};font-family:'Segoe UI',Roboto,'Noto Sans','Noto Sans Telugu','Noto Sans Devanagari',Arial,sans-serif;color:#1B1D18;">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:{Page};padding:24px 12px;"><tr><td align="center">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;background:#ffffff;border:1px solid {Line};border-radius:16px;overflow:hidden;">
            <tr><td style="background:{Brand};padding:18px 28px;color:#ffffff;font-size:20px;font-weight:700;letter-spacing:.3px;">Aangan Mandi</td></tr>
            <tr><td style="padding:28px 28px 8px 28px;">
            <h1 style="margin:0 0 18px 0;font-size:22px;line-height:1.3;color:{BrandDark};">{heading}</h1>
            <p style="margin:0 0 14px 0;font-size:16px;line-height:1.55;">{greeting}</p>
            """);
        foreach (var p in paragraphs)
            h.Append($"""<p style="margin:0 0 14px 0;font-size:16px;line-height:1.55;">{p}</p>""");

        if (details is { Count: > 0 })
        {
            h.Append($"""<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:8px 0 18px 0;border:1px solid {Line};border-radius:12px;border-collapse:separate;">""");
            foreach (var (d, i) in details.Select((d, i) => (d, i)))
            {
                var top = i == 0 ? "" : $"border-top:1px solid {Line};";
                h.Append($"""
                    <tr><td style="{top}padding:10px 14px;width:34%;color:{Muted};font-size:14px;vertical-align:top;">{E(d.Label.For(lang))}</td>
                    <td style="{top}padding:10px 14px;font-size:15px;font-weight:600;vertical-align:top;">{E(d.Value)}</td></tr>
                    """);
            }
            h.Append("</table>");
        }

        if (note is not null)
            h.Append($"""
                <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 18px 0;"><tr>
                <td style="background:#FFF4D6;border-left:4px solid #B07800;border-radius:8px;padding:12px 16px;">
                <div style="font-size:13px;color:#6B4A00;font-weight:700;margin-bottom:4px;">{E(note.Title.For(lang))}</div>
                <div style="font-size:15px;line-height:1.5;color:#3D2A00;">{E(note.Text)}</div></td></tr></table>
                """);

        if (!string.IsNullOrWhiteSpace(appUrl))
            h.Append($"""
                <table role="presentation" cellpadding="0" cellspacing="0" style="margin:6px 0 22px 0;"><tr>
                <td style="background:{Brand};border-radius:10px;"><a href="{E(appUrl)}" style="display:inline-block;padding:12px 22px;color:#ffffff;font-size:16px;font-weight:700;text-decoration:none;">{E(MailText.OpenApp.For(lang))}</a></td>
                </tr></table>
                """);

        h.Append($"""
            </td></tr>
            <tr><td style="background:#F6F8F2;border-top:1px solid {Line};padding:16px 28px;color:{Muted};font-size:12px;line-height:1.5;">{E(MailText.Footer.For(lang))}</td></tr>
            </table></td></tr></table></body></html>
            """);
        return new RenderedMail(subject, h.ToString());
    }
}
