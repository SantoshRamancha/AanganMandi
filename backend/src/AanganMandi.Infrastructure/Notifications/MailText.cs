namespace AanganMandi.Infrastructure.Notifications;

/// <summary>One text in the three app languages. Placeholders like {{name}} are filled (HTML-encoded) when rendered.</summary>
public sealed record L(string En, string Te, string Hi)
{
    public string For(string lang) => lang switch { "te" => Te, "hi" => Hi, _ => En };
}

/// <summary>An email's own text. <see cref="Body"/> may hold several paragraphs separated by a blank line.</summary>
public sealed record MailTemplate(string Key, L Subject, L Heading, L Body);

/// <summary>
/// All email wording, in English, Telugu and Hindi. Kept short and plain: many farmers read on a phone, in their own language.
/// </summary>
public static class MailText
{
    // Shared parts of every email -------------------------------------------------------------

    public static readonly L Greeting = new("Namaste {{name}},", "నమస్కారం {{name}},", "नमस्ते {{name}},");
    public static readonly L GreetingNoName = new("Namaste,", "నమస్కారం,", "नमस्ते,");
    public static readonly L OpenApp = new("Open Aangan Mandi", "ఆంగన్ మండి తెరవండి", "आंगन मंडी खोलें");
    public static readonly L Footer = new(
        "You get this email because your email address is saved in your Aangan Mandi profile. To stop these emails, remove it in My profile.",
        "మీ ఈమెయిల్ చిరునామా మీ ఆంగన్ మండి ప్రొఫైల్‌లో ఉన్నందున మీకు ఈ ఈమెయిల్ వచ్చింది. ఇవి ఆపడానికి, నా ప్రొఫైల్‌లో దాన్ని తీసివేయండి.",
        "आपको यह ईमेल इसलिए मिला क्योंकि आपका ईमेल पता आपकी आंगन मंडी प्रोफ़ाइल में सेव है। ये ईमेल बंद करने के लिए उसे मेरी प्रोफ़ाइल में हटाएँ।");
    public static readonly L ReasonTitle = new("Reason", "కారణం", "कारण");
    public static readonly L MessageTitle = new("Message from the farmer", "రైతు నుండి సందేశం", "किसान का संदेश");

    // Labels for the details table -------------------------------------------------------------

    public static readonly L Date = new("Date", "తేదీ", "तारीख");
    public static readonly L Time = new("Time", "సమయం", "समय");
    public static readonly L Space = new("Space", "స్థలం", "जगह");
    public static readonly L Locality = new("Area", "ప్రాంతం", "इलाका");
    public static readonly L Address = new("Address", "చిరునామా", "पता");
    public static readonly L Host = new("Host", "యజమాని", "मेज़बान");
    public static readonly L Farmer = new("Farmer", "రైతు", "किसान");
    public static readonly L Phone = new("Phone", "ఫోన్", "फ़ोन");
    public static readonly L Village = new("Village", "గ్రామం", "गाँव");
    public static readonly L Fee = new("Fee", "రుసుము", "शुल्क");
    public static readonly L Vehicle = new("Vehicle", "వాహనం", "वाहन");
    public static readonly L Crops = new("Bringing", "తెచ్చేవి", "ला रहे हैं");
    public static readonly L Submitted = new("Submitted", "సమర్పించినది", "जमा किया");
    public static readonly L Free = new("Free", "ఉచితం", "मुफ़्त");
    public static readonly L PerSlot = new("₹{{fee}} per slot, paid to the host at the space",
        "ఒక్కో స్లాట్‌కు ₹{{fee}}, స్థలం వద్ద యజమానికి చెల్లించాలి", "₹{{fee}} प्रति स्लॉट, जगह पर मेज़बान को देना है");
    public static readonly L SlotTaken = new("The host confirmed another farmer for this day.",
        "ఈ రోజుకు యజమాని మరో రైతును నిర్ధారించారు.", "मेज़बान ने इस दिन के लिए दूसरे किसान की पुष्टि कर दी।");

