using System.Globalization;
using System.Net;
using System.Text;
using AanganMandi.Domain.Trips;
using AanganMandi.Infrastructure.Notifications;

namespace AanganMandi.Infrastructure.Sharing;

/// <summary>One crop on the stall, its name already in the page language.</summary>
public sealed record StallCrop(string Name, decimal? PricePerKg);

/// <summary>Everything the public page shows. Address and position are filled only while selling now.</summary>
public sealed record StallView(StallState State, DateOnly Date, TimeOnly From, TimeOnly To, string FarmerFirstName,
    string? Village, IReadOnlyList<StallCrop> Crops, string SpaceTitle, string Locality, string? Address,
    double? Latitude, double? Longitude);

/// <summary>
/// The public page behind a link a host shares with neighbours (WhatsApp groups, posters). No login, no tracking,
/// no phone numbers, the farmer's first name only; the exact address only while the farmer is there. Plain HTML
/// with Open Graph tags, so WhatsApp shows a preview card. Every value is HTML-encoded.
/// </summary>
public static class StallPage
{
    public static readonly string[] Languages = ["en", "te", "hi"];

    private static readonly L Brand = new("Aangan Mandi", "ఆంగన్ మండి", "आंगन मंडी");
    private static readonly L TitleUpcoming = new("Fresh produce in {{locality}} on {{date}}",
        "{{date}} న {{locality}}లో తాజా పంట", "{{date}} को {{locality}} में ताज़ी उपज");
    private static readonly L TitleNow = new("Selling now in {{locality}}", "ఇప్పుడు {{locality}}లో అమ్ముతున్నారు",
        "अभी {{locality}} में बिक रहा है");
    private static readonly L TitleOver = new("This stall is over", "ఈ దుకాణం ముగిసింది", "यह दुकान ख़त्म हो गई");
    private static readonly L SellingNow = new("Selling now", "ఇప్పుడు అమ్ముతున్నారు", "अभी बिक रहा है");
    private static readonly L Coming = new("Coming", "రాబోతోంది", "आने वाला");
    private static readonly L Over = new("Over", "ముగిసింది", "ख़त्म");
    private static readonly L Verified = new("Verified farmer", "ధృవీకరించిన రైతు", "सत्यापित किसान");
    private static readonly L From = new("from {{village}}", "{{village}} నుండి", "{{village}} से");
    private static readonly L Bringing = new("Bringing", "తెస్తున్నవి", "ला रहे हैं");
    private static readonly L Where = new("Where", "ఎక్కడ", "कहाँ");
    private static readonly L When = new("When", "ఎప్పుడు", "कब");
    private static readonly L Until = new("until {{time}}", "{{time}} వరకు", "{{time}} बजे तक");
    private static readonly L OpenMaps = new("Open in maps", "మ్యాప్స్‌లో తెరవండి", "मैप्स में खोलें");
    private static readonly L AddressLater = new("The exact place shows here when the farmer arrives. Open this link again then.",
        "రైతు వచ్చినప్పుడు సరిగ్గా ఎక్కడ అనేది ఇక్కడ కనిపిస్తుంది. అప్పుడు ఈ లింక్ మళ్లీ తెరవండి.",
        "किसान के पहुँचने पर सही जगह यहाँ दिखेगी। तब यह लिंक फिर से खोलें।");
    private static readonly L OverBody = new("This farmer's selling day here has ended. Ask your neighbour who shared it about the next one.",
        "ఇక్కడ ఈ రైతు అమ్మకం రోజు ముగిసింది. తదుపరి రోజు గురించి దీన్ని పంచుకున్న మీ పొరుగువారిని అడగండి.",
        "यहाँ इस किसान की बिक्री का दिन ख़त्म हो गया। अगली बार के बारे में इसे भेजने वाले पड़ोसी से पूछें।");
    private static readonly L About = new("Verified farmers sell their own produce at homes in your neighbourhood. Pay the farmer at the stall.",
        "ధృవీకరించిన రైతులు మీ పరిసరాల్లోని ఇళ్ల వద్ద తమ సొంత పంటను అమ్ముతారు. దుకాణం వద్దే రైతుకు చెల్లించండి.",
        "सत्यापित किसान आपके मोहल्ले के घरों पर अपनी उपज बेचते हैं। दुकान पर ही किसान को भुगतान करें।");
    private static readonly L GetApp = new("Get alerts in the Aangan Mandi app", "ఆంగన్ మండి యాప్‌లో హెచ్చరికలు పొందండి",
        "आंगन मंडी ऐप में सूचनाएँ पाएँ");

