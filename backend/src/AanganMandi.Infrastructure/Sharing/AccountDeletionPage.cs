using System.Net;
using System.Text;
using AanganMandi.Infrastructure.Notifications;

namespace AanganMandi.Infrastructure.Sharing;

/// <summary>
/// The public "delete your account" page (GET /account/delete): the web link the Play Store asks for. Explains how to
/// delete in the app, what is deleted and what is kept, and whom to write to if the app cannot be opened.
/// </summary>
public static class AccountDeletionPage
{
    private static readonly L Title = new("Delete your Aangan Mandi account", "మీ ఆంగన్ మండి ఖాతాను తొలగించండి",
        "अपना आंगन मंडी खाता हटाएँ");
    private static readonly L HowTitle = new("How to delete it", "ఎలా తొలగించాలి", "कैसे हटाएँ");
    private static readonly L Steps = new(
        "Open the Aangan Mandi app and log in with your mobile number.|Tap your initials at the top right to open My profile.|Tap \"Delete my account\" at the bottom and confirm.",
        "ఆంగన్ మండి యాప్ తెరిచి మీ మొబైల్ నంబర్‌తో లాగిన్ అవ్వండి.|నా ప్రొఫైల్ తెరవడానికి పై కుడివైపున మీ అక్షరాలపై నొక్కండి.|కింద \"నా ఖాతాను తొలగించు\" నొక్కి నిర్ధారించండి.",
        "आंगन मंडी ऐप खोलें और अपने मोबाइल नंबर से लॉग इन करें।|मेरी प्रोफ़ाइल खोलने के लिए ऊपर दाईं ओर अपने अक्षरों पर टैप करें।|नीचे \"मेरा खाता हटाएँ\" पर टैप करें और पुष्टि करें।");
    private static readonly L DeletedTitle = new("What is deleted", "ఏమి తొలగించబడుతుంది", "क्या हटाया जाता है");
    private static readonly L Deleted = new(
        "Your name, mobile number and email.|Your farming details, crops and the proof photo you uploaded.|Your spaces with their photos and proof.|Your saved area and alerts.|Upcoming bookings are cancelled and the other person is told.",
        "మీ పేరు, మొబైల్ నంబర్, ఈమెయిల్.|మీ వ్యవసాయ వివరాలు, పంటలు, మీరు అప్‌లోడ్ చేసిన రుజువు ఫోటో.|మీ స్థలాలు, వాటి ఫోటోలు, రుజువు.|మీరు సేవ్ చేసిన ప్రాంతం, హెచ్చరికలు.|రాబోయే బుకింగ్‌లు రద్దవుతాయి, అవతలి వ్యక్తికి తెలియజేయబడుతుంది.",
        "आपका नाम, मोबाइल नंबर और ईमेल।|आपकी खेती का विवरण, फ़सलें और आपकी अपलोड की गई सबूत की फ़ोटो।|आपकी जगहें, उनकी फ़ोटो और सबूत।|आपका सेव किया इलाका और सूचनाएँ।|आने वाली बुकिंग रद्द होती हैं और दूसरे व्यक्ति को बताया जाता है।");
    private static readonly L KeptTitle = new("What is kept", "ఏమి ఉంచబడుతుంది", "क्या रखा जाता है");
    private static readonly L Kept = new(
        "Past bookings stay in the other person's history (date, space, crops), without your name or number.",
        "గత బుకింగ్‌లు అవతలి వ్యక్తి చరిత్రలో (తేదీ, స్థలం, పంటలు) మీ పేరు, నంబర్ లేకుండా ఉంటాయి.",
        "पुरानी बुकिंग दूसरे व्यक्ति के इतिहास में (तारीख़, जगह, फ़सलें) आपके नाम या नंबर के बिना रहती हैं।");
    private static readonly L NoAppTitle = new("Can't open the app?", "యాప్ తెరవలేకపోతున్నారా?", "ऐप नहीं खुल रहा?");
    private static readonly L NoApp = new(
        "Email {{email}} from any address with your registered mobile number, and we will delete the account within 7 days.",
        "మీ నమోదైన మొబైల్ నంబర్‌తో {{email}}కు ఈమెయిల్ చేయండి, 7 రోజుల్లో మీ ఖాతాను తొలగిస్తాము.",
        "अपने रजिस्टर्ड मोबाइल नंबर के साथ {{email}} पर ईमेल करें, हम 7 दिनों में खाता हटा देंगे।");

    public static string Render(string lang, string? supportEmail)
    {
        static string E(string s) => WebUtility.HtmlEncode(s);
        static string List(string items, string tag) =>
            $"<{tag}>" + string.Concat(items.Split('|').Select(i => $"<li>{E(i)}</li>")) + $"</{tag}>";

        var h = new StringBuilder();
        h.Append($"<!doctype html><html lang=\"{lang}\"><head><meta charset=\"utf-8\">");
        h.Append("<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">");
        h.Append($"<title>{E(Title.For(lang))}</title><style>");
        h.Append("body{margin:0;font-family:system-ui,-apple-system,'Segoe UI',Roboto,'Noto Sans','Noto Sans Telugu','Noto Sans Devanagari',sans-serif;background:#f6f7f2;color:#1d2a1f;line-height:1.55}");
        h.Append("main{max-width:620px;margin:0 auto;padding:20px 16px 40px}nav{display:flex;gap:12px;justify-content:flex-end;font-size:14px}nav a{color:#2e6b34}");
        h.Append("h1{font-size:24px}h2{font-size:18px;margin-top:24px}li{margin:4px 0}");
        h.Append("@media(prefers-color-scheme:dark){body{background:#121612;color:#e6ece4}nav a{color:#9ccc9f}}</style></head><body><main><nav>");
        foreach (var (code, name) in new[] { ("en", "English"), ("te", "తెలుగు"), ("hi", "हिन्दी") })
            h.Append(code == lang ? $"<b>{name}</b>" : $"<a href=\"?lang={code}\">{name}</a>");
        h.Append($"</nav><h1>{E(Title.For(lang))}</h1>");
        h.Append($"<h2>{E(HowTitle.For(lang))}</h2>{List(Steps.For(lang), "ol")}");
        h.Append($"<h2>{E(DeletedTitle.For(lang))}</h2>{List(Deleted.For(lang), "ul")}");
        h.Append($"<h2>{E(KeptTitle.For(lang))}</h2><p>{E(Kept.For(lang))}</p>");
        if (!string.IsNullOrWhiteSpace(supportEmail))
            h.Append($"<h2>{E(NoAppTitle.For(lang))}</h2><p>{E(NoApp.For(lang).Replace("{{email}}", supportEmail))}</p>");
        h.Append("</main></body></html>");
        return h.ToString();
    }
}