    public static L VehicleName(string v) => v switch
    {
        "TwoWheeler" => new("Two-wheeler", "టూ-వీలర్", "दोपहिया"),
        "Auto" => new("Auto", "ఆటో", "ऑटो"),
        "MiniTruck" => new("Mini-truck", "మినీ ట్రక్", "मिनी ट्रक"),
        _ => new("Tractor", "ట్రాక్టర్", "ट्रैक्टर"),
    };

    // Farmer verification ----------------------------------------------------------------------

    public static readonly MailTemplate FarmerSubmitted = new("farmer-submitted",
        new("We received your verification", "మీ ధృవీకరణ మాకు అందింది", "हमें आपका सत्यापन मिल गया"),
        new("We received your verification", "మీ ధృవీకరణ మాకు అందింది", "हमें आपका सत्यापन मिल गया"),
        new("Thank you. A verifier will check your farming details and proof, usually within 2 working days.\n\nWe will email you as soon as it is done.",
            "ధన్యవాదాలు. ధృవీకరణ అధికారి మీ వ్యవసాయ వివరాలు మరియు రుజువును సాధారణంగా 2 పని దినాల్లో తనిఖీ చేస్తారు.\n\nపూర్తవగానే మీకు ఈమెయిల్ చేస్తాము.",
            "धन्यवाद। सत्यापनकर्ता आपकी खेती का विवरण और सबूत आमतौर पर 2 कामकाजी दिनों में जाँचेंगे।\n\nहोते ही हम आपको ईमेल करेंगे।"));

    public static readonly MailTemplate FarmerToVerify = new("farmer-to-verify",
        new("New farmer to verify: {{farmer}}", "ధృవీకరించాల్సిన కొత్త రైతు: {{farmer}}", "सत्यापन के लिए नए किसान: {{farmer}}"),
        new("A farmer is waiting for you", "ఒక రైతు మీ కోసం వేచి ఉన్నారు", "एक किसान आपका इंतज़ार कर रहे हैं"),
        new("{{farmer}} submitted their verification and it is assigned to you. Please review it in the Operations screen of the app.",
            "{{farmer}} తమ ధృవీకరణను సమర్పించారు, అది మీకు కేటాయించబడింది. దయచేసి యాప్‌లోని కార్యకలాపాల స్క్రీన్‌లో సమీక్షించండి.",
            "{{farmer}} ने अपना सत्यापन जमा किया है और यह आपको सौंपा गया है। कृपया ऐप की ऑपरेशंस स्क्रीन में इसकी जाँच करें।"));

    public static readonly MailTemplate FarmerApproved = new("farmer-approved",
        new("You are a verified farmer", "మీరు ధృవీకరించిన రైతు", "आप सत्यापित किसान हैं"),
        new("Congratulations, you are verified!", "అభినందనలు, మీరు ధృవీకరించబడ్డారు!", "बधाई हो, आप सत्यापित हैं!"),
        new("Your farming proof was checked and approved.\n\nYou can now plan your selling trips and book a space near buyers in the city.",
            "మీ వ్యవసాయ రుజువు తనిఖీ చేసి ఆమోదించబడింది.\n\nఇప్పుడు మీరు అమ్మకం ప్రయాణాలు ప్లాన్ చేసి, నగరంలో కొనుగోలుదారుల దగ్గర స్థలం బుక్ చేయవచ్చు.",
            "आपकी खेती का सबूत जाँचा गया और मंज़ूर हो गया।\n\nअब आप बिक्री की यात्राओं की योजना बना सकते हैं और शहर में खरीदारों के पास जगह बुक कर सकते हैं।"));

