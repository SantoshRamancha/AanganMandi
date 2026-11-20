using System.Globalization;
using AanganMandi.Domain.Common;
using AanganMandi.Infrastructure.Notifications;

namespace AanganMandi.Infrastructure.Errors;

/// <summary>
/// The words for every <see cref="ApiError"/> code, in English, Telugu and Hindi ({{name}} = a value from the error).
/// The API answers in the language of the request's Accept-Language header, which the app sets to the app language.
/// Add a code here whenever a rule or controller starts using one; a test checks every entry renders in all three.
/// </summary>
public static class ErrorText
{
    public static readonly IReadOnlyDictionary<string, L> All = new Dictionary<string, L>
    {
        // General ----------------------------------------------------------------------------------------
        ["not_found"] = new("Not found. It may have been removed", "కనబడలేదు. దీన్ని తీసివేసి ఉండవచ్చు", "नहीं मिला। शायद इसे हटा दिया गया है"),

        // Login and account ---------------------------------------------------------------------------
        ["phone_invalid"] = new("Enter a 10-digit Indian mobile number", "10 అంకెల భారతీయ మొబైల్ నంబర్ నమోదు చేయండి", "10 अंकों का भारतीय मोबाइल नंबर डालें"),
        ["otp_wait"] = new("Please wait {{seconds}} seconds before asking for a new OTP", "కొత్త OTP అడగడానికి ముందు {{seconds}} సెకన్లు ఆగండి", "नया OTP माँगने से पहले {{seconds}} सेकंड रुकें"),
        ["otp_too_many"] = new("Too many OTPs for this number. Try again in {{minutes}} minutes", "ఈ నంబర్‌కు చాలా OTPలు వచ్చాయి. {{minutes}} నిమిషాల తర్వాత మళ్లీ ప్రయత్నించండి", "इस नंबर पर बहुत सारे OTP हो गए। {{minutes}} मिनट बाद फिर कोशिश करें"),
        ["otp_wrong"] = new("Wrong or expired OTP. Check it, or ask for a new one", "OTP తప్పు లేదా గడువు ముగిసింది. సరిచూడండి, లేదా కొత్తది అడగండి", "OTP गलत है या उसकी समय-सीमा ख़त्म हो गई। जाँचें, या नया माँगें"),
        ["session_expired"] = new("Session expired. Please log in again.", "సెషన్ ముగిసింది. దయచేసి మళ్లీ లాగిన్ అవ్వండి.", "सत्र ख़त्म हो गया। कृपया फिर से लॉग इन करें।"),
        ["too_many_attempts"] = new("Too many login attempts from this network. Try again in 10 minutes", "ఈ నెట్‌వర్క్ నుండి చాలా లాగిన్ ప్రయత్నాలు జరిగాయి. 10 నిమిషాల తర్వాత మళ్లీ ప్రయత్నించండి", "इस नेटवर्क से बहुत सारी लॉगिन कोशिशें हुईं। 10 मिनट बाद फिर कोशिश करें"),
        ["staff_account_delete"] = new("Verifier and admin accounts are removed by an admin. Ask an admin to remove yours", "ధృవీకరణ అధికారి, అడ్మిన్ ఖాతాలను అడ్మిన్ తొలగిస్తారు. మీ ఖాతాను తొలగించమని అడ్మిన్‌ను అడగండి", "सत्यापनकर्ता और एडमिन खाते एडमिन हटाते हैं। अपना खाता हटाने के लिए एडमिन से कहें"),
        ["email_invalid"] = new("Enter a valid email address, like name@example.com", "name@example.com లాంటి సరైన ఈమెయిల్ చిరునామా నమోదు చేయండి", "name@example.com जैसा सही ईमेल पता डालें"),
        ["role_not_allowed"] = new("Only Farmer, Host or Buyer can be chosen in the app", "యాప్‌లో రైతు, యజమాని లేదా కొనుగోలుదారు మాత్రమే ఎంచుకోవచ్చు", "ऐप में सिर्फ़ किसान, मेज़बान या खरीदार चुना जा सकता है"),
        ["language_invalid"] = new("Language must be en, te or hi", "భాష en, te లేదా hi అయి ఉండాలి", "भाषा en, te या hi होनी चाहिए"),

        // Buyers ----------------------------------------------------------------------------------------
        ["location_required"] = new("Capture your location", "మీ లొకేషన్ తీసుకోండి", "अपनी लोकेशन लें"),
        ["radius_invalid"] = new("Choose {{radii}} km", "{{radii}} కి.మీ. ఎంచుకోండి", "{{radii}} किमी चुनें"),

        // Farmer verification -----------------------------------------------------------------------------
        ["farmer_details_required"] = new("Name, village and district are required", "పేరు, గ్రామం, జిల్లా తప్పనిసరి", "नाम, गाँव और ज़िला ज़रूरी हैं"),
        ["farm_size_range"] = new("Farm size must be between 0 and 1000 acres", "పొలం విస్తీర్ణం 0 నుండి 1000 ఎకరాల మధ్య ఉండాలి", "खेत का आकार 0 से 1000 एकड़ के बीच होना चाहिए"),
        ["produce_source_required"] = new("Say whether you grow your own crops", "మీరు సొంతంగా పంటలు పండిస్తారో లేదో చెప్పండి", "बताएँ कि आप अपनी फ़सल ख़ुद उगाते हैं या नहीं"),
        ["crop_name_invalid"] = new("Crop names must be 2 to 30 letters", "పంట పేర్లు 2 నుండి 30 అక్షరాలు ఉండాలి", "फ़सल का नाम 2 से 30 अक्षरों का होना चाहिए"),
        ["crop_unknown"] = new("Unknown crop code", "తెలియని పంట కోడ్", "अनजान फ़सल कोड"),
        ["crops_too_many"] = new("Choose at most {{max}} crops", "గరిష్టంగా {{max}} పంటలు ఎంచుకోండి", "ज़्यादा से ज़्यादा {{max}} फ़सलें चुनें"),
        ["crops_required"] = new("Choose at least one crop you grow or sell", "మీరు పండించే లేదా అమ్మే కనీసం ఒక పంట ఎంచుకోండి", "कम से कम एक फ़सल चुनें जो आप उगाते या बेचते हैं"),
        ["evidence_type_required"] = new("Choose the type of evidence", "ఆధారం రకాన్ని ఎంచుకోండి", "सबूत का प्रकार चुनें"),
        ["details_too_long"] = new("Keep the details under {{max}} characters", "వివరాలు {{max}} అక్షరాల లోపు ఉంచండి", "विवरण {{max}} अक्षरों से कम रखें"),
        ["farmer_id_required"] = new("Enter your Farmer ID number", "మీ రైతు ID నంబర్ నమోదు చేయండి", "अपना किसान ID नंबर डालें"),
        ["fpo_required"] = new("Enter the FPO name, or who referred you", "FPO పేరు, లేదా మిమ్మల్ని సూచించిన వారి పేరు నమోదు చేయండి", "FPO का नाम, या आपको भेजने वाले का नाम डालें"),
        ["referee_required"] = new("Enter the officer's or organisation's name and phone number", "అధికారి లేదా సంస్థ పేరు, ఫోన్ నంబర్ నమోదు చేయండి", "अधिकारी या संस्था का नाम और फ़ोन नंबर डालें"),
        ["photo_too_big"] = new("Photo must be under {{mb}} MB", "ఫోటో {{mb}} MB లోపు ఉండాలి", "फ़ोटो {{mb}} MB से कम होनी चाहिए"),
        ["photo_format"] = new("Only JPEG, PNG or WebP photos are accepted", "JPEG, PNG లేదా WebP ఫోటోలు మాత్రమే అంగీకరిస్తాము", "सिर्फ़ JPEG, PNG या WebP फ़ोटो ली जाती हैं"),
        ["verification_incomplete"] = new("Verification is incomplete", "ధృవీకరణ పూర్తి కాలేదు", "सत्यापन अधूरा है"),
        ["verification_under_review"] = new("Verification is under review", "ధృవీకరణ సమీక్షలో ఉంది", "सत्यापन की जाँच चल रही है"),
        ["farmer_already_verified"] = new("Farmer is already verified", "రైతు ఇప్పటికే ధృవీకరించబడ్డారు", "किसान पहले से सत्यापित हैं"),

        // Trips and bookings (farmer) --------------------------------------------------------------------
        ["not_verified"] = new("Get verified before planning trips", "ప్రయాణాలు ప్లాన్ చేసే ముందు ధృవీకరణ పొందండి", "यात्रा की योजना से पहले सत्यापन करवाएँ"),
        ["trip_date_past"] = new("Choose today or a later date", "ఈరోజు లేదా తర్వాతి తేదీ ఎంచుకోండి", "आज या बाद की तारीख़ चुनें"),
        ["trip_date_too_far"] = new("Trips can be planned up to {{days}} days ahead", "ప్రయాణాలను {{days}} రోజుల ముందు వరకు ప్లాన్ చేయవచ్చు", "यात्रा {{days}} दिन पहले तक की योजना बनाई जा सकती है"),
        ["vehicle_required"] = new("Choose your vehicle", "మీ వాహనాన్ని ఎంచుకోండి", "अपना वाहन चुनें"),
        ["area_too_long"] = new("Keep the area under {{max}} characters", "ప్రాంతం {{max}} అక్షరాల లోపు ఉంచండి", "इलाका {{max}} अक्षरों से कम रखें"),
        ["notes_too_long"] = new("Keep the notes under {{max}} characters", "నోట్స్ {{max}} అక్షరాల లోపు ఉంచండి", "नोट्स {{max}} अक्षरों से कम रखें"),
        ["produce_required"] = new("Add at least one crop you will bring", "మీరు తెచ్చే కనీసం ఒక పంట జోడించండి", "कम से कम एक फ़सल जोड़ें जो आप लाएँगे"),
        ["produce_numbers_invalid"] = new("Quantity and price must be positive numbers", "పరిమాణం, ధర ధనాత్మక సంఖ్యలు అయి ఉండాలి", "मात्रा और दाम सकारात्मक संख्याएँ होनी चाहिए"),
        ["crop_duplicate"] = new("Each crop can be added once", "ప్రతి పంటను ఒకసారి మాత్రమే జోడించవచ్చు", "हर फ़सल एक ही बार जोड़ी जा सकती है"),
        ["trip_locked"] = new("This trip can no longer be changed", "ఈ ప్రయాణాన్ని ఇక మార్చలేరు", "यह यात्रा अब बदली नहीं जा सकती"),
        ["trip_cancel_booking_first"] = new("Cancel the space booking first to change the date or vehicle", "తేదీ లేదా వాహనం మార్చడానికి ముందు స్థలం బుకింగ్ రద్దు చేయండి", "तारीख़ या वाहन बदलने के लिए पहले जगह की बुकिंग रद्द करें"),
        ["trip_already_cancelled"] = new("Trip is already cancelled", "ప్రయాణం ఇప్పటికే రద్దయింది", "यात्रा पहले ही रद्द हो चुकी है"),
        ["trip_not_bookable"] = new("This trip can no longer be booked", "ఈ ప్రయాణానికి ఇక బుక్ చేయలేరు", "इस यात्रा के लिए अब बुकिंग नहीं हो सकती"),
        ["trip_has_booking"] = new("This trip already has a space requested or booked", "ఈ ప్రయాణానికి ఇప్పటికే ఒక స్థలం అభ్యర్థించబడింది లేదా బుక్ అయింది", "इस यात्रा के लिए पहले से एक जगह माँगी या बुक की गई है"),
        ["message_too_long"] = new("Keep the message under {{max}} characters", "సందేశం {{max}} అక్షరాల లోపు ఉంచండి", "संदेश {{max}} अक्षरों से कम रखें"),
        ["space_closed_that_day"] = new("The space is not open on that day", "ఆ రోజు స్థలం తెరిచి ఉండదు", "उस दिन जगह खुली नहीं है"),
        ["vehicle_too_big"] = new("Your vehicle is too big for this space", "మీ వాహనం ఈ స్థలానికి చాలా పెద్దది", "आपका वाहन इस जगह के लिए बहुत बड़ा है"),
        ["space_taken"] = new("Another farmer has this space on that day", "ఆ రోజు ఈ స్థలం మరో రైతుకు ఉంది", "उस दिन यह जगह दूसरे किसान के पास है"),
        ["booking_closed"] = new("This booking is already closed", "ఈ బుకింగ్ ఇప్పటికే ముగిసింది", "यह बुकिंग पहले ही बंद हो चुकी है"),
        ["booking_date_passed"] = new("This booking date has passed", "ఈ బుకింగ్ తేదీ దాటిపోయింది", "इस बुकिंग की तारीख़ निकल चुकी है"),

        // Booking day ---------------------------------------------------------------------------------------
        ["checkin_location_required"] = new("Turn on location to check in", "చెక్ ఇన్ చేయడానికి లొకేషన్ ఆన్ చేయండి", "चेक इन करने के लिए लोकेशन चालू करें"),
        ["checkin_not_confirmed"] = new("Only a confirmed booking can be checked in", "నిర్ధారించిన బుకింగ్‌కే చెక్ ఇన్ చేయవచ్చు", "सिर्फ़ पक्की बुकिंग पर चेक इन हो सकता है"),
        ["already_checked_in"] = new("You already checked in", "మీరు ఇప్పటికే చెక్ ఇన్ చేశారు", "आप पहले ही चेक इन कर चुके हैं"),
        ["checkin_future_day"] = new("Check in on the day of your booking", "మీ బుకింగ్ రోజున చెక్ ఇన్ చేయండి", "अपनी बुकिंग वाले दिन चेक इन करें"),
        ["checkin_day_passed"] = new("This booking's day has passed", "ఈ బుకింగ్ రోజు దాటిపోయింది", "इस बुकिंग का दिन निकल चुका है"),
        ["checkin_not_open"] = new("Check-in opens at {{time}}", "చెక్ ఇన్ {{time}}కు మొదలవుతుంది", "चेक इन {{time}} बजे खुलेगा"),
        ["slot_ended"] = new("Your slot has ended", "మీ స్లాట్ ముగిసింది", "आपका स्लॉट ख़त्म हो गया"),
        ["too_far"] = new("You are about {{meters}} m from the space. Check in when you reach it", "మీరు స్థలానికి సుమారు {{meters}} మీ. దూరంలో ఉన్నారు. చేరుకున్నాక చెక్ ఇన్ చేయండి", "आप जगह से लगभग {{meters}} मीटर दूर हैं। पहुँचकर चेक इन करें"),
        ["no_show_checked_in"] = new("The farmer checked in for this booking", "ఈ బుకింగ్‌కు రైతు చెక్ ఇన్ చేశారు", "इस बुकिंग के लिए किसान ने चेक इन किया है"),
        ["no_show_too_early"] = new("You can mark this once the slot has ended", "స్లాట్ ముగిసిన తర్వాతే దీన్ని నమోదు చేయవచ్చు", "स्लॉट ख़त्म होने के बाद ही इसे दर्ज कर सकते हैं"),
        ["share_not_allowed"] = new("Only a confirmed booking that is not over can be shared", "ముగియని నిర్ధారించిన బుకింగ్‌ను మాత్రమే పంచుకోవచ్చు", "सिर्फ़ ऐसी पक्की बुकिंग शेयर हो सकती है जो ख़त्म नहीं हुई"),

        // Bookings (host) ----------------------------------------------------------------------------------
        ["request_answered"] = new("This request is already answered", "ఈ అభ్యర్థనకు ఇప్పటికే జవాబిచ్చారు", "इस अनुरोध का जवाब पहले ही दिया जा चुका है"),
        ["date_passed"] = new("This date has passed", "ఈ తేదీ దాటిపోయింది", "यह तारीख़ निकल चुकी है"),
        ["space_not_live"] = new("The space is not live", "స్థలం లైవ్‌లో లేదు", "जगह लाइव नहीं है"),
        ["farmer_already_confirmed"] = new("You already confirmed another farmer for this day", "ఈ రోజుకు మీరు ఇప్పటికే మరో రైతును నిర్ధారించారు", "इस दिन के लिए आप पहले ही दूसरे किसान की पुष्टि कर चुके हैं"),
        ["cancel_not_confirmed"] = new("Only a confirmed booking can be cancelled", "నిర్ధారించిన బుకింగ్‌ను మాత్రమే రద్దు చేయవచ్చు", "सिर्फ़ पक्की बुकिंग रद्द की जा सकती है"),
        ["reason_required_farmer"] = new("Give the farmer a reason", "రైతుకు కారణం చెప్పండి", "किसान को कारण बताएँ"),
        ["reason_too_long"] = new("Keep the reason under {{max}} characters", "కారణం {{max}} అక్షరాల లోపు ఉంచండి", "कारण {{max}} अक्षरों से कम रखें"),

        // Spaces ----------------------------------------------------------------------------------------------
        ["space_name_required"] = new("Give the space a name", "స్థలానికి పేరు పెట్టండి", "जगह को नाम दें"),
        ["space_address_required"] = new("Address and locality are required", "చిరునామా, ప్రాంతం తప్పనిసరి", "पता और इलाका ज़रूरी हैं"),
        ["space_location_required"] = new("Capture the space location", "స్థలం లొకేషన్ తీసుకోండి", "जगह की लोकेशन लें"),
        ["space_area_range"] = new("Usable area must be between 50 and 100,000 sq ft", "ఉపయోగించే విస్తీర్ణం 50 నుండి 1,00,000 చ.అ. మధ్య ఉండాలి", "इस्तेमाल लायक जगह 50 से 1,00,000 वर्ग फ़ुट के बीच होनी चाहिए"),
        ["space_fee_required"] = new("Enter a fee per slot, or mark the space as free", "ఒక్కో స్లాట్‌కు రుసుము నమోదు చేయండి, లేదా స్థలాన్ని ఉచితంగా గుర్తించండి", "हर स्लॉट का शुल्क डालें, या जगह को मुफ़्त चुनें"),
        ["space_days_required"] = new("Choose at least one day", "కనీసం ఒక రోజు ఎంచుకోండి", "कम से कम एक दिन चुनें"),
        ["space_slot_length"] = new("Each slot must be 2 to 6 hours long", "ప్రతి స్లాట్ 2 నుండి 6 గంటలు ఉండాలి", "हर स्लॉट 2 से 6 घंटे का होना चाहिए"),
        ["space_under_review"] = new("Space is under review", "స్థలం సమీక్షలో ఉంది", "जगह की जाँच चल रही है"),
        ["space_max_photos"] = new("A space can have at most {{max}} photos", "ఒక స్థలానికి గరిష్టంగా {{max}} ఫోటోలు ఉండవచ్చు", "एक जगह की ज़्यादा से ज़्यादा {{max}} फ़ोटो हो सकती हैं"),
        ["space_already_submitted"] = new("Space is already submitted", "స్థలం ఇప్పటికే సమర్పించబడింది", "जगह पहले ही जमा हो चुकी है"),
        ["space_min_photos"] = new("Add at least {{min}} photos of the space", "స్థలానికి కనీసం {{min}} ఫోటోలు జోడించండి", "जगह की कम से कम {{min}} फ़ोटो जोड़ें"),
        ["space_proof_required"] = new("Add a photo of your ownership, rent document or society letter", "మీ యాజమాన్యం, అద్దె పత్రం లేదా సొసైటీ లేఖ ఫోటో జోడించండి", "अपने मालिकाना हक़, किराए के कागज़ या सोसाइटी पत्र की फ़ोटो जोड़ें"),
        ["space_files_locked"] = new("This space is approved, so its photos and proof can no longer be changed", "ఈ స్థలం ఆమోదించబడింది, కాబట్టి దాని ఫోటోలు, రుజువు ఇక మార్చలేరు", "यह जगह मंज़ूर हो चुकी है, इसलिए इसकी फ़ोटो और सबूत अब नहीं बदले जा सकते"),

        // Operations ----------------------------------------------------------------------------------------
        ["farmer_other_verifier"] = new("This farmer is assigned to another verifier", "ఈ రైతు మరో ధృవీకరణ అధికారికి కేటాయించబడ్డారు", "यह किसान दूसरे सत्यापनकर्ता को सौंपे गए हैं"),
        ["farmer_not_waiting"] = new("Only farmers waiting for review can be assigned", "సమీక్ష కోసం వేచి ఉన్న రైతులను మాత్రమే కేటాయించవచ్చు", "सिर्फ़ जाँच का इंतज़ार कर रहे किसान ही सौंपे जा सकते हैं"),
        ["verifier_invalid"] = new("Choose an active verifier other than the farmer", "రైతు కాకుండా మరో క్రియాశీల ధృవీకరణ అధికారిని ఎంచుకోండి", "किसान के अलावा कोई सक्रिय सत्यापनकर्ता चुनें"),
        ["reject_reason_farmer"] = new("Give a reason to reject; the farmer sees it", "తిరస్కరించడానికి కారణం ఇవ్వండి; రైతు దాన్ని చూస్తారు", "अस्वीकार करने का कारण दें; किसान इसे देखेंगे"),
        ["reject_reason_host"] = new("Give a reason to reject; the host sees it", "తిరస్కరించడానికి కారణం ఇవ్వండి; యజమాని దాన్ని చూస్తారు", "अस्वीकार करने का कारण दें; मेज़बान इसे देखेंगे"),
        ["farmer_already_reviewed"] = new("This farmer was already reviewed", "ఈ రైతును ఇప్పటికే సమీక్షించారు", "इस किसान की जाँच पहले ही हो चुकी है"),
        ["space_already_reviewed"] = new("This space was already reviewed", "ఈ స్థలాన్ని ఇప్పటికే సమీక్షించారు", "इस जगह की जाँच पहले ही हो चुकी है"),
        ["verifier_name_required"] = new("Enter the verifier's name", "ధృవీకరణ అధికారి పేరు నమోదు చేయండి", "सत्यापनकर्ता का नाम डालें"),
        ["verifier_exists"] = new("{{phone}} is already a verifier", "{{phone}} ఇప్పటికే ధృవీకరణ అధికారి", "{{phone}} पहले से सत्यापनकर्ता हैं"),

        // Problem reports -------------------------------------------------------------------------------------
        ["report_category_required"] = new("Choose what the problem is about", "సమస్య దేని గురించో ఎంచుకోండి", "चुनें कि समस्या किस बारे में है"),
        ["report_message_short"] = new("Describe the problem in at least {{min}} characters", "సమస్యను కనీసం {{min}} అక్షరాల్లో వివరించండి", "समस्या कम से कम {{min}} अक्षरों में बताएँ"),
        ["report_message_long"] = new("Keep the description under {{max}} characters", "వివరణను {{max}} అక్షరాల లోపు ఉంచండి", "विवरण {{max}} अक्षरों से कम रखें"),
        ["report_too_many"] = new("You have sent many reports today. Please try again tomorrow", "ఈరోజు మీరు చాలా రిపోర్టులు పంపారు. దయచేసి రేపు మళ్లీ ప్రయత్నించండి", "आज आपने बहुत सारी रिपोर्ट भेजी हैं। कृपया कल फिर कोशिश करें"),
        ["report_already_resolved"] = new("This report is already resolved", "ఈ రిపోర్ట్ ఇప్పటికే పరిష్కరించబడింది", "यह रिपोर्ट पहले ही हल हो चुकी है"),
        ["report_resolution_required"] = new("Write what was done; the person who reported sees it", "ఏమి చేశారో రాయండి; రిపోర్ట్ చేసిన వారు దాన్ని చూస్తారు", "लिखें कि क्या किया गया; रिपोर्ट करने वाले इसे देखेंगे"),

        // Ratings and no-shows ----------------------------------------------------------------------------------
        ["rating_not_confirmed"] = new("Only a confirmed stall can be rated", "నిర్ధారించిన స్టాల్‌కు మాత్రమే రేటింగ్ ఇవ్వవచ్చు", "सिर्फ़ पक्के स्टॉल को ही रेटिंग दी जा सकती है"),
        ["rating_too_early"] = new("You can rate once the stall is over", "స్టాల్ ముగిసిన తర్వాత రేటింగ్ ఇవ్వవచ్చు", "स्टॉल ख़त्म होने के बाद रेटिंग दे सकते हैं"),
        ["rating_too_late"] = new("Stalls can be rated for {{days}} days only", "స్టాల్‌లకు {{days}} రోజుల వరకే రేటింగ్ ఇవ్వవచ్చు", "स्टॉल को सिर्फ़ {{days}} दिन तक रेटिंग दी जा सकती है"),
        ["rating_no_show"] = new("This booking was marked as not attended, so it cannot be rated", "ఈ బుకింగ్‌కు రాలేదని నమోదైంది, కాబట్టి రేటింగ్ ఇవ్వలేరు", "इस बुकिंग में न आना दर्ज है, इसलिए रेटिंग नहीं दे सकते"),
        ["rating_stars"] = new("Choose 1 to 5 stars", "1 నుండి 5 నక్షత్రాలు ఎంచుకోండి", "1 से 5 सितारे चुनें"),
        ["rating_comment_long"] = new("Keep the comment under {{max}} characters", "వ్యాఖ్యను {{max}} అక్షరాల లోపు ఉంచండి", "टिप्पणी {{max}} अक्षरों से कम रखें"),
        ["rating_already_given"] = new("You have already rated this stall", "మీరు ఈ స్టాల్‌కు ఇప్పటికే రేటింగ్ ఇచ్చారు", "आप इस स्टॉल को पहले ही रेटिंग दे चुके हैं"),
        ["too_many_no_shows"] = new("You missed {{count}} booked stalls in the last {{days}} days, so you cannot request new slots for now. If a no-show was wrong, report a problem", "గత {{days}} రోజుల్లో మీరు {{count}} బుక్ చేసిన స్టాల్‌లకు రాలేదు, కాబట్టి ప్రస్తుతం కొత్త స్లాట్‌లు అడగలేరు. రాలేదని తప్పుగా నమోదైతే, సమస్యను రిపోర్ట్ చేయండి", "पिछले {{days}} दिनों में आप {{count}} बुक किए स्टॉल पर नहीं आए, इसलिए अभी नए स्लॉट नहीं माँग सकते। अगर न आना ग़लत दर्ज हुआ है, तो समस्या की रिपोर्ट करें"),
        ["no_show_not_marked"] = new("This booking is not marked as a no-show", "ఈ బుకింగ్‌కు రాలేదని నమోదు కాలేదు", "इस बुकिंग में न आना दर्ज नहीं है"),
        ["buyer_area_required"] = new("Save your area first", "ముందుగా మీ ప్రాంతాన్ని సేవ్ చేయండి", "पहले अपना इलाक़ा सेव करें"),
        ["block_date_past"] = new("You cannot block a day that has passed", "గడిచిన రోజును బ్లాక్ చేయలేరు", "बीता हुआ दिन ब्लॉक नहीं कर सकते"),
        ["block_date_too_far"] = new("You can block days up to {{days}} days ahead", "{{days}} రోజుల ముందు వరకు మాత్రమే బ్లాక్ చేయగలరు", "आप {{days}} दिन आगे तक के दिन ब्लॉक कर सकते हैं"),
        ["block_note_long"] = new("Keep the note under {{max}} characters", "నోట్‌ను {{max}} అక్షరాల లోపు ఉంచండి", "नोट {{max}} अक्षरों से कम रखें"),
        ["block_date_booked"] = new("A farmer is confirmed for that day. Cancel that booking first, so the farmer is told why", "ఆ రోజు ఒక రైతు నిర్ధారించబడ్డారు. రైతుకు కారణం తెలిసేలా ముందుగా ఆ బుకింగ్‌ను రద్దు చేయండి", "उस दिन एक किसान पक्का है। पहले वह बुकिंग रद्द करें, ताकि किसान को कारण पता चले"),
        ["block_range_order"] = new("The last day must be on or after the first day", "చివరి రోజు మొదటి రోజు లేదా ఆ తర్వాత ఉండాలి", "आख़िरी दिन पहले दिन या उसके बाद का होना चाहिए"),
        ["block_range_closed"] = new("Your space is not open on any of those days", "ఆ రోజుల్లో ఏ రోజూ మీ స్థలం తెరిచి ఉండదు", "उन दिनों में से किसी भी दिन आपकी जगह खुली नहीं है"),
        ["summary_period"] = new("Choose a period of {{days}} days", "{{days}} రోజుల వ్యవధిని ఎంచుకోండి", "{{days}} दिनों की अवधि चुनें"),
        ["analytics_period"] = new("Choose a period of {{days}} days", "{{days}} రోజుల వ్యవధిని ఎంచుకోండి", "{{days}} दिनों की अवधि चुनें"),

        // Consent ---------------------------------------------------------------------------------------------
        ["consent_version_outdated"] = new("Please read and accept the latest terms and privacy policy", "దయచేసి తాజా నిబంధనలు, గోప్యతా విధానం చదివి అంగీకరించండి", "कृपया नई शर्तें और गोपनीयता नीति पढ़कर स्वीकार करें"),
        ["consent_required"] = new("Please accept the terms and privacy policy to continue", "కొనసాగడానికి దయచేసి నిబంధనలు, గోప్యతా విధానాన్ని అంగీకరించండి", "आगे बढ़ने के लिए कृपया शर्तें और गोपनीयता नीति स्वीकार करें"),
    };

    /// <summary>
    /// The error in <paramref name="lang"/> (en, te or hi; anything else is English), with its values filled in.
    /// An unknown code falls back to the code itself, so a missing entry is visible rather than silent.
    /// </summary>
    public static string Render(ApiError error, string lang)
    {
        if (!All.TryGetValue(error.Code, out var text)) return error.Code;
        var s = text.For(lang);
        foreach (var (key, value) in error.Args)
            s = s.Replace("{{" + key + "}}", Convert.ToString(value, CultureInfo.InvariantCulture));
        return s;
    }

    /// <summary>"te-IN,te;q=0.9" → "te"; the first of en/te/hi in the header, else English.</summary>
    public static string LanguageOf(string? acceptLanguage)
    {
        foreach (var part in (acceptLanguage ?? "").Split(','))
        {
            var primary = part.Split(';')[0].Trim().Split('-')[0].ToLowerInvariant();
            if (primary is "en" or "te" or "hi") return primary;
        }
        return "en";
    }
}