    /// <summary>The page language: ?lang= if valid, else the first supported Accept-Language, else English.</summary>
    public static string PickLanguage(string? query, string? acceptLanguage)
    {
        if (query is not null && Languages.Contains(query)) return query;
        foreach (var part in (acceptLanguage ?? "").Split(','))
        {
            var tag = part.Split(';')[0].Trim();
            var primary = tag.Split('-')[0].ToLowerInvariant();
            if (Languages.Contains(primary)) return primary;
        }
        return "en";
    }

    public static string Render(StallView v, string lang, string pageUrl, string? appUrl)
    {
        var date = EmailNotifier.FormatDate(v.Date, lang);
        var vals = new Dictionary<string, string> { ["locality"] = v.Locality, ["date"] = date, ["village"] = v.Village ?? "",
            ["time"] = Time(v.To) };
        var title = Fill((v.State switch { StallState.SellingNow => TitleNow, StallState.Over => TitleOver, _ => TitleUpcoming }).For(lang), vals);
        var crops = string.Join(", ", v.Crops.Select(CropText));
        var description = v.State == StallState.Over
            ? OverBody.For(lang)
            : $"{Verified.For(lang)} {v.FarmerFirstName} · {Time(v.From)}–{Time(v.To)} · {crops}";

        var h = new StringBuilder();
        h.Append($"<!doctype html><html lang=\"{lang}\"><head><meta charset=\"utf-8\">");
        h.Append("<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><meta name=\"robots\" content=\"noindex\">");
        h.Append($"<title>{E(title)} · {E(Brand.For(lang))}</title>");
        h.Append($"<meta property=\"og:type\" content=\"website\"><meta property=\"og:title\" content=\"{E(title)}\">");
        h.Append($"<meta property=\"og:description\" content=\"{E(description)}\"><meta property=\"og:url\" content=\"{E(pageUrl)}\">");
        h.Append($"<meta property=\"og:site_name\" content=\"{E(Brand.For(lang))}\"><meta name=\"description\" content=\"{E(description)}\">");
        h.Append("<style>").Append(Css).Append("</style></head><body><main>");

        // Language switch, then the brand.
        h.Append("<nav>");
        foreach (var (code, name) in new[] { ("en", "English"), ("te", "తెలుగు"), ("hi", "हिन्दी") })
            h.Append(code == lang ? $"<b>{name}</b>" : $"<a href=\"?lang={code}\">{name}</a>");
        h.Append($"</nav><p class=\"brand\">{E(Brand.For(lang))}</p>");

        var (badge, cls) = v.State switch
        {
            StallState.SellingNow => (SellingNow.For(lang), "now"),
            StallState.Over => (Over.For(lang), "over"),
            _ => (Coming.For(lang), "soon"),
        };
        h.Append($"<span class=\"badge {cls}\">{E(badge)}</span><h1>{E(title)}</h1>");

        if (v.State == StallState.Over)
        {
            h.Append($"<p>{E(OverBody.For(lang))}</p>");
        }
        else
        {
            var who = string.IsNullOrWhiteSpace(v.Village) ? v.FarmerFirstName : $"{v.FarmerFirstName}, {Fill(From.For(lang), vals)}";
            h.Append($"<p class=\"who\">✔ {E(Verified.For(lang))}: <b>{E(who)}</b></p>");
            var when = v.State == StallState.SellingNow ? Fill(Until.For(lang), vals) : $"{date} · {Time(v.From)}–{Time(v.To)}";
            h.Append($"<dl><dt>{E(When.For(lang))}</dt><dd>{E(when)}</dd>");
            h.Append($"<dt>{E(Where.For(lang))}</dt><dd>{E(v.SpaceTitle)}, {E(v.Locality)}");
            if (v.State == StallState.SellingNow && v.Address is not null)
            {
                h.Append($"<br><b>{E(v.Address)}</b>");
                if (v.Latitude is { } lat && v.Longitude is { } lng)
                    h.Append($"<br><a class=\"btn\" href=\"https://www.google.com/maps?q={lat.ToString(CultureInfo.InvariantCulture)},{lng.ToString(CultureInfo.InvariantCulture)}\">{E(OpenMaps.For(lang))}</a>");
            }
            else
            {
                h.Append($"<br><small>{E(AddressLater.For(lang))}</small>");
            }
            h.Append("</dd>");
            if (v.Crops.Count > 0)
            {
                h.Append($"<dt>{E(Bringing.For(lang))}</dt><dd><ul>");
                foreach (var c in v.Crops) h.Append($"<li>{E(CropText(c))}</li>");
                h.Append("</ul></dd>");
            }
            h.Append("</dl>");
        }

        h.Append($"<footer><p>{E(About.For(lang))}</p>");
        if (!string.IsNullOrWhiteSpace(appUrl)) h.Append($"<a href=\"{E(appUrl)}\">{E(GetApp.For(lang))}</a>");
        h.Append("</footer></main></body></html>");
        return h.ToString();
    }