    public static readonly MailTemplate FarmerRejected = new("farmer-rejected",
        new("Your verification needs changes", "మీ ధృవీకరణలో మార్పులు కావాలి", "आपके सत्यापन में बदलाव चाहिए"),
        new("Your verification needs changes", "మీ ధృవీకరణలో మార్పులు కావాలి", "आपके सत्यापन में बदलाव चाहिए"),
        new("A verifier could not approve your verification yet. Please read the reason below, fix it in the app and submit again.",
            "ధృవీకరణ అధికారి ఇంకా మీ ధృవీకరణను ఆమోదించలేకపోయారు. దయచేసి కింది కారణం చదివి, యాప్‌లో సరిచేసి మళ్లీ సమర్పించండి.",
            "सत्यापनकर्ता अभी आपका सत्यापन मंज़ूर नहीं कर पाए। कृपया नीचे दिया कारण पढ़ें, ऐप में ठीक करें और फिर से जमा करें।"));

    public static readonly MailTemplate VerifierAdded = new("verifier-added",
        new("You are now a verifier on Aangan Mandi", "మీరు ఇప్పుడు ఆంగన్ మండిలో ధృవీకరణ అధికారి", "अब आप आंगन मंडी पर सत्यापनकर्ता हैं"),
        new("Welcome to the verification team", "ధృవీకరణ బృందానికి స్వాగతం", "सत्यापन टीम में आपका स्वागत है"),
        new("{{admin}} added you as a verifier. Sign in to the Aangan Mandi app with your mobile number {{phone}} and an OTP.\n\nFarmers who submit their verification will be assigned to you, and you will get an email for each one.",
            "{{admin}} మిమ్మల్ని ధృవీకరణ అధికారిగా జోడించారు. మీ మొబైల్ నంబర్ {{phone}} మరియు OTPతో ఆంగన్ మండి యాప్‌లో లాగిన్ అవ్వండి.\n\nధృవీకరణ సమర్పించిన రైతులు మీకు కేటాయించబడతారు, ప్రతి ఒక్కరి కోసం మీకు ఈమెయిల్ వస్తుంది.",
            "{{admin}} ने आपको सत्यापनकर्ता के रूप में जोड़ा है। अपने मोबाइल नंबर {{phone}} और OTP से आंगन मंडी ऐप में लॉग इन करें।\n\nसत्यापन जमा करने वाले किसान आपको सौंपे जाएँगे, और हर एक के लिए आपको ईमेल मिलेगा।"));

    // Spaces --------------------------------------------------------------------------------------

    public static readonly MailTemplate SpaceSubmitted = new("space-submitted",
        new("We received your space: {{space}}", "మీ స్థలం మాకు అందింది: {{space}}", "हमें आपकी जगह मिल गई: {{space}}"),
        new("We received your space", "మీ స్థలం మాకు అందింది", "हमें आपकी जगह मिल गई"),
        new("Thank you for listing {{space}}. Our team will check the photos, location and proof, usually within 2 working days.\n\nWe will email you when it is live.",
            "{{space}}ను జాబితాలో పెట్టినందుకు ధన్యవాదాలు. మా బృందం ఫోటోలు, లొకేషన్, రుజువును సాధారణంగా 2 పని దినాల్లో తనిఖీ చేస్తుంది.\n\nలైవ్ అయినప్పుడు మీకు ఈమెయిల్ చేస్తాము.",
            "{{space}} जोड़ने के लिए धन्यवाद। हमारी टीम फ़ोटो, लोकेशन और सबूत आमतौर पर 2 कामकाजी दिनों में जाँचेगी।\n\nलाइव होने पर हम आपको ईमेल करेंगे।"));

