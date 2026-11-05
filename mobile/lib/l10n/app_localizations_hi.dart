// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'आंगन मंडी';

  @override
  String get chooseLanguage => 'अपनी भाषा चुनें';

  @override
  String get continueButton => 'आगे बढ़ें';

  @override
  String get enterPhone => 'अपना मोबाइल नंबर दर्ज करें';

  @override
  String get sendOtp => 'OTP भेजें';

  @override
  String enterOtp(String phone) {
    return '$phone पर भेजा गया 6 अंकों का OTP दर्ज करें';
  }

  @override
  String get verify => 'सत्यापित करें';

  @override
  String testOtp(String code) {
    return 'टेस्ट OTP: $code';
  }

  @override
  String get testOtpHint => 'टेस्टिंग मोड: SMS नहीं भेजा जाता';

  @override
  String get useTestOtp => 'भर दें';

  @override
  String get whoAreYou => 'आप आंगन मंडी का उपयोग कैसे करेंगे?';

  @override
  String get roleFarmer => 'मैं किसान हूँ';

  @override
  String get roleFarmerHint => 'अपनी उपज खरीदारों के पास बेचें';

  @override
  String get roleHost => 'मेरे पास जगह है';

  @override
  String get roleHostHint => 'कुछ घंटों के लिए अपना आंगन दें';

  @override
  String get roleBuyer => 'मुझे ताज़ी उपज चाहिए';

  @override
  String get roleBuyerHint => 'पास में किसान होने पर सूचना पाएँ';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get comingSoon => 'जल्द आ रहा है';

  @override
  String get farmerHome => 'होम';

  @override
  String get hostHome => 'होम';

  @override
  String get buyerHome => 'मेरे पास की दुकानें';

  @override
  String get opsHome => 'संचालन';

  @override
  String get errorGeneric => 'कुछ गलत हो गया। कृपया फिर से प्रयास करें।';

  @override
  String get tagline => 'खेत से सीधे, आपके गेट तक';

  @override
  String get featureVerified => 'केवल अपनी उपज बेचने वाले सत्यापित किसान';

  @override
  String get featureSpaces =>
      'पड़ोसी कुछ घंटों के लिए अपना आंगन या ड्राइववे देते हैं';

  @override
  String get featureAlerts => 'दुकान खुलने पर पास के खरीदारों को सूचना';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get retry => 'फिर से प्रयास करें';

  @override
  String get refresh => 'रीफ़्रेश करें';

  @override
  String get next => 'आगे';

  @override
  String get back => 'पीछे';

  @override
  String get save => 'सहेजें';

  @override
  String get required => 'आवश्यक';

  @override
  String get verifyNotStartedTitle => 'बेचना शुरू करने के लिए सत्यापन कराएँ';

  @override
  String get startVerification => 'सत्यापन शुरू करें';

  @override
  String get continueVerification => 'सत्यापन जारी रखें';

  @override
  String get verifyPendingTitle => 'जाँच जारी है';

  @override
  String get verifyPendingBody =>
      'हमारी टीम आपकी जानकारी जाँच रही है। आमतौर पर 48 घंटे तक लगते हैं।';

  @override
  String get verifiedTitle => 'सत्यापित किसान';

  @override
  String get verifiedBody =>
      'आप सत्यापित हैं। बेचना शुरू करने के लिए यात्रा की योजना बनाएँ और जगह बुक करें।';

  @override
  String get rejectedTitle => 'सत्यापन में बदलाव ज़रूरी हैं';

  @override
  String rejectedReason(String reason) {
    return 'कारण: $reason';
  }

  @override
  String get fixAndResubmit => 'सुधारें और फिर भेजें';

  @override
  String get stepAboutYou => 'आपके बारे में';

  @override
  String get stepReview => 'भेजें';

  @override
  String get verifyNotStartedBody =>
      'हम जाँचते हैं कि आप असली किसान हैं। लगभग 5 मिनट लगते हैं। खेती का एक सबूत तैयार रखें: एग्रीस्टैक किसान ID, ज़मीन या खेती का रिकॉर्ड, FPO सदस्यता, या कृषि अधिकारी का पत्र।';

  @override
  String get consentText =>
      'मैं पुष्टि करता/करती हूँ कि ये जानकारी सही है। मैं सहमत हूँ कि आंगन मंडी मेरे सत्यापन के लिए यह सबूत रखे।';

  @override
  String get stepEvidence => 'खेती का सबूत';

  @override
  String get farmSizeOptional => 'खेत का अनुमानित आकार एकड़ में (वैकल्पिक)';

  @override
  String get farmSizeInvalid => '0 से 1000 एकड़ के बीच लिखें';

  @override
  String get produceSourceQuestion => 'क्या आप अपनी उगाई उपज बेचते हैं?';

  @override
  String get sourceOwnFarm => 'हाँ, केवल अपनी उगाई हुई';

  @override
  String get sourceOwnAndOthers => 'ज़्यादातर मेरी, कुछ दूसरे किसानों से';

  @override
  String get sourceOthers => 'नहीं, दूसरे किसानों से खरीदकर बेचता/बेचती हूँ';

  @override
  String get evidenceQuestion => 'किसान होने का एक सबूत चुनें';

  @override
  String get evidenceSubtitle =>
      'एक सत्यापनकर्ता इसे जाँचकर मंज़ूरी देता है, आमतौर पर 48 घंटों में।';

  @override
  String get evidenceAgriStack => 'एग्रीस्टैक किसान ID';

  @override
  String get evidenceAgriStackHint => 'आपका किसान ID कार्ड या SMS';

  @override
  String get evidenceLandRecord => 'ज़मीन या खेती का रिकॉर्ड';

  @override
  String get evidenceLandRecordHint =>
      'पट्टादार पासबुक, ROR-1B, पट्टा समझौता या फ़सल रिकॉर्ड';

  @override
  String get evidenceFpo => 'FPO सदस्यता या सिफ़ारिश';

  @override
  String get evidenceFpoHint =>
      'आपके किसान उत्पादक संगठन का सदस्यता कार्ड या पत्र';

  @override
  String get evidenceOfficer => 'कृषि अधिकारी की सिफ़ारिश';

  @override
  String get evidenceOfficerHint =>
      'आपके कृषि विस्तार अधिकारी या मान्यता प्राप्त किसान संगठन का पत्र';

  @override
  String get detailsAgriStack => 'किसान ID नंबर';

  @override
  String get detailsLandRecord => 'सर्वे नंबर (वैकल्पिक)';

  @override
  String get detailsFpo => 'FPO का नाम, या जिसने आपकी सिफ़ारिश की';

  @override
  String get detailsOfficer => 'अधिकारी या संगठन का नाम और फ़ोन';

  @override
  String get evidencePhoto => 'सबूत की फ़ोटो';

  @override
  String get evidencePhotoHint => 'ध्यान रखें कि आपका नाम पढ़ा जा सके';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get village => 'गाँव';

  @override
  String get district => 'ज़िला';

  @override
  String get takePhoto => 'फ़ोटो लें';

  @override
  String get retakePhoto => 'फिर से लें';

  @override
  String get uploaded => 'अपलोड हो गया';

  @override
  String get uploading => 'अपलोड हो रहा है…';

  @override
  String get cropsYouGrow => 'आप जो फ़सलें उगाते हैं';

  @override
  String get useMyLocation => 'मेरा मौजूदा स्थान लें';

  @override
  String get locationDenied => 'आगे बढ़ने के लिए लोकेशन की अनुमति दें';

  @override
  String get reviewChecklist => 'भेजने से पहले सब कुछ जाँच लें';

  @override
  String get submitForReview => 'जाँच के लिए भेजें';

  @override
  String get completeAllSteps => 'भेजने से पहले सभी चरण पूरे करें';

  @override
  String get submittedMessage => 'भेज दिया गया। हम 48 घंटे में जाँच करेंगे।';

  @override
  String get addSpace => 'जगह जोड़ें';

  @override
  String get noSpacesTitle => 'अपनी पहली जगह जोड़ें';

  @override
  String get noSpacesBody =>
      'किसी सत्यापित किसान को कुछ घंटों के लिए अपना ड्राइववे, आंगन या खुली जगह दें। पड़ोसियों को गेट पर ताज़ी उपज मिलेगी।';

  @override
  String get spaceDetails => 'जगह का विवरण';

  @override
  String get spaceName => 'जगह का नाम';

  @override
  String get spaceNameHint => 'उदाहरण: ग्रीन विला आंगन';

  @override
  String get spaceType => 'जगह का प्रकार';

  @override
  String get driveway => 'ड्राइववे';

  @override
  String get courtyard => 'आंगन';

  @override
  String get openArea => 'खुली जगह';

  @override
  String get commercialFrontage => 'दुकान का सामने का हिस्सा';

  @override
  String get address => 'पूरा पता';

  @override
  String get addressHint =>
      'बुकिंग मंज़ूर करने के बाद ही किसान को दिखाया जाएगा';

  @override
  String get locality => 'इलाका';

  @override
  String get spaceLocation => 'जगह का स्थान';

  @override
  String get enterCoordinates => 'निर्देशांक दर्ज करें';

  @override
  String get latitude => 'अक्षांश';

  @override
  String get longitude => 'देशांतर';

  @override
  String get areaSqFt => 'उपयोगी क्षेत्र (वर्ग फ़ुट)';

  @override
  String get maxVehicle => 'अंदर आ सकने वाला सबसे बड़ा वाहन';

  @override
  String get twoWheeler => 'दोपहिया';

  @override
  String get auto => 'ऑटो';

  @override
  String get miniTruck => 'मिनी ट्रक';

  @override
  String get tractor => 'ट्रैक्टर';

  @override
  String get amenities => 'सुविधाएँ';

  @override
  String get water => 'पानी';

  @override
  String get shade => 'छाया';

  @override
  String get powerPoint => 'बिजली पॉइंट';

  @override
  String get buyerParking => 'खरीदारों के लिए पार्किंग';

  @override
  String get loadingAccess => 'सामान उतारने की सुविधा';

  @override
  String get toilet => 'शौचालय';

  @override
  String get pricing => 'शुल्क';

  @override
  String get freeSpace => 'मुफ़्त सामुदायिक जगह';

  @override
  String get feePerSlot => 'प्रति स्लॉट शुल्क (₹)';

  @override
  String get availability => 'उपलब्धता';

  @override
  String get availableDays => 'उपलब्ध दिन';

  @override
  String get openFrom => 'से';

  @override
  String get openTo => 'तक';

  @override
  String get slotRule => 'हर स्लॉट 2 से 6 घंटे का होना चाहिए';

  @override
  String get houseRules => 'नियम (वैकल्पिक)';

  @override
  String get houseRulesHint => 'उदाहरण: मछली या मांस नहीं, बिक्री के बाद सफ़ाई';

  @override
  String get spacePhotos => 'जगह की फ़ोटो (3 से 8)';

  @override
  String get addPhotos => 'फ़ोटो जोड़ें';

  @override
  String get proofOfRight => 'इस जगह के उपयोग के अधिकार का प्रमाण';

  @override
  String get proofHint =>
      'मालिकाना दस्तावेज़, किराया समझौता या सोसाइटी का पत्र। खरीदारों को कभी नहीं दिखाया जाता।';

  @override
  String get submitSpace => 'मंज़ूरी के लिए भेजें';

  @override
  String get spaceSubmitted =>
      'मंज़ूरी के लिए भेज दिया। आमतौर पर 48 घंटे में जाँच होती है।';

  @override
  String get statusDraft => 'ड्राफ़्ट';

  @override
  String get statusPendingReview => 'मंज़ूरी का इंतज़ार';

  @override
  String get statusLive => 'लाइव';

  @override
  String get statusRejected => 'बदलाव ज़रूरी';

  @override
  String perSlot(String fee) {
    return '₹$fee प्रति स्लॉट';
  }

  @override
  String get free => 'मुफ़्त';

  @override
  String get photosNeeded => 'कम से कम 3 फ़ोटो और प्रमाण दस्तावेज़ जोड़ें';

  @override
  String get finishAndSubmit => 'पूरा करें और भेजें';

  @override
  String get addMorePhotos => 'और फ़ोटो जोड़ें';

  @override
  String get buyerComingSoon =>
      'किसानों के बेचना शुरू करने पर आपके पास की दुकानें यहाँ दिखेंगी।';

  @override
  String get profileTitle => 'मेरी प्रोफ़ाइल';

  @override
  String get accountDetails => 'खाते का विवरण';

  @override
  String get name => 'नाम';

  @override
  String get nameNotSet => 'अभी नहीं जोड़ा';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get memberSince => 'जुड़ने की तारीख';

  @override
  String get yourRoles => 'ऐप का उपयोग इस रूप में';

  @override
  String get roleNameFarmer => 'किसान';

  @override
  String get roleNameHost => 'जगह के मेज़बान';

  @override
  String get roleNameBuyer => 'खरीदार';

  @override
  String get roleNameVerifier => 'सत्यापनकर्ता';

  @override
  String get roleNameAdmin => 'एडमिन';

  @override
  String get verificationStatus => 'सत्यापन';

  @override
  String get farmDetails => 'खेती का विवरण';

  @override
  String get crops => 'फसलें';

  @override
  String get mySpaces => 'मेरी जगहें';

  @override
  String mySpacesSummary(int count, int live) {
    return '$count सूचीबद्ध · $live लाइव';
  }

  @override
  String get appearance => 'दिखावट';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get themeSystemHint =>
      'सिस्टम आपके फ़ोन या कंप्यूटर की सेटिंग के अनुसार चलता है।';

  @override
  String get staffAccessRevokedTitle => 'अब आपके पास स्टाफ़ एक्सेस नहीं है';

  @override
  String get staffAccessRevokedBody =>
      'अगर आपको लगता है कि यह गलती है तो एडमिन से पूछें। अपने दूसरे खाते से जारी रखने के लिए लॉग आउट करें।';

  @override
  String get opsTabDashboard => 'डैशबोर्ड';

  @override
  String get opsTabFarmers => 'किसान';

  @override
  String get opsTabSpaces => 'जगहें';

  @override
  String get opsTabVerifiers => 'सत्यापनकर्ता';

  @override
  String opsHello(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get opsHelloNoName => 'नमस्ते';

  @override
  String get opsAdminSubtitle =>
      'एडमिन · आप हर किसान को देखते हैं और सत्यापनकर्ताओं को संभालते हैं';

  @override
  String get opsVerifierSubtitle =>
      'सत्यापनकर्ता · आप अपने को सौंपे गए किसानों की जाँच करते हैं';

  @override
  String get statFarmersWaitingAll => 'जाँच का इंतज़ार कर रहे किसान';

  @override
  String get statFarmersWaitingYou => 'आपका इंतज़ार कर रहे किसान';

  @override
  String get statUnassigned => 'बिना सत्यापनकर्ता के इंतज़ार में';

  @override
  String get statSpacesWaiting => 'मंज़ूरी का इंतज़ार कर रही जगहें';

  @override
  String get statVerifiedAll => 'सत्यापित किसान';

  @override
  String get statVerifiedYou => 'आपके द्वारा सत्यापित किसान';

  @override
  String get statSpacesLive => 'लाइव जगहें';

  @override
  String get couldNotLoad =>
      'लोड नहीं हो सका। फिर से कोशिश करने के लिए नीचे खींचें या रिफ़्रेश दबाएँ।';

  @override
  String get couldNotSave => 'सेव नहीं हो सका। फिर से कोशिश करें।';

  @override
  String get emptyList => 'इस सूची में कुछ नहीं है।';

  @override
  String get noName => '(कोई नाम नहीं)';

  @override
  String get decision => 'निर्णय';

  @override
  String get reasonLabel => 'कारण (अस्वीकार करने के लिए ज़रूरी; उन्हें दिखेगा)';

  @override
  String get reject => 'अस्वीकार करें';

  @override
  String rejectedWith(String reason) {
    return 'अस्वीकृत: $reason';
  }

  @override
  String get unassigned => 'सौंपा नहीं गया';

  @override
  String get farmerStatusPending => 'जाँच का इंतज़ार';

  @override
  String get farmerStatusVerified => 'सत्यापित';

  @override
  String get farmerStatusRejected => 'अस्वीकृत';

  @override
  String get farmerStatusNotStarted => 'जमा नहीं किया';

  @override
  String get farmerVerificationTitle => 'किसान सत्यापन';

  @override
  String get farmerQueueAdminHint =>
      'सभी किसान। हर आवेदन उस सत्यापनकर्ता को जाता है जिसके पास सबसे कम इंतज़ार में हैं।';

  @override
  String get farmerQueueVerifierHint =>
      'आपको सौंपे गए किसान, सबसे पुराने पहले।';

  @override
  String get noVerifierWarnTitle =>
      'कुछ किसानों के पास कोई सत्यापनकर्ता नहीं है';

  @override
  String get noVerifierWarnBody =>
      'सत्यापनकर्ता जोड़ें तो किसान अपने आप सौंप दिए जाएँगे, या किसी किसान को खोलकर सौंपें।';

  @override
  String submittedOn(String when) {
    return 'जमा किया $when';
  }

  @override
  String verifierIs(String name) {
    return 'सत्यापनकर्ता: $name';
  }

  @override
  String get reviewFarmer => 'किसान की जाँच';

  @override
  String get qrFarmerPhotoUnclear =>
      'सबूत की फ़ोटो साफ़ नहीं है — कृपया दोबारा लें';

  @override
  String get qrFarmerNameMismatch => 'सबूत पर लिखा नाम मेल नहीं खाता';

  @override
  String get qrFarmerIdUnconfirmed => 'किसान ID की पुष्टि नहीं हो सकी';

  @override
  String get qrFarmerRefereeNo => 'सिफ़ारिश करने वाले ने आपकी पुष्टि नहीं की';

  @override
  String get qrFarmerNotGrower =>
      'आप सिर्फ़ दूसरे किसानों से खरीदी उपज बेचते हैं';

  @override
  String phoneOtpVerified(String phone) {
    return '$phone (OTP सत्यापित)';
  }

  @override
  String get farmSize => 'खेत का आकार';

  @override
  String get notGiven => 'नहीं दिया';

  @override
  String aboutAcres(String acres) {
    return 'लगभग $acres एकड़';
  }

  @override
  String get sells => 'बेचते हैं';

  @override
  String get sellsOwnFarm => 'सिर्फ़ अपनी उगाई उपज';

  @override
  String get sellsOwnAndOthers => 'अपनी फसल, कुछ दूसरे किसानों से भी';

  @override
  String get sellsOthers => 'सिर्फ़ दूसरे किसानों की उपज (खुद नहीं उगाते)';

  @override
  String get submitted => 'जमा किया';

  @override
  String get farmingEvidence => 'खेती का सबूत';

  @override
  String get factType => 'प्रकार';

  @override
  String get factDetails => 'विवरण';

  @override
  String get noPhoto => 'कोई फ़ोटो नहीं';

  @override
  String get olderDocuments => 'पिछली सत्यापन प्रक्रिया के दस्तावेज़';

  @override
  String get howCheckAgriStack =>
      'AgriStack किसान रजिस्ट्री में किसान ID नंबर और नाम जाँचें।';

  @override
  String get howCheckLandRecord =>
      'भू भारती पोर्टल पर मालिक या काश्तकार का नाम और सर्वे नंबर जाँचें।';

  @override
  String get howCheckFpo =>
      'FPO (या सिफ़ारिश करने वाले) को फ़ोन करके पुष्टि करें कि वे इस किसान को जानते हैं।';

  @override
  String get howCheckOfficer =>
      'अधिकारी या संस्था को फ़ोन करके पुष्टि करें कि वे इस किसान को जानते हैं।';

  @override
  String get farmerApproveGuidance =>
      'तभी मंज़ूरी दें जब सबूत असली हो, उस पर नाम इसी किसान का हो, और वे जो बेचते हैं वह खुद उगाते हों।';

  @override
  String get farmerApproveLabel => 'मंज़ूर करें — सत्यापित किसान';

  @override
  String farmerApprovedToast(String name) {
    return 'मंज़ूर: $name अब सत्यापित किसान हैं';
  }

  @override
  String get farmerRejectedToast => 'अस्वीकार किया। किसान को आपका कारण दिखेगा।';

  @override
  String get assignedTo => 'किसे सौंपा';

  @override
  String get assignedOn => 'सौंपने की तारीख';

  @override
  String get reviewedBy => 'जाँच करने वाले';

  @override
  String get verifierAssignedToast => 'सत्यापनकर्ता सौंपा गया';

  @override
  String get noVerifiersYetAssign =>
      'अभी कोई सत्यापनकर्ता नहीं है। सत्यापनकर्ता टैब में जोड़ें।';

  @override
  String get chooseVerifier => 'सत्यापनकर्ता चुनें';

  @override
  String verifierOption(String name, int count) {
    return '$name ($count इंतज़ार में)';
  }

  @override
  String get assign => 'सौंपें';

  @override
  String get reassign => 'दोबारा सौंपें';

  @override
  String get spaceApprovals => 'जगह की मंज़ूरी';

  @override
  String hostedBy(String host, String when) {
    return 'मेज़बान: $host · अपडेट $when';
  }

  @override
  String get reviewSpace => 'जगह की जाँच';

  @override
  String get qrSpacePublicRoad => 'जगह सार्वजनिक सड़क या फ़ुटपाथ पर है';

  @override
  String get qrSpacePhotos => 'फ़ोटो साफ़ नहीं हैं या जगह नहीं दिखाते';

  @override
  String get qrSpaceProof =>
      'दस्तावेज़ से इस जगह के उपयोग का अधिकार साबित नहीं होता';

  @override
  String get qrSpacePin => 'लोकेशन पिन पते से मेल नहीं खाता';

  @override
  String get spaceSection => 'जगह';

  @override
  String get usableArea => 'इस्तेमाल लायक जगह';

  @override
  String areaValue(int area, String stall) {
    return '$area वर्ग फ़ुट (स्टॉल $stall तक)';
  }

  @override
  String get none => 'कोई नहीं';

  @override
  String get openInMaps => 'मैप में लोकेशन खोलें';

  @override
  String get availabilityAndHost => 'उपलब्धता और मेज़बान';

  @override
  String get hours => 'समय';

  @override
  String get fee => 'शुल्क';

  @override
  String get freeCommunitySpace => 'मुफ़्त सामुदायिक जगह';

  @override
  String get rules => 'घर के नियम';

  @override
  String get host => 'मेज़बान';

  @override
  String get proofMissing => 'सबूत नहीं है';

  @override
  String photosCount(int count) {
    return 'फ़ोटो ($count)';
  }

  @override
  String get spaceApproveGuidance =>
      'तभी मंज़ूरी दें जब यह निजी जगह हो (सड़क या फ़ुटपाथ नहीं), फ़ोटो लोकेशन से मेल खाएँ, और सबूत में मेज़बान का नाम हो या उपयोग की अनुमति हो।';

  @override
  String get spaceApproveLabel => 'मंज़ूर करें — लाइव करें';

  @override
  String spaceLiveToast(String title) {
    return '$title अब लाइव है';
  }

  @override
  String get spaceRejectedToast =>
      'अस्वीकार किया। मेज़बान को आपका कारण दिखेगा।';

  @override
  String get verifiersHint =>
      'हर आवेदन करने वाला किसान उस सत्यापनकर्ता को जाता है जिसके पास सबसे कम किसान इंतज़ार में हों; दोबारा जमा करने पर उसी सत्यापनकर्ता को।';

  @override
  String get addVerifierTitle => 'सत्यापनकर्ता जोड़ें';

  @override
  String get addVerifierButton => 'जोड़ें';

  @override
  String get enterName => 'नाम दर्ज करें';

  @override
  String get enterTenDigits => '10 अंकों का नंबर दर्ज करें';

  @override
  String verifierAddedToast(String name, String phone) {
    return '$name को जोड़ा गया। वे +91 $phone से लॉग इन कर सकते हैं।';
  }

  @override
  String farmersAssignedToNew(int count) {
    return 'इंतज़ार कर रहे $count किसान उन्हें सौंपे गए।';
  }

  @override
  String removeVerifierQ(String name) {
    return '$name को हटाएँ?';
  }

  @override
  String get removeVerifierBody =>
      'वे अब किसानों या जगहों की जाँच नहीं कर पाएँगे।';

  @override
  String removeVerifierMoves(int count) {
    return 'उनके $count इंतज़ार कर रहे किसान दूसरे सत्यापनकर्ताओं को चले जाएँगे।';
  }

  @override
  String get cancel => 'रद्द करें';

  @override
  String get remove => 'हटाएँ';

  @override
  String verifierRemovedToast(String name) {
    return '$name को हटाया गया।';
  }

  @override
  String farmersMoved(int count) {
    return 'इंतज़ार कर रहे $count किसान दूसरे सत्यापनकर्ताओं को भेजे गए।';
  }

  @override
  String farmersNowUnassigned(int count) {
    return '$count किसान अब किसी को नहीं सौंपे गए: उनके लिए सत्यापनकर्ता जोड़ें।';
  }

  @override
  String get noVerifiersBody =>
      'अभी कोई सत्यापनकर्ता नहीं है। जब तक आप किसी को नहीं जोड़ते, आवेदन करने वाले किसान किसी को नहीं सौंपे जाएँगे।';

  @override
  String verifierAddedOn(String phone, String when) {
    return '$phone · जोड़ा $when';
  }

  @override
  String verifierCounts(int waiting, int reviewed) {
    return '$waiting इंतज़ार में · $reviewed जाँचे';
  }

  @override
  String get removeVerifierTooltip => 'सत्यापनकर्ता हटाएँ';

  @override
  String get preview => 'देखें';

  @override
  String get download => 'डाउनलोड';

  @override
  String get reupload => 'दोबारा अपलोड';

  @override
  String get delete => 'हटाएँ';

  @override
  String get close => 'बंद करें';

  @override
  String get uploadPhoto => 'फ़ोटो अपलोड करें';

  @override
  String get downloadSaved => 'डाउनलोड हो गया';

  @override
  String get downloadFailed => 'डाउनलोड नहीं हो सका। फिर से कोशिश करें।';

  @override
  String get deleteDocumentQ => 'यह फ़ोटो हटाएँ?';

  @override
  String get deleteDocumentBody => 'बाद में आप नई फ़ोटो अपलोड कर सकते हैं।';

  @override
  String get documentLocked => 'मंज़ूर हो चुका है — अब इसे बदला नहीं जा सकता।';

  @override
  String get evidenceWithdrawWarning =>
      'आपका सत्यापन जाँच का इंतज़ार कर रहा है। सबूत हटाने से यह कतार से हट जाएगा: नई फ़ोटो अपलोड करके फिर से जमा करें।';

  @override
  String get evidenceWithdrawnToast =>
      'फ़ोटो हटा दी गई। नई फ़ोटो अपलोड करके फिर से जमा करें।';

  @override
  String get spaceWithdrawWarning =>
      'यह जगह मंज़ूरी का इंतज़ार कर रही है। अगर 3 से कम फ़ोटो रह जाएँ या सबूत न रहे, तो यह ड्राफ़्ट में चली जाएगी और आपको फिर से जमा करना होगा।';

  @override
  String get spaceWithdrawnToast =>
      'फ़ोटो हटा दी गई। जगह ड्राफ़्ट में चली गई: जो कमी है वह जोड़कर फिर से जमा करें।';

  @override
  String get photoDeletedToast => 'फ़ोटो हटा दी गई';

  @override
  String photoNumber(int number) {
    return 'फ़ोटो $number';
  }

  @override
  String get yourDocument => 'आपका दस्तावेज़';

  @override
  String get yourDocumentPendingHint =>
      'जाँच के इंतज़ार के दौरान भी आप इसे बदल या हटा सकते हैं।';

  @override
  String get bookingRequested => 'मेज़बान का इंतज़ार';

  @override
  String get bookingAccepted => 'जगह बुक हो गई';

  @override
  String get bookingDeclined => 'अस्वीकार';

  @override
  String get bookingCancelled => 'रद्द';

  @override
  String get tripPlanned => 'योजना बनी';

  @override
  String get tripCompleted => 'पूरा हुआ';

  @override
  String kgAmount(String amount) {
    return '$amount किलो';
  }

  @override
  String pricePerKgAmount(String price) {
    return '₹$price/किलो';
  }

  @override
  String get bookingSlotTaken =>
      'मेज़बान ने इस दिन के लिए दूसरे किसान की पुष्टि कर दी।';

  @override
  String bookingDeclinedBecause(String reason) {
    return 'मेज़बान ने अस्वीकार किया: $reason';
  }

  @override
  String bookingHostCancelled(String reason) {
    return 'मेज़बान ने रद्द किया: $reason';
  }

  @override
  String get bookingYouCancelled => 'आपने यह बुकिंग रद्द की।';

  @override
  String upToVehicle(String vehicle) {
    return '$vehicle तक आ सकता है';
  }

  @override
  String get myTrips => 'मेरी यात्राएँ';

  @override
  String get planTrip => 'यात्रा की योजना बनाएँ';

  @override
  String get noTripsTitle => 'अभी कोई यात्रा नहीं';

  @override
  String get noTripsBody =>
      'जिस दिन आप शहर में बेचने आएँगे उसकी योजना बनाएँ, फिर अपने खरीदारों के पास जगह बुक करें।';

  @override
  String get noSpaceYet => 'अभी कोई जगह बुक नहीं';

  @override
  String get editTrip => 'यात्रा बदलें';

  @override
  String get tripWhen => 'आप कब आ रहे हैं?';

  @override
  String get tripDateLocked =>
      'जगह माँगी या बुक होने पर तारीख और वाहन नहीं बदल सकते। बदलने के लिए बुकिंग रद्द करें।';

  @override
  String get chooseDate => 'तारीख चुनें';

  @override
  String get tripVehicle => 'आपका वाहन';

  @override
  String get tripVehicleHint =>
      'हम सिर्फ़ वही जगहें दिखाते हैं जहाँ यह जा सके।';

  @override
  String get tripProduce => 'आप क्या लाएँगे?';

  @override
  String get tripProduceHint =>
      'फसलें चुनें। मात्रा और दाम वैकल्पिक हैं और मेज़बान की मदद करते हैं।';

  @override
  String get quantityKg => 'किलो';

  @override
  String get priceKg => '₹ प्रति किलो';

  @override
  String get tripWhere => 'आप कहाँ बेचना चाहेंगे?';

  @override
  String get preferredArea => 'इलाका (वैकल्पिक)';

  @override
  String get preferredAreaHint => 'जैसे अमीरपेट, कूकटपल्ली';

  @override
  String get tripNotes => 'नोट (वैकल्पिक)';

  @override
  String get saveTripFindSpace => 'सेव करें और जगह खोजें';

  @override
  String get tripNeedsDateAndCrop => 'तारीख और कम से कम एक फसल चुनें';

  @override
  String get cancelTrip => 'यात्रा रद्द करें';

  @override
  String get cancelTripQ => 'यह यात्रा रद्द करें?';

  @override
  String get cancelTripBody =>
      'इसके लिए माँगी या बुक की गई जगह भी रद्द हो जाएगी, और मेज़बान को बताया जाएगा।';

  @override
  String get tripCancelledToast => 'यात्रा रद्द हुई';

  @override
  String get tripDetails => 'यात्रा';

  @override
  String get cancelBookingQ => 'यह बुकिंग रद्द करें?';

  @override
  String get cancelBookingBody =>
      'दूसरे पक्ष को बताया जाएगा और स्लॉट फिर से खाली हो जाएगा।';

  @override
  String get cancelBooking => 'बुकिंग रद्द करें';

  @override
  String get bookingCancelledToast => 'बुकिंग रद्द हुई';

  @override
  String get spaceBookedTitle => 'जगह बुक हो गई — वहीं मिलते हैं';

  @override
  String get payAtSpace => 'जगह पर मेज़बान को भुगतान करें';

  @override
  String get callHost => 'मेज़बान को फ़ोन करें';

  @override
  String get waitingForHostTitle => 'मेज़बान का इंतज़ार';

  @override
  String get waitingForHostBody =>
      'मेज़बान आपका अनुरोध स्वीकार या अस्वीकार करेंगे। स्वीकार होने पर आपको पता और फ़ोन नंबर दिखेगा।';

  @override
  String get cancelRequest => 'अनुरोध रद्द करें';

  @override
  String get spaceForTrip => 'इस यात्रा के लिए जगह';

  @override
  String get findSpaceIntro =>
      'ऐसी जगह खोजें जो इस दिन खुली हो और जहाँ आपका वाहन आ सके।';

  @override
  String get findAnotherSpaceIntro =>
      'आप इस दिन के लिए दूसरी जगह माँग सकते हैं।';

  @override
  String get findSpace => 'जगह खोजें';

  @override
  String get findAnotherSpace => 'दूसरी जगह खोजें';

  @override
  String get tripWasCancelled => 'यह यात्रा रद्द हो गई थी।';

  @override
  String get tripIsOver => 'इस यात्रा की तारीख निकल चुकी है।';

  @override
  String requestSpaceTitle(String title) {
    return '$title माँगें';
  }

  @override
  String get messageToHost => 'मेज़बान के लिए संदेश (वैकल्पिक)';

  @override
  String get messageToHostHint =>
      'जैसे मैं ऑटो में टमाटर की 3 पेटियाँ लेकर आऊँगा';

  @override
  String get sendRequest => 'अनुरोध भेजें';

  @override
  String get requestSentToast =>
      'अनुरोध भेजा गया। जवाब आपकी यात्रा में दिखेगा।';

  @override
  String spacesFor(String date) {
    return '$date के लिए जगहें';
  }

  @override
  String get searchArea => 'इलाका खोजें (जैसे अमीरपेट)';

  @override
  String get clear => 'हटाएँ';

  @override
  String spacesMatchHint(String vehicle) {
    return 'उस दिन खुली जगहें जहाँ आपका $vehicle आ सके। मेज़बान के स्वीकार करने पर पूरा पता दिया जाएगा।';
  }

  @override
  String get noSpacesThatDay =>
      'इस दिन आपके वाहन के लायक कोई खाली जगह नहीं है। दूसरी तारीख आज़माएँ।';

  @override
  String get noSpacesInArea =>
      'इस दिन इस इलाके में कोई खाली जगह नहीं है। सभी इलाके देखने के लिए खोज हटाएँ।';

  @override
  String get requestThisSpace => 'यह जगह माँगें';

  @override
  String get bookings => 'बुकिंग';

  @override
  String get bookingsHint => 'किसानों के अनुरोध और पक्के दिन';

  @override
  String requestsWaiting(int count) {
    return '$count किसान आपके जवाब का इंतज़ार कर रहे हैं';
  }

  @override
  String requestsCount(int count) {
    return 'अनुरोध ($count)';
  }

  @override
  String get bookingRequestsTab => 'अनुरोध';

  @override
  String get upcomingTab => 'आने वाली';

  @override
  String get pastTab => 'पिछली';

  @override
  String get noRequests =>
      'कोई नया अनुरोध नहीं। आपकी जगहों के लिए किसानों के अनुरोध यहाँ दिखेंगे।';

  @override
  String get noUpcoming => 'कोई पक्की बुकिंग आगे नहीं है।';

  @override
  String get noPastBookings => 'अभी कोई पिछली बुकिंग नहीं।';

  @override
  String get reasonForFarmer => 'कारण (किसान को दिखेगा)';

  @override
  String get verifiedFarmerTag => 'सत्यापित किसान';

  @override
  String get hostAutoDeclined =>
      'अपने आप अस्वीकार: आपने इस दिन के लिए दूसरे किसान की पुष्टि की।';

  @override
  String get farmerCancelled => 'किसान ने रद्द किया।';

  @override
  String yourReason(String reason) {
    return 'कारण: $reason';
  }

  @override
  String get accept => 'स्वीकार करें';

  @override
  String get decline => 'अस्वीकार करें';

  @override
  String get acceptedToast =>
      'स्वीकार किया। अब किसान को आपका पता और फ़ोन दिखेगा।';

  @override
  String get declineQ => 'यह अनुरोध अस्वीकार करें?';

  @override
  String get qrNotAvailableDay => 'उस दिन जगह उपलब्ध नहीं है';

  @override
  String get qrVehicleTooBig => 'वाहन अंदर नहीं आएगा';

  @override
  String get qrOnlySomeProduce => 'मैं इस तरह की उपज के लिए जगह नहीं दे सकता';

  @override
  String get declinedToast => 'अनुरोध अस्वीकार किया';

  @override
  String get callFarmer => 'किसान को फ़ोन करें';

  @override
  String get newRequest => 'नया अनुरोध';

  @override
  String greetingName(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get greetingNoName => 'नमस्ते';

  @override
  String get farmerBannerVerified =>
      'आप सत्यापित किसान हैं। अपने अगले बिक्री के दिन की योजना बनाएँ।';

  @override
  String get farmerBannerNotVerified =>
      'एक बार सत्यापन कराएँ, फिर शहर में अपनी ताज़ी उपज बेचें।';

  @override
  String get statUpcomingTrips => 'आने वाली यात्राएँ';

  @override
  String get statSpacesBooked => 'बुक हुई जगहें';

  @override
  String get statWaitingHost => 'मेज़बान का इंतज़ार';

  @override
  String get statCompletedTrips => 'पूरी हुई यात्राएँ';

  @override
  String get nextTrip => 'आपकी अगली यात्रा';

  @override
  String get noUpcomingTitle => 'कोई यात्रा तय नहीं';

  @override
  String get noUpcomingBody =>
      'शहर आने का दिन चुनें, फिर खरीदारों के पास जगह बुक करें।';

  @override
  String get viewTrip => 'यात्रा देखें';

  @override
  String get allTrips => 'सभी यात्राएँ';

  @override
  String get yourVerification => 'आपका सत्यापन';

  @override
  String get howItWorks => 'यह कैसे काम करता है';

  @override
  String get howStepVerify => 'सत्यापन कराएँ';

  @override
  String get howStepVerifyBody =>
      'अपनी खेती के बारे में बताएँ और एक सबूत जोड़ें। सत्यापनकर्ता उसे जाँचते हैं।';

  @override
  String get howStepTrip => 'यात्रा की योजना बनाएँ';

  @override
  String get howStepTripBody => 'दिन, अपना वाहन और आप क्या लाएँगे, चुनें।';

  @override
  String get howStepBook => 'जगह बुक करें';

  @override
  String get howStepBookBody =>
      'खरीदारों के पास ड्राइववे या आँगन माँगें। मेज़बान स्वीकार करते हैं।';

  @override
  String get howStepSell => 'ताज़ा बेचें';

  @override
  String get howStepSellBody =>
      'अपना स्टॉल लगाएँ और पास के परिवारों को सीधे बेचें।';

  @override
  String bookedAt(String space) {
    return '$space में बुक हुआ';
  }

  @override
  String waitingAt(String space) {
    return '$space की मंज़ूरी का इंतज़ार';
  }

  @override
  String hostBanner(int live, int waiting) {
    return 'लाइव जगहें: $live · नए अनुरोध: $waiting';
  }

  @override
  String get hostBannerNew =>
      'अपना ड्राइववे या आँगन जोड़ें और किसानों के वहाँ बेचने पर कमाएँ।';

  @override
  String get statNewRequests => 'नए अनुरोध';

  @override
  String get statUpcomingBookings => 'आने वाली बुकिंग';

  @override
  String get needsYourAnswer => 'आपके जवाब का इंतज़ार';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get nextBooking => 'अगली बुकिंग';

  @override
  String get noBookingYet =>
      'अभी कोई पक्की बुकिंग नहीं। स्वीकार किए गए अनुरोध यहाँ दिखेंगे।';

  @override
  String get answer => 'जवाब दें';

  @override
  String get hostHowList => 'अपनी जगह जोड़ें';

  @override
  String get hostHowListBody =>
      'फ़ोटो, दिन और समय, शुल्क, और जगह के उपयोग के अधिकार का सबूत।';

  @override
  String get hostHowApproved => 'मंज़ूरी पाएँ';

  @override
  String get hostHowApprovedBody =>
      'हमारी टीम फ़ोटो, लोकेशन और सबूत जाँचती है।';

  @override
  String get hostHowRequests => 'किसान एक दिन माँगते हैं';

  @override
  String get hostHowRequestsBody =>
      'सत्यापित किसान अपने बिक्री के दिन के लिए आपकी जगह माँगते हैं।';

  @override
  String get hostHowAccept => 'स्वीकार करें और जगह दें';

  @override
  String get hostHowAcceptBody =>
      'स्वीकार करें, अपना पता साझा करें, और जगह पर शुल्क लें।';

  @override
  String get catVegetable => 'सब्ज़ियाँ';

  @override
  String get catLeafy => 'पत्तेदार सब्ज़ियाँ';

  @override
  String get catFruit => 'फल';

  @override
  String get catGrain => 'अनाज और मोटा अनाज';

  @override
  String get catPulse => 'दालें';

  @override
  String get catOilseed => 'तिलहन';

  @override
  String get catSpice => 'मसाले';

  @override
  String get catFlower => 'फूल';

  @override
  String get catOther => 'अन्य';

  @override
  String get searchCrops => 'फसलें खोजें (किसी भी भाषा में)';

  @override
  String get yourCrops => 'आपकी फसलें';

  @override
  String get addedByYou => 'आपके द्वारा जोड़ी गई';

  @override
  String get addAnotherCrop => 'दूसरी फसल जोड़ें';

  @override
  String get addCropTitle => 'फसल जोड़ें';

  @override
  String get addCropBody =>
      'सूची में नहीं है? उसका नाम किसी भी भाषा में लिखें। वह वैसे ही दिखेगा जैसा आप लिखेंगे।';

  @override
  String get addCropHint => 'फसल का नाम';

  @override
  String get addCropInvalid => '2 से 30 अक्षर लिखें';

  @override
  String addCropNamed(String name) {
    return '“$name” जोड़ें';
  }

  @override
  String get addButton => 'जोड़ें';

  @override
  String get noCropsMatch => 'सूची में इस नाम की कोई फसल नहीं है।';

  @override
  String get logoutQ => 'लॉग आउट करें?';

  @override
  String get logoutBody =>
      'वापस आने के लिए आपको अपने मोबाइल नंबर और OTP से फिर से लॉग इन करना होगा।';

  @override
  String signedInAs(String phone) {
    return '$phone से लॉग इन हैं';
  }

  @override
  String get email => 'ईमेल';

  @override
  String get emailNotSet => 'अपडेट पाने के लिए अपना ईमेल जोड़ें';

  @override
  String get changeButton => 'बदलें';

  @override
  String get emailDialogTitle => 'अपडेट के लिए ईमेल';

  @override
  String get emailDialogBody =>
      'हम आपके सत्यापन, जगहों और बुकिंग के बारे में आपकी ऐप भाषा में ईमेल करते हैं। ईमेल बंद करने के लिए इसे खाली छोड़ें।';

  @override
  String get emailInvalid => 'सही ईमेल पता दर्ज करें, जैसे name@example.com';

  @override
  String get emailSaved => 'ईमेल सेव हो गया';

  @override
  String get emailRemoved => 'ईमेल हटा दिया गया';

  @override
  String get emailOptional => 'ईमेल (वैकल्पिक)';

  @override
  String get verifierEmailHint =>
      'उन्हें स्वागत ईमेल और सौंपे गए हर किसान के लिए एक ईमेल मिलेगा।';
}
