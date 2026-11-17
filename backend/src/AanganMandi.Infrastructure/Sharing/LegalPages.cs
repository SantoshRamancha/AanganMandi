using System.Net;
using System.Text;
using AanganMandi.Infrastructure.Notifications;

namespace AanganMandi.Infrastructure.Sharing;

/// <summary>
/// The terms of use and the privacy policy (GET /legal/terms, /legal/privacy). The full text is in English; Telugu
/// and Hindi readers get a summary in their language at the top. The texts describe what this app really does
/// (see README) and are a DRAFT to be checked by a lawyer before launch.
/// Changing either text: raise <see cref="Version"/>, and every user is asked to accept again in the app.
/// </summary>
public static class LegalPages
{
    /// <summary>The version users accept (User.TermsVersion). Raise it whenever the terms or the policy change.</summary>
    public const string Version = "2026-11-17";

    private static readonly L TermsTitle = new("Terms of use", "వినియోగ నిబంధనలు", "उपयोग की शर्तें");
    private static readonly L PrivacyTitle = new("Privacy policy", "గోప్యతా విధానం", "गोपनीयता नीति");
    private static readonly L Draft = new(
        "Draft for review: this text is to be checked by a lawyer before Aangan Mandi is launched.",
        "సమీక్ష కోసం ముసాయిదా: ఆంగన్ మండి ప్రారంభానికి ముందు దీన్ని న్యాయవాది తనిఖీ చేయాలి.",
        "समीक्षा के लिए मसौदा: आंगन मंडी शुरू होने से पहले इसे वकील जाँचेंगे।");
    private static readonly L EnglishBelow = new("",
        "పూర్తి పాఠం ఆంగ్లంలో కింద ఉంది. సారాంశం:",
        "पूरा पाठ नीचे अंग्रेज़ी में है। सारांश:");
    private static readonly L TermsSummary = new("",
        "ఆంగన్ మండి ధృవీకరించిన రైతులను, తమ స్థలాన్ని కొన్ని గంటలకు ఇచ్చే యజమానులను, దగ్గరి కొనుగోలుదారులను కలుపుతుంది.|అమ్మకం, చెల్లింపు రైతు, యజమాని, కొనుగోలుదారుల మధ్య నేరుగా జరుగుతాయి; ఆంగన్ మండి డబ్బు తీసుకోదు, పంట నాణ్యతకు హామీ ఇవ్వదు.|సరైన వివరాలు, మీకు హక్కు ఉన్న స్థలాలు, మీ సొంత లేదా సేకరించిన పంట మాత్రమే ఇవ్వండి.|తప్పుడు సమాచారం, ఇతరులను ఇబ్బంది పెట్టడం జరిగితే మేము ఖాతాను ఆపవచ్చు.|మీ ఖాతాను ఎప్పుడైనా యాప్‌లో తొలగించవచ్చు.",
        "आंगन मंडी सत्यापित किसानों, कुछ घंटों के लिए अपनी जगह देने वाले मेज़बानों और आस-पास के खरीदारों को जोड़ती है।|बिक्री और भुगतान सीधे किसान, मेज़बान और खरीदार के बीच होते हैं; आंगन मंडी पैसे नहीं लेती और उपज की गुणवत्ता की गारंटी नहीं देती।|सही जानकारी दें, सिर्फ़ वही जगह दें जिसका आपको हक़ है, और अपनी या जुटाई हुई उपज ही बेचें।|ग़लत जानकारी या दूसरों को परेशान करने पर हम खाता रोक सकते हैं।|आप कभी भी ऐप में अपना खाता हटा सकते हैं।");
    private static readonly L PrivacySummary = new("",
        "మేము సేకరించేవి: మొబైల్ నంబర్, పేరు, ఐచ్ఛికంగా ఈమెయిల్; రైతుల వ్యవసాయ వివరాలు, రుజువు ఫోటో; స్థలాల చిరునామా, లొకేషన్, ఫోటోలు; చెక్ ఇన్ సమయంలో, కొనుగోలుదారు ప్రాంతం కోసం లొకేషన్.|ఎందుకు: ధృవీకరణ, బుకింగ్‌లు, మీకు తెలియజేయడం, మోసాన్ని ఆపడం.|ఫోన్ నంబర్లు, చిరునామా బుకింగ్ అంగీకరించిన తర్వాతే అవతలి వ్యక్తికి కనిపిస్తాయి. మేము మీ డేటాను అమ్మము.|మీ ఖాతాను యాప్‌లో తొలగించవచ్చు; ప్రశ్నలు, ఫిర్యాదుల కోసం కింద ఉన్న చిరునామాకు రాయండి.",
        "हम क्या लेते हैं: मोबाइल नंबर, नाम, वैकल्पिक ईमेल; किसानों की खेती का विवरण और सबूत की फ़ोटो; जगहों का पता, लोकेशन और फ़ोटो; चेक इन के समय और खरीदार के इलाके के लिए लोकेशन।|क्यों: सत्यापन, बुकिंग, आपको सूचना देना, धोखाधड़ी रोकना।|फ़ोन नंबर और पता बुकिंग स्वीकार होने के बाद ही दूसरे व्यक्ति को दिखते हैं। हम आपका डेटा नहीं बेचते।|आप ऐप में खाता हटा सकते हैं; सवाल या शिकायत के लिए नीचे दिए पते पर लिखें।");