    public static readonly MailTemplate SpaceToReview = new("space-to-review",
        new("New space to approve: {{space}}", "ఆమోదించాల్సిన కొత్త స్థలం: {{space}}", "मंज़ूरी के लिए नई जगह: {{space}}"),
        new("A space is waiting for approval", "ఒక స్థలం ఆమోదం కోసం వేచి ఉంది", "एक जगह मंज़ूरी का इंतज़ार कर रही है"),
        new("{{host}} submitted {{space}} in {{locality}}. Please review it in the Operations screen of the app.",
            "{{host}} {{locality}}లో {{space}}ను సమర్పించారు. దయచేసి యాప్‌లోని కార్యకలాపాల స్క్రీన్‌లో సమీక్షించండి.",
            "{{host}} ने {{locality}} में {{space}} जमा की है। कृपया ऐप की ऑपरेशंस स्क्रीन में इसकी जाँच करें।"));

    public static readonly MailTemplate SpaceApproved = new("space-approved",
        new("Your space is live: {{space}}", "మీ స్థలం లైవ్ అయింది: {{space}}", "आपकी जगह लाइव है: {{space}}"),
        new("Your space is live", "మీ స్థలం లైవ్ అయింది", "आपकी जगह लाइव है"),
        new("{{space}} is approved. Verified farmers can now request it for their selling days.\n\nYou will get an email for each request, and you choose whom to accept.",
            "{{space}} ఆమోదించబడింది. ధృవీకరించిన రైతులు ఇప్పుడు తమ అమ్మకం రోజుల కోసం దీన్ని అభ్యర్థించవచ్చు.\n\nప్రతి అభ్యర్థనకు మీకు ఈమెయిల్ వస్తుంది, ఎవరిని అంగీకరించాలో మీరే ఎంచుకుంటారు.",
            "{{space}} मंज़ूर हो गई है। सत्यापित किसान अब अपने बिक्री के दिनों के लिए इसे माँग सकते हैं।\n\nहर अनुरोध के लिए आपको ईमेल मिलेगा, और किसे स्वीकार करना है यह आप चुनेंगे।"));

    public static readonly MailTemplate SpaceRejected = new("space-rejected",
        new("Your space needs changes: {{space}}", "మీ స్థలంలో మార్పులు కావాలి: {{space}}", "आपकी जगह में बदलाव चाहिए: {{space}}"),
        new("Your space needs changes", "మీ స్థలంలో మార్పులు కావాలి", "आपकी जगह में बदलाव चाहिए"),
        new("Our team could not approve {{space}} yet. Please read the reason below, fix it in the app and submit again.",
            "మా బృందం ఇంకా {{space}}ను ఆమోదించలేకపోయింది. దయచేసి కింది కారణం చదివి, యాప్‌లో సరిచేసి మళ్లీ సమర్పించండి.",
            "हमारी टीम अभी {{space}} को मंज़ूर नहीं कर पाई। कृपया नीचे दिया कारण पढ़ें, ऐप में ठीक करें और फिर से जमा करें।"));

    // Bookings ------------------------------------------------------------------------------------

    public static readonly MailTemplate BookingRequested = new("booking-requested",
        new("New request for {{space}} on {{date}}", "{{date}} న {{space}} కోసం కొత్త అభ్యర్థన", "{{date}} को {{space}} के लिए नया अनुरोध"),
        new("A farmer wants your space", "ఒక రైతు మీ స్థలం కావాలనుకుంటున్నారు", "एक किसान आपकी जगह चाहते हैं"),
        new("{{farmer}}, a verified farmer, asked for {{space}} on {{date}}. Please accept or decline the request in the app.",
            "ధృవీకరించిన రైతు {{farmer}} {{date}} న {{space}} అడిగారు. దయచేసి యాప్‌లో అభ్యర్థనను అంగీకరించండి లేదా తిరస్కరించండి.",
            "सत्यापित किसान {{farmer}} ने {{date}} के लिए {{space}} माँगी है। कृपया ऐप में अनुरोध स्वीकार या अस्वीकार करें।"));

