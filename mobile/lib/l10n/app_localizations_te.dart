// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appTitle => 'ఆంగన్ మండి';

  @override
  String get chooseLanguage => 'మీ భాషను ఎంచుకోండి';

  @override
  String get continueButton => 'కొనసాగించండి';

  @override
  String get enterPhone => 'మీ మొబైల్ నంబర్ నమోదు చేయండి';

  @override
  String get sendOtp => 'OTP పంపండి';

  @override
  String enterOtp(String phone) {
    return '$phone కు పంపిన 6 అంకెల OTP నమోదు చేయండి';
  }

  @override
  String get verify => 'ధృవీకరించండి';

  @override
  String testOtp(String code) {
    return 'టెస్ట్ OTP: $code';
  }

  @override
  String get testOtpHint => 'టెస్టింగ్ మోడ్: SMS పంపబడదు';

  @override
  String get useTestOtp => 'నింపండి';

  @override
  String get whoAreYou => 'మీరు ఆంగన్ మండిని ఎలా ఉపయోగిస్తారు?';

  @override
  String get roleFarmer => 'నేను రైతును';

  @override
  String get roleFarmerHint => 'మీ పంటను కొనుగోలుదారుల దగ్గర అమ్మండి';

  @override
  String get roleHost => 'నా దగ్గర స్థలం ఉంది';

  @override
  String get roleHostHint => 'కొన్ని గంటలు మీ ఆవరణను ఇవ్వండి';

  @override
  String get roleBuyer => 'నాకు తాజా కూరగాయలు కావాలి';

  @override
  String get roleBuyerHint => 'రైతు దగ్గరలో ఉన్నప్పుడు సమాచారం పొందండి';

  @override
  String get settings => 'సెట్టింగ్‌లు';

  @override
  String get language => 'భాష';

  @override
  String get comingSoon => 'త్వరలో వస్తుంది';

  @override
  String get farmerHome => 'నా ప్రయాణాలు';

  @override
  String get hostHome => 'నా స్థలాలు';

  @override
  String get buyerHome => 'నా దగ్గరి దుకాణాలు';

  @override
  String get opsHome => 'కార్యకలాపాలు';

  @override
  String get errorGeneric => 'ఏదో తప్పు జరిగింది. దయచేసి మళ్ళీ ప్రయత్నించండి.';

  @override
  String get tagline => 'పొలం నుండి నేరుగా, మీ గేటు వద్దకు';

  @override
  String get featureVerified => 'తమ సొంత పంట అమ్మే ధృవీకరించిన రైతులు మాత్రమే';

  @override
  String get featureSpaces => 'ఇరుగుపొరుగువారు కొన్ని గంటలు తమ ఆవరణను ఇస్తారు';

  @override
  String get featureAlerts =>
      'దుకాణం తెరిచినప్పుడు దగ్గరలోని కొనుగోలుదారులకు సమాచారం';

  @override
  String get logout => 'లాగ్ అవుట్';

  @override
  String get retry => 'మళ్ళీ ప్రయత్నించండి';

  @override
  String get refresh => 'రిఫ్రెష్ చేయండి';

  @override
  String get next => 'తదుపరి';

  @override
  String get back => 'వెనుకకు';

  @override
  String get save => 'సేవ్ చేయండి';

  @override
  String get required => 'తప్పనిసరి';

  @override
  String get verifyNotStartedTitle => 'అమ్మకం ప్రారంభించడానికి ధృవీకరణ పొందండి';

  @override
  String get startVerification => 'ధృవీకరణ ప్రారంభించండి';

  @override
  String get continueVerification => 'ధృవీకరణ కొనసాగించండి';

  @override
  String get verifyPendingTitle => 'పరిశీలనలో ఉంది';

  @override
  String get verifyPendingBody =>
      'మా బృందం మీ వివరాలను తనిఖీ చేస్తోంది. సాధారణంగా 48 గంటలు పడుతుంది.';

  @override
  String get verifiedTitle => 'ధృవీకరించిన రైతు';

  @override
  String get verifiedBody =>
      'మీరు ధృవీకరించబడ్డారు. ప్రయాణాలు, స్థల బుకింగ్‌లు త్వరలో ప్రారంభమవుతాయి.';

  @override
  String get rejectedTitle => 'ధృవీకరణలో మార్పులు అవసరం';

  @override
  String rejectedReason(String reason) {
    return 'కారణం: $reason';
  }

  @override
  String get fixAndResubmit => 'సరిచేసి మళ్ళీ పంపండి';

  @override
  String get stepAboutYou => 'మీ గురించి';

  @override
  String get stepReview => 'పంపండి';

  @override
  String get verifyNotStartedBody =>
      'మీరు నిజమైన రైతు అని మేము తనిఖీ చేస్తాము. దాదాపు 5 నిమిషాలు పడుతుంది. వ్యవసాయ రుజువు ఒకటి సిద్ధంగా ఉంచుకోండి: అగ్రిస్టాక్ రైతు ID, భూమి లేదా సాగు రికార్డు, FPO సభ్యత్వం, లేదా వ్యవసాయ అధికారి లేఖ.';

  @override
  String get consentText =>
      'ఈ వివరాలు నిజమని నిర్ధారిస్తున్నాను. నన్ను ధృవీకరించడానికి ఆంగన్ మండి ఈ రుజువును నిల్వ చేయడానికి అంగీకరిస్తున్నాను.';

  @override
  String get stepEvidence => 'వ్యవసాయ రుజువు';

  @override
  String get farmSizeOptional => 'సుమారు పొలం విస్తీర్ణం ఎకరాల్లో (ఐచ్ఛికం)';

  @override
  String get farmSizeInvalid => '0 నుండి 1000 ఎకరాల మధ్య నమోదు చేయండి';

  @override
  String get produceSourceQuestion => 'మీరు పండించినదే అమ్ముతారా?';

  @override
  String get sourceOwnFarm => 'అవును, నేను పండించినదే';

  @override
  String get sourceOwnAndOthers => 'ఎక్కువగా నావి, కొన్ని ఇతర రైతుల నుండి';

  @override
  String get sourceOthers => 'లేదు, ఇతర రైతుల నుండి కొని అమ్ముతాను';

  @override
  String get evidenceQuestion => 'మీరు రైతు అని చూపే ఒక రుజువు ఎంచుకోండి';

  @override
  String get evidenceSubtitle =>
      'ఒక వెరిఫైయర్ దీన్ని తనిఖీ చేసి ఆమోదిస్తారు, సాధారణంగా 48 గంటల్లో.';

  @override
  String get evidenceAgriStack => 'అగ్రిస్టాక్ రైతు ID';

  @override
  String get evidenceAgriStackHint => 'మీ రైతు ID కార్డు లేదా SMS';

  @override
  String get evidenceLandRecord => 'భూమి లేదా సాగు రికార్డు';

  @override
  String get evidenceLandRecordHint =>
      'పట్టాదారు పాస్‌బుక్, ROR-1B, కౌలు ఒప్పందం లేదా పంట రికార్డు';

  @override
  String get evidenceFpo => 'FPO సభ్యత్వం లేదా సిఫార్సు';

  @override
  String get evidenceFpoHint =>
      'మీ రైతు ఉత్పత్తిదారుల సంస్థ సభ్యత్వ కార్డు లేదా లేఖ';

  @override
  String get evidenceOfficer => 'వ్యవసాయ అధికారి సిఫార్సు';

  @override
  String get evidenceOfficerHint =>
      'మీ వ్యవసాయ విస్తరణ అధికారి (AEO) లేదా గుర్తింపు పొందిన రైతు సంస్థ లేఖ';

  @override
  String get detailsAgriStack => 'రైతు ID సంఖ్య';

  @override
  String get detailsLandRecord => 'సర్వే నంబర్ (ఐచ్ఛికం)';

  @override
  String get detailsFpo => 'FPO పేరు, లేదా మిమ్మల్ని సిఫార్సు చేసినవారు';

  @override
  String get detailsOfficer => 'అధికారి లేదా సంస్థ పేరు, ఫోన్ నంబర్';

  @override
  String get evidencePhoto => 'రుజువు ఫోటో';

  @override
  String get evidencePhotoHint => 'మీ పేరు స్పష్టంగా కనిపించేలా తీయండి';

  @override
  String get fullName => 'పూర్తి పేరు';

  @override
  String get village => 'గ్రామం';

  @override
  String get district => 'జిల్లా';

  @override
  String get takePhoto => 'ఫోటో తీయండి';

  @override
  String get retakePhoto => 'మళ్ళీ తీయండి';

  @override
  String get uploaded => 'అప్‌లోడ్ అయింది';

  @override
  String get uploading => 'అప్‌లోడ్ అవుతోంది…';

  @override
  String get cropsYouGrow => 'మీరు పండించే పంటలు';

  @override
  String get useMyLocation => 'నా ప్రస్తుత స్థానం వాడండి';

  @override
  String get locationDenied => 'కొనసాగడానికి లొకేషన్ అనుమతి ఇవ్వండి';

  @override
  String get reviewChecklist => 'పంపే ముందు అన్నీ తనిఖీ చేయండి';

  @override
  String get submitForReview => 'పరిశీలనకు పంపండి';

  @override
  String get completeAllSteps => 'పంపే ముందు అన్ని దశలు పూర్తి చేయండి';

  @override
  String get submittedMessage => 'పంపబడింది. 48 గంటల్లో పరిశీలిస్తాము.';

  @override
  String get addSpace => 'స్థలం జోడించండి';

  @override
  String get noSpacesTitle => 'మీ మొదటి స్థలాన్ని జోడించండి';

  @override
  String get noSpacesBody =>
      'ధృవీకరించిన రైతుకు కొన్ని గంటలు మీ వాకిలి, ఆవరణ లేదా ఖాళీ స్థలం ఇవ్వండి. ఇరుగుపొరుగువారికి గేటు వద్దే తాజా కూరగాయలు.';

  @override
  String get spaceDetails => 'స్థలం వివరాలు';

  @override
  String get spaceName => 'స్థలం పేరు';

  @override
  String get spaceNameHint => 'ఉదాహరణ: గ్రీన్ విల్లా ఆవరణ';

  @override
  String get spaceType => 'స్థలం రకం';

  @override
  String get driveway => 'వాకిలి';

  @override
  String get courtyard => 'ఆవరణ';

  @override
  String get openArea => 'ఖాళీ స్థలం';

  @override
  String get commercialFrontage => 'దుకాణం ముందు భాగం';

  @override
  String get address => 'పూర్తి చిరునామా';

  @override
  String get addressHint => 'బుకింగ్ ఆమోదించిన తర్వాతే రైతుకు చూపిస్తాము';

  @override
  String get locality => 'ప్రాంతం';

  @override
  String get spaceLocation => 'స్థలం స్థానం';

  @override
  String get enterCoordinates => 'అక్షాంశ రేఖాంశాలు నమోదు చేయండి';

  @override
  String get latitude => 'అక్షాంశం';

  @override
  String get longitude => 'రేఖాంశం';

  @override
  String get areaSqFt => 'వాడుకోగల విస్తీర్ణం (చ. అడుగులు)';

  @override
  String get maxVehicle => 'లోపలికి రాగల అతిపెద్ద వాహనం';

  @override
  String get twoWheeler => 'ద్విచక్ర వాహనం';

  @override
  String get auto => 'ఆటో';

  @override
  String get miniTruck => 'మినీ ట్రక్';

  @override
  String get tractor => 'ట్రాక్టర్';

  @override
  String get amenities => 'సౌకర్యాలు';

  @override
  String get water => 'నీరు';

  @override
  String get shade => 'నీడ';

  @override
  String get powerPoint => 'కరెంట్ పాయింట్';

  @override
  String get buyerParking => 'కొనుగోలుదారులకు పార్కింగ్';

  @override
  String get loadingAccess => 'సరుకు దించే సౌకర్యం';

  @override
  String get toilet => 'మరుగుదొడ్డి';

  @override
  String get pricing => 'ధర';

  @override
  String get freeSpace => 'ఉచిత సామాజిక స్థలం';

  @override
  String get feePerSlot => 'ఒక్కో స్లాట్ రుసుము (₹)';

  @override
  String get availability => 'అందుబాటు';

  @override
  String get availableDays => 'అందుబాటులో ఉండే రోజులు';

  @override
  String get openFrom => 'నుండి';

  @override
  String get openTo => 'వరకు';

  @override
  String get slotRule => 'ప్రతి స్లాట్ 2 నుండి 6 గంటలు ఉండాలి';

  @override
  String get houseRules => 'నియమాలు (ఐచ్ఛికం)';

  @override
  String get houseRulesHint =>
      'ఉదాహరణ: చేపలు, మాంసం వద్దు; అమ్మిన తర్వాత శుభ్రం చేయాలి';

  @override
  String get spacePhotos => 'స్థలం ఫోటోలు (3 నుండి 8)';

  @override
  String get addPhotos => 'ఫోటోలు జోడించండి';

  @override
  String get proofOfRight => 'ఈ స్థలాన్ని వాడే హక్కు రుజువు';

  @override
  String get proofHint =>
      'యాజమాన్య పత్రం, అద్దె ఒప్పందం లేదా సొసైటీ లేఖ. కొనుగోలుదారులకు ఎప్పుడూ చూపించము.';

  @override
  String get submitSpace => 'ఆమోదానికి పంపండి';

  @override
  String get spaceSubmitted =>
      'ఆమోదానికి పంపబడింది. సాధారణంగా 48 గంటల్లో పరిశీలిస్తాము.';

  @override
  String get statusDraft => 'డ్రాఫ్ట్';

  @override
  String get statusPendingReview => 'ఆమోదం కోసం వేచి ఉంది';

  @override
  String get statusLive => 'ప్రత్యక్షం';

  @override
  String get statusRejected => 'మార్పులు అవసరం';

  @override
  String perSlot(String fee) {
    return 'ఒక్కో స్లాట్ ₹$fee';
  }

  @override
  String get free => 'ఉచితం';

  @override
  String get photosNeeded => 'కనీసం 3 ఫోటోలు, రుజువు పత్రం జోడించండి';

  @override
  String get finishAndSubmit => 'పూర్తి చేసి పంపండి';

  @override
  String get addMorePhotos => 'మరిన్ని ఫోటోలు జోడించండి';

  @override
  String get buyerComingSoon =>
      'రైతులు అమ్మడం ప్రారంభించిన తర్వాత మీ దగ్గరి దుకాణాలు ఇక్కడ కనిపిస్తాయి.';
}
