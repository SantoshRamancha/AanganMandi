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
  String get farmerHome => 'मेरी यात्राएँ';

  @override
  String get hostHome => 'मेरी जगहें';

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
      'आप सत्यापित हैं। यात्राएँ और जगह बुकिंग जल्द शुरू होंगी।';

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
}