    public static string Terms(string lang, string? contactEmail) => Page(lang, TermsTitle, TermsSummary, contactEmail,
    [
        ("What Aangan Mandi is", "Aangan Mandi is an app that connects verified farmers with residents who lend a driveway, courtyard or other space for a few hours (hosts), and with buyers nearby. Aangan Mandi is not a party to any sale."),
        ("Who can use it", "You must be at least 18 and give a mobile number that is yours. Farmers are verified by our team before they can book spaces; hosts' spaces are reviewed before they go live."),
        ("Sales and payment", "Farmers sell their produce directly to buyers and pay any fee for a space directly to the host, at the space. Aangan Mandi does not collect, hold or refund money and does not guarantee the quality, quantity or price of produce, or the condition of a space."),
        ("What you agree to", "Give true details and documents. List only spaces you have the right to lend. Sell only produce you grew or sourced as you described. Keep your bookings, or cancel in the app in time. Treat others with respect and follow local rules on selling, parking and noise."),
        ("Bookings and check-in", "A booking is an agreement between the farmer and the host for the day and hours shown. The farmer checks in from the app at the space; the host may record that a farmer did not come. Repeated no-shows or problems may lead to an account being limited."),
        ("Shared links", "A host may share a link to a confirmed stall. Anyone with the link sees the farmer's first name and village, the crops, prices, time and area, and the address only while the farmer is there."),
        ("Problems", "Report a problem from the booking or from My profile; our team looks at every report and replies. We may suspend or remove accounts that give false information, misuse the app or harm others."),
        ("Ending", "You can delete your account at any time in My profile; what happens to your data is described in the privacy policy."),
        ("Liability", "Aangan Mandi provides the app as it is. To the extent the law allows, we are not responsible for losses arising from sales, payments, produce or spaces arranged through the app."),
        ("Changes and law", "We may update these terms; the app asks you to accept the new version before you continue. These terms are governed by the laws of India, and the courts at Hyderabad, Telangana have jurisdiction."),
    ]);