    public static readonly MailTemplate BookingAccepted = new("booking-accepted",
        new("Space booked: {{space}} on {{date}}", "స్థలం బుక్ అయింది: {{date}} న {{space}}", "जगह बुक हुई: {{date}} को {{space}}"),
        new("Your space is booked", "మీ స్థలం బుక్ అయింది", "आपकी जगह बुक हो गई"),
        new("{{host}} accepted your request. Here is everything you need for the day.",
            "{{host}} మీ అభ్యర్థనను అంగీకరించారు. ఆ రోజుకు కావాల్సిన వివరాలన్నీ ఇవి.",
            "{{host}} ने आपका अनुरोध स्वीकार कर लिया। उस दिन के लिए ज़रूरी सारी जानकारी यह है।"));

    public static readonly MailTemplate BookingDeclined = new("booking-declined",
        new("Request declined: {{space}} on {{date}}", "అభ్యర్థన తిరస్కరించబడింది: {{date}} న {{space}}", "अनुरोध अस्वीकार: {{date}} को {{space}}"),
        new("Your request was declined", "మీ అభ్యర్థన తిరస్కరించబడింది", "आपका अनुरोध अस्वीकार हुआ"),
        new("{{host}} could not give you {{space}} on {{date}}. You can request another space for this trip in the app.",
            "{{host}} మీకు {{date}} న {{space}} ఇవ్వలేకపోయారు. యాప్‌లో ఈ ప్రయాణానికి మరో స్థలం అభ్యర్థించవచ్చు.",
            "{{host}} आपको {{date}} को {{space}} नहीं दे पाए। आप ऐप में इस यात्रा के लिए दूसरी जगह माँग सकते हैं।"));

    public static readonly MailTemplate BookingCancelledByHost = new("booking-cancelled-by-host",
        new("Booking cancelled: {{space}} on {{date}}", "బుకింగ్ రద్దయింది: {{date}} న {{space}}", "बुकिंग रद्द: {{date}} को {{space}}"),
        new("Your booking was cancelled", "మీ బుకింగ్ రద్దయింది", "आपकी बुकिंग रद्द हो गई"),
        new("{{host}} had to cancel your booking of {{space}} on {{date}}. You can find another space for this trip in the app.",
            "{{host}} {{date}} న {{space}} బుకింగ్‌ను రద్దు చేయాల్సి వచ్చింది. యాప్‌లో ఈ ప్రయాణానికి మరో స్థలం వెతకవచ్చు.",
            "{{host}} को {{date}} की {{space}} की बुकिंग रद्द करनी पड़ी। आप ऐप में इस यात्रा के लिए दूसरी जगह खोज सकते हैं।"));

    public static readonly MailTemplate BookingCancelledByFarmer = new("booking-cancelled-by-farmer",
        new("Cancelled: {{space}} on {{date}}", "రద్దయింది: {{date}} న {{space}}", "रद्द: {{date}} को {{space}}"),
        new("A farmer cancelled", "ఒక రైతు రద్దు చేశారు", "एक किसान ने रद्द किया"),
        new("{{farmer}} cancelled their request for {{space}} on {{date}}. The day is free again for other farmers.",
            "{{farmer}} {{date}} న {{space}} కోసం తమ అభ్యర్థనను రద్దు చేశారు. ఆ రోజు మళ్లీ ఇతర రైతులకు ఖాళీగా ఉంది.",
            "{{farmer}} ने {{date}} के लिए {{space}} का अपना अनुरोध रद्द कर दिया। वह दिन फिर से दूसरे किसानों के लिए खाली है।"));

    /// <summary>Every template, for tests and an admin preview.</summary>
    public static readonly MailTemplate[] All =
    [
        FarmerSubmitted, FarmerToVerify, FarmerApproved, FarmerRejected, VerifierAdded,
        SpaceSubmitted, SpaceToReview, SpaceApproved, SpaceRejected,
        BookingRequested, BookingAccepted, BookingDeclined, BookingCancelledByHost, BookingCancelledByFarmer,
    ];
}