    private static string CropText(StallCrop c)
    {
        var parts = new List<string> { c.Name };
        if (c.PricePerKg is { } p) parts.Add($"₹{p:0.##}/kg");
        return string.Join(" ", parts);
    }

    private static string Time(TimeOnly t) => t.ToString("HH:mm", CultureInfo.InvariantCulture);

    private static string Fill(string text, Dictionary<string, string> values) =>
        values.Aggregate(text, (s, kv) => s.Replace("{{" + kv.Key + "}}", kv.Value));

    private static string E(string s) => WebUtility.HtmlEncode(s);

    private const string Css =
        "body{margin:0;font-family:system-ui,-apple-system,'Segoe UI',Roboto,'Noto Sans','Noto Sans Telugu','Noto Sans Devanagari',sans-serif;" +
        "background:#f6f7f2;color:#1d2a1f;line-height:1.5}main{max-width:560px;margin:0 auto;padding:20px 16px 40px}" +
        "nav{display:flex;gap:12px;justify-content:flex-end;font-size:14px}nav a{color:#2e6b34}" +
        ".brand{color:#2e6b34;font-weight:700;margin:8px 0 16px}h1{font-size:24px;line-height:1.25;margin:8px 0 16px}" +
        ".badge{display:inline-block;padding:4px 12px;border-radius:99px;font-size:14px;font-weight:600}" +
        ".now{background:#2e6b34;color:#fff}.soon{background:#e3efd9;color:#1d4d22}.over{background:#e7e7e2;color:#555}" +
        ".who{font-size:17px}dl{background:#fff;border-radius:12px;padding:16px;margin:0 0 20px}" +
        "dt{font-size:13px;color:#5b6b5d;margin-top:12px}dt:first-child{margin-top:0}dd{margin:2px 0 0;font-size:17px}" +
        "ul{margin:4px 0 0;padding-left:20px}small{color:#5b6b5d;font-size:14px}" +
        ".btn{display:inline-block;margin-top:10px;background:#2e6b34;color:#fff;padding:10px 16px;border-radius:8px;text-decoration:none}" +
        "footer{font-size:14px;color:#5b6b5d}footer a{color:#2e6b34}" +
        "@media(prefers-color-scheme:dark){body{background:#121612;color:#e6ece4}dl{background:#1d241d}" +
        ".soon{background:#24402a;color:#d6ecd0}.over{background:#2c2c2a;color:#bbb}dt,small,footer{color:#a9b6a8}}";
}