    public static string Privacy(string lang, string? contactEmail) => Page(lang, PrivacyTitle, PrivacySummary, contactEmail,
    [
        ("Who we are", "Aangan Mandi is the data fiduciary for the personal data described here, under the Digital Personal Data Protection Act, 2023."),
        ("What we collect", "Everyone: mobile number, name, app language, and an email address if you add one. Farmers: village, district, crops, farm size, the kind of farming proof, its number or reference, and a photo of it. Hosts: space details, address, the location you capture, photos, and a photo of your right to use the space. Buyers: a location you save and the radius you choose. When a farmer checks in, the phone's location at that moment, to confirm they are at the space. Technical logs (time, page, error) to keep the service working."),
        ("Why we use it", "To log you in, verify farmers and spaces, make and manage bookings, show nearby stalls, send you the emails you need (bookings, reminders, alerts you turned on), handle problem reports, and prevent fraud and misuse. We do not sell your data or use it for advertising."),
        ("Who sees it", "Verifiers and admins of Aangan Mandi, to review farmers and spaces and handle reports. The other side of a booking: phone numbers and the space address are shared only once the host accepts. Buyers nearby: a farmer's first name, village, crops and the area of a stall, and its address only while the farmer is there. Service providers who host our servers, store files and send email, only to provide the service."),
        ("How long we keep it", "While your account exists. When you delete your account, your name, number, email, farming details and documents, spaces and their files, and saved area are deleted; past bookings stay for the other person's records without your name. Logs are kept for 30 days."),
        ("Your rights", "You can see and correct your details in the app, withdraw consent by deleting your account (My profile, Delete my account), ask what data we hold, and complain to us or to the Data Protection Board of India."),
        ("Security", "Data is sent over encrypted connections, documents are stored privately and shown only to the people above, and access by our team is limited to their work."),
        ("Children", "Aangan Mandi is for people aged 18 and over."),
        ("Changes", "We may update this policy; the app asks you to accept the new version before you continue."),
    ]);

    private static string Page(string lang, L title, L summary, string? contactEmail, (string Heading, string Text)[] sections)
    {
        static string E(string s) => WebUtility.HtmlEncode(s);
        var h = new StringBuilder();
        h.Append($"<!doctype html><html lang=\"{lang}\"><head><meta charset=\"utf-8\">");
        h.Append("<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">");
        h.Append($"<title>{E(title.For(lang))} · Aangan Mandi</title><style>");
        h.Append("body{margin:0;font-family:system-ui,-apple-system,'Segoe UI',Roboto,'Noto Sans','Noto Sans Telugu','Noto Sans Devanagari',sans-serif;background:#f6f7f2;color:#1d2a1f;line-height:1.6}");
        h.Append("main{max-width:720px;margin:0 auto;padding:20px 16px 48px}nav{display:flex;gap:12px;justify-content:flex-end;font-size:14px}nav a{color:#2e6b34}");
        h.Append("h1{font-size:26px}h2{font-size:18px;margin-top:28px}.draft{background:#fff4d6;border-radius:8px;padding:10px 14px;font-size:14px}");
        h.Append(".summary{background:#fff;border-radius:12px;padding:12px 18px}small{color:#5b6b5d}");
        h.Append("@media(prefers-color-scheme:dark){body{background:#121612;color:#e6ece4}.summary{background:#1d241d}.draft{background:#3f3000}nav a{color:#9ccc9f}}</style></head><body><main><nav>");
        foreach (var (code, name) in new[] { ("en", "English"), ("te", "తెలుగు"), ("hi", "हिन्दी") })
            h.Append(code == lang ? $"<b>{name}</b>" : $"<a href=\"?lang={code}\">{name}</a>");
        h.Append($"</nav><h1>{E(title.For(lang))}</h1><p class=\"draft\">{E(Draft.For(lang))}</p>");
        h.Append($"<p><small>Version {Version}</small></p>");
        if (lang != "en")
        {
            h.Append($"<div class=\"summary\"><p>{E(EnglishBelow.For(lang))}</p><ul>");
            foreach (var line in summary.For(lang).Split('|')) h.Append($"<li>{E(line)}</li>");
            h.Append("</ul></div>");
        }
        foreach (var (heading, text) in sections) h.Append($"<h2>{E(heading)}</h2><p>{E(text)}</p>");
        h.Append("<h2>Contact and grievances</h2><p>");
        h.Append(string.IsNullOrWhiteSpace(contactEmail)
            ? "Use Report a problem in the app (My profile)."
            : $"Write to {E(contactEmail)}, or use Report a problem in the app (My profile). We reply within 7 days.");
        h.Append("</p></main></body></html>");
        return h.ToString();
    }
}
