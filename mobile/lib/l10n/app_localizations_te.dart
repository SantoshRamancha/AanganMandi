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
  String get farmerHome => 'హోమ్';

  @override
  String get hostHome => 'హోమ్';

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
      'మీరు ధృవీకరించబడ్డారు. అమ్మడం ప్రారంభించడానికి ప్రయాణం ప్లాన్ చేసి స్థలం బుక్ చేయండి.';

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

  @override
  String get profileTitle => 'నా ప్రొఫైల్';

  @override
  String get accountDetails => 'ఖాతా వివరాలు';

  @override
  String get name => 'పేరు';

  @override
  String get nameNotSet => 'ఇంకా జోడించలేదు';

  @override
  String get mobileNumber => 'మొబైల్ నంబర్';

  @override
  String get memberSince => 'చేరిన తేదీ';

  @override
  String get yourRoles => 'యాప్‌ను ఇలా ఉపయోగిస్తున్నారు';

  @override
  String get roleNameFarmer => 'రైతు';

  @override
  String get roleNameHost => 'స్థల యజమాని';

  @override
  String get roleNameBuyer => 'కొనుగోలుదారు';

  @override
  String get roleNameVerifier => 'ధృవీకరణ అధికారి';

  @override
  String get roleNameAdmin => 'అడ్మిన్';

  @override
  String get verificationStatus => 'ధృవీకరణ';

  @override
  String get farmDetails => 'వ్యవసాయ వివరాలు';

  @override
  String get crops => 'పంటలు';

  @override
  String get mySpaces => 'నా స్థలాలు';

  @override
  String mySpacesSummary(int count, int live) {
    return '$count జాబితాలో · $live లైవ్';
  }

  @override
  String get appearance => 'రూపం';

  @override
  String get themeSystem => 'సిస్టమ్';

  @override
  String get themeLight => 'లైట్';

  @override
  String get themeDark => 'డార్క్';

  @override
  String get themeSystemHint =>
      'సిస్టమ్ మీ ఫోన్ లేదా కంప్యూటర్ సెట్టింగ్‌ను అనుసరిస్తుంది.';

  @override
  String get staffAccessRevokedTitle => 'మీకు ఇక సిబ్బంది యాక్సెస్ లేదు';

  @override
  String get staffAccessRevokedBody =>
      'ఇది పొరపాటు అనిపిస్తే అడ్మిన్‌ను అడగండి. మీ ఇతర ఖాతాతో కొనసాగడానికి లాగ్ అవుట్ చేయండి.';

  @override
  String get opsTabDashboard => 'డాష్‌బోర్డ్';

  @override
  String get opsTabFarmers => 'రైతులు';

  @override
  String get opsTabSpaces => 'స్థలాలు';

  @override
  String get opsTabVerifiers => 'ధృవీకరణ అధికారులు';

  @override
  String opsHello(String name) {
    return 'నమస్కారం, $name';
  }

  @override
  String get opsHelloNoName => 'నమస్కారం';

  @override
  String get opsAdminSubtitle =>
      'అడ్మిన్ · మీరు అందరు రైతులను చూస్తారు, ధృవీకరణ అధికారులను నిర్వహిస్తారు';

  @override
  String get opsVerifierSubtitle =>
      'ధృవీకరణ అధికారి · మీకు కేటాయించిన రైతులను మీరు సమీక్షిస్తారు';

  @override
  String get statFarmersWaitingAll => 'సమీక్ష కోసం వేచి ఉన్న రైతులు';

  @override
  String get statFarmersWaitingYou => 'మీ కోసం వేచి ఉన్న రైతులు';

  @override
  String get statUnassigned => 'ధృవీకరణ అధికారి లేకుండా వేచి ఉన్నవి';

  @override
  String get statSpacesWaiting => 'ఆమోదం కోసం వేచి ఉన్న స్థలాలు';

  @override
  String get statVerifiedAll => 'ధృవీకరించిన రైతులు';

  @override
  String get statVerifiedYou => 'మీరు ధృవీకరించిన రైతులు';

  @override
  String get statSpacesLive => 'లైవ్ స్థలాలు';

  @override
  String get couldNotLoad =>
      'లోడ్ కాలేదు. మళ్లీ ప్రయత్నించడానికి కిందకు లాగండి లేదా రిఫ్రెష్ నొక్కండి.';

  @override
  String get couldNotSave => 'సేవ్ కాలేదు. మళ్లీ ప్రయత్నించండి.';

  @override
  String get emptyList => 'ఈ జాబితాలో ఏమీ లేదు.';

  @override
  String get noName => '(పేరు లేదు)';

  @override
  String get decision => 'నిర్ణయం';

  @override
  String get reasonLabel =>
      'కారణం (తిరస్కరించడానికి తప్పనిసరి; వారికి కనిపిస్తుంది)';

  @override
  String get reject => 'తిరస్కరించు';

  @override
  String rejectedWith(String reason) {
    return 'తిరస్కరించారు: $reason';
  }

  @override
  String get unassigned => 'కేటాయించలేదు';

  @override
  String get farmerStatusPending => 'సమీక్ష కోసం వేచి ఉంది';

  @override
  String get farmerStatusVerified => 'ధృవీకరించబడింది';

  @override
  String get farmerStatusRejected => 'తిరస్కరించబడింది';

  @override
  String get farmerStatusNotStarted => 'సమర్పించలేదు';

  @override
  String get farmerVerificationTitle => 'రైతు ధృవీకరణ';

  @override
  String get farmerQueueAdminHint =>
      'అందరు రైతులు. ప్రతి సమర్పణ తక్కువ పెండింగ్ ఉన్న ధృవీకరణ అధికారికి వెళ్తుంది.';

  @override
  String get farmerQueueVerifierHint =>
      'మీకు కేటాయించిన రైతులు, పాతవి ముందుగా.';

  @override
  String get noVerifierWarnTitle => 'కొందరు రైతులకు ధృవీకరణ అధికారి లేరు';

  @override
  String get noVerifierWarnBody =>
      'ధృవీకరణ అధికారిని జోడిస్తే రైతులు ఆటోమేటిగ్గా కేటాయించబడతారు, లేదా రైతును తెరిచి ఒకరిని కేటాయించండి.';

  @override
  String submittedOn(String when) {
    return 'సమర్పించినది $when';
  }

  @override
  String verifierIs(String name) {
    return 'ధృవీకరణ అధికారి: $name';
  }

  @override
  String get reviewFarmer => 'రైతును సమీక్షించండి';

  @override
  String get qrFarmerPhotoUnclear =>
      'ఆధార ఫోటో స్పష్టంగా లేదు — దయచేసి మళ్లీ తీయండి';

  @override
  String get qrFarmerNameMismatch => 'ఆధారంలోని పేరు సరిపోలడం లేదు';

  @override
  String get qrFarmerIdUnconfirmed => 'రైతు ID నిర్ధారించలేకపోయాము';

  @override
  String get qrFarmerRefereeNo => 'సిఫార్సు చేసినవారు మిమ్మల్ని నిర్ధారించలేదు';

  @override
  String get qrFarmerNotGrower =>
      'మీరు ఇతర రైతుల నుండి కొన్న పంట మాత్రమే అమ్ముతున్నారు';

  @override
  String phoneOtpVerified(String phone) {
    return '$phone (OTP ధృవీకరించబడింది)';
  }

  @override
  String get farmSize => 'పొలం విస్తీర్ణం';

  @override
  String get notGiven => 'ఇవ్వలేదు';

  @override
  String aboutAcres(String acres) {
    return 'సుమారు $acres ఎకరాలు';
  }

  @override
  String get sells => 'అమ్మేది';

  @override
  String get sellsOwnFarm => 'వారు పండించినది మాత్రమే';

  @override
  String get sellsOwnAndOthers => 'సొంత పంట, కొంత ఇతర రైతుల నుండి';

  @override
  String get sellsOthers => 'ఇతర రైతుల పంట మాత్రమే (పండించేవారు కాదు)';

  @override
  String get submitted => 'సమర్పించినది';

  @override
  String get farmingEvidence => 'వ్యవసాయ ఆధారం';

  @override
  String get factType => 'రకం';

  @override
  String get factDetails => 'వివరాలు';

  @override
  String get noPhoto => 'ఫోటో లేదు';

  @override
  String get olderDocuments => 'మునుపటి ధృవీకరణ పత్రాలు';

  @override
  String get howCheckAgriStack =>
      'AgriStack రైతు రిజిస్ట్రీలో రైతు ID నంబర్ మరియు పేరు తనిఖీ చేయండి.';

  @override
  String get howCheckLandRecord =>
      'భూ భారతి పోర్టల్‌లో యజమాని లేదా సాగుదారు పేరు, సర్వే నంబర్ తనిఖీ చేయండి.';

  @override
  String get howCheckFpo =>
      'FPO (లేదా సిఫార్సు చేసిన వ్యక్తి)కి ఫోన్ చేసి ఈ రైతు వారికి తెలుసని నిర్ధారించండి.';

  @override
  String get howCheckOfficer =>
      'అధికారి లేదా సంస్థకు ఫోన్ చేసి ఈ రైతు వారికి తెలుసని నిర్ధారించండి.';

  @override
  String get farmerApproveGuidance =>
      'ఆధారం నిజమైనది, దానిపై పేరు ఈ రైతుదే, వారు అమ్మేది వారే పండిస్తారు అయితేనే ఆమోదించండి.';

  @override
  String get farmerApproveLabel => 'ఆమోదించు — ధృవీకరించిన రైతు';

  @override
  String farmerApprovedToast(String name) {
    return 'ఆమోదించారు: $name ధృవీకరించిన రైతు';
  }

  @override
  String get farmerRejectedToast =>
      'తిరస్కరించారు. రైతుకు మీ కారణం కనిపిస్తుంది.';

  @override
  String get assignedTo => 'కేటాయించినది';

  @override
  String get assignedOn => 'కేటాయించిన తేదీ';

  @override
  String get reviewedBy => 'సమీక్షించినవారు';

  @override
  String get verifierAssignedToast => 'ధృవీకరణ అధికారిని కేటాయించారు';

  @override
  String get noVerifiersYetAssign =>
      'ఇంకా ధృవీకరణ అధికారులు లేరు. ధృవీకరణ అధికారులు ట్యాబ్‌లో జోడించండి.';

  @override
  String get chooseVerifier => 'ధృవీకరణ అధికారిని ఎంచుకోండి';

  @override
  String verifierOption(String name, int count) {
    return '$name ($count వేచి ఉన్నాయి)';
  }

  @override
  String get assign => 'కేటాయించు';

  @override
  String get reassign => 'మళ్లీ కేటాయించు';

  @override
  String get spaceApprovals => 'స్థల ఆమోదాలు';

  @override
  String hostedBy(String host, String when) {
    return 'యజమాని: $host · నవీకరించినది $when';
  }

  @override
  String get reviewSpace => 'స్థలాన్ని సమీక్షించండి';

  @override
  String get qrSpacePublicRoad => 'స్థలం పబ్లిక్ రోడ్డు లేదా ఫుట్‌పాత్‌పై ఉంది';

  @override
  String get qrSpacePhotos => 'ఫోటోలు స్పష్టంగా లేవు లేదా స్థలాన్ని చూపడం లేదు';

  @override
  String get qrSpaceProof =>
      'ఈ స్థలాన్ని ఉపయోగించే హక్కు పత్రంలో కనిపించడం లేదు';

  @override
  String get qrSpacePin => 'లొకేషన్ పిన్ చిరునామాతో సరిపోలడం లేదు';

  @override
  String get spaceSection => 'స్థలం';

  @override
  String get usableArea => 'ఉపయోగించగల విస్తీర్ణం';

  @override
  String areaValue(int area, String stall) {
    return '$area చ.అడుగులు (స్టాల్ $stall వరకు)';
  }

  @override
  String get none => 'ఏమీ లేవు';

  @override
  String get openInMaps => 'మ్యాప్స్‌లో లొకేషన్ తెరవండి';

  @override
  String get availabilityAndHost => 'అందుబాటు మరియు యజమాని';

  @override
  String get hours => 'సమయం';

  @override
  String get fee => 'రుసుము';

  @override
  String get freeCommunitySpace => 'ఉచిత సామూహిక స్థలం';

  @override
  String get rules => 'ఇంటి నియమాలు';

  @override
  String get host => 'యజమాని';

  @override
  String get proofMissing => 'రుజువు లేదు';

  @override
  String photosCount(int count) {
    return 'ఫోటోలు ($count)';
  }

  @override
  String get spaceApproveGuidance =>
      'ఇది ప్రైవేట్ స్థలం (రోడ్డు లేదా ఫుట్‌పాత్ కాదు), ఫోటోలు లొకేషన్‌తో సరిపోలుతాయి, రుజువులో యజమాని పేరు ఉంది లేదా ఉపయోగానికి అనుమతి ఉంది అయితేనే ఆమోదించండి.';

  @override
  String get spaceApproveLabel => 'ఆమోదించు — లైవ్ చేయి';

  @override
  String spaceLiveToast(String title) {
    return '$title లైవ్ అయింది';
  }

  @override
  String get spaceRejectedToast =>
      'తిరస్కరించారు. యజమానికి మీ కారణం కనిపిస్తుంది.';

  @override
  String get verifiersHint =>
      'సమర్పించిన ప్రతి రైతు తక్కువ పెండింగ్ ఉన్న ధృవీకరణ అధికారికి వెళ్తారు; మళ్లీ సమర్పిస్తే అదే అధికారికి వెళ్తారు.';

  @override
  String get addVerifierTitle => 'ధృవీకరణ అధికారిని జోడించండి';

  @override
  String get addVerifierButton => 'జోడించు';

  @override
  String get enterName => 'పేరు నమోదు చేయండి';

  @override
  String get enterTenDigits => '10 అంకెల నంబర్ నమోదు చేయండి';

  @override
  String verifierAddedToast(String name, String phone) {
    return '$nameను జోడించారు. వారు +91 $phoneతో లాగిన్ అవ్వవచ్చు.';
  }

  @override
  String farmersAssignedToNew(int count) {
    return 'వేచి ఉన్న $count రైతులను వారికి కేటాయించారు.';
  }

  @override
  String removeVerifierQ(String name) {
    return '$nameను తొలగించాలా?';
  }

  @override
  String get removeVerifierBody =>
      'వారు ఇక రైతులను లేదా స్థలాలను సమీక్షించలేరు.';

  @override
  String removeVerifierMoves(int count) {
    return 'వారి వద్ద వేచి ఉన్న $count రైతులు ఇతర అధికారులకు వెళ్తారు.';
  }

  @override
  String get cancel => 'రద్దు';

  @override
  String get remove => 'తొలగించు';

  @override
  String verifierRemovedToast(String name) {
    return '$nameను తొలగించారు.';
  }

  @override
  String farmersMoved(int count) {
    return 'వేచి ఉన్న $count రైతులు ఇతర అధికారులకు వెళ్లారు.';
  }

  @override
  String farmersNowUnassigned(int count) {
    return '$count రైతులు ఇప్పుడు ఎవరికీ కేటాయించబడలేదు: వారి కోసం ధృవీకరణ అధికారిని జోడించండి.';
  }

  @override
  String get noVerifiersBody =>
      'ఇంకా ధృవీకరణ అధికారులు లేరు. మీరు ఒకరిని జోడించే వరకు సమర్పించిన రైతులు కేటాయించబడరు.';

  @override
  String verifierAddedOn(String phone, String when) {
    return '$phone · జోడించినది $when';
  }

  @override
  String verifierCounts(int waiting, int reviewed) {
    return '$waiting వేచి ఉన్నాయి · $reviewed సమీక్షించారు';
  }

  @override
  String get removeVerifierTooltip => 'ధృవీకరణ అధికారిని తొలగించు';

  @override
  String get preview => 'చూడండి';

  @override
  String get download => 'డౌన్‌లోడ్';

  @override
  String get reupload => 'మళ్లీ అప్‌లోడ్';

  @override
  String get delete => 'తొలగించు';

  @override
  String get close => 'మూసివేయి';

  @override
  String get uploadPhoto => 'ఫోటో అప్‌లోడ్ చేయండి';

  @override
  String get downloadSaved => 'డౌన్‌లోడ్ అయింది';

  @override
  String get downloadFailed => 'డౌన్‌లోడ్ కాలేదు. మళ్లీ ప్రయత్నించండి.';

  @override
  String get deleteDocumentQ => 'ఈ ఫోటోను తొలగించాలా?';

  @override
  String get deleteDocumentBody => 'తర్వాత కొత్తది అప్‌లోడ్ చేయవచ్చు.';

  @override
  String get documentLocked => 'ఆమోదించబడింది — దీన్ని ఇక మార్చలేరు.';

  @override
  String get evidenceWithdrawWarning =>
      'మీ ధృవీకరణ సమీక్ష కోసం వేచి ఉంది. ఆధారాన్ని తొలగిస్తే అది క్యూ నుండి తొలగిపోతుంది: కొత్త ఫోటో అప్‌లోడ్ చేసి మళ్లీ సమర్పించండి.';

  @override
  String get evidenceWithdrawnToast =>
      'ఫోటో తొలగించబడింది. కొత్తది అప్‌లోడ్ చేసి మళ్లీ సమర్పించండి.';

  @override
  String get spaceWithdrawWarning =>
      'ఈ స్థలం ఆమోదం కోసం వేచి ఉంది. 3 కంటే తక్కువ ఫోటోలు లేదా రుజువు లేకపోతే, అది డ్రాఫ్ట్‌కు వెళ్తుంది, మీరు మళ్లీ సమర్పించాలి.';

  @override
  String get spaceWithdrawnToast =>
      'ఫోటో తొలగించబడింది. స్థలం డ్రాఫ్ట్‌కు వెళ్లింది: లేనివి జోడించి మళ్లీ సమర్పించండి.';

  @override
  String get photoDeletedToast => 'ఫోటో తొలగించబడింది';

  @override
  String photoNumber(int number) {
    return 'ఫోటో $number';
  }

  @override
  String get yourDocument => 'మీ పత్రం';

  @override
  String get yourDocumentPendingHint =>
      'సమీక్ష కోసం వేచి ఉన్నప్పుడు కూడా దీన్ని మార్చవచ్చు లేదా తొలగించవచ్చు.';

  @override
  String get bookingRequested => 'యజమాని కోసం వేచి ఉంది';

  @override
  String get bookingAccepted => 'స్థలం బుక్ అయింది';

  @override
  String get bookingDeclined => 'తిరస్కరించారు';

  @override
  String get bookingCancelled => 'రద్దయింది';

  @override
  String get tripPlanned => 'ప్లాన్ చేసింది';

  @override
  String get tripCompleted => 'పూర్తయింది';

  @override
  String kgAmount(String amount) {
    return '$amount కిలోలు';
  }

  @override
  String pricePerKgAmount(String price) {
    return '₹$price/కిలో';
  }

  @override
  String get bookingSlotTaken => 'ఈ రోజుకు యజమాని మరో రైతును నిర్ధారించారు.';

  @override
  String bookingDeclinedBecause(String reason) {
    return 'యజమాని తిరస్కరించారు: $reason';
  }

  @override
  String bookingHostCancelled(String reason) {
    return 'యజమాని రద్దు చేశారు: $reason';
  }

  @override
  String get bookingYouCancelled => 'మీరు ఈ బుకింగ్‌ను రద్దు చేశారు.';

  @override
  String upToVehicle(String vehicle) {
    return '$vehicle వరకు సరిపోతుంది';
  }

  @override
  String get myTrips => 'నా ప్రయాణాలు';

  @override
  String get planTrip => 'ప్రయాణం ప్లాన్ చేయండి';

  @override
  String get noTripsTitle => 'ఇంకా ప్రయాణాలు లేవు';

  @override
  String get noTripsBody =>
      'అమ్మడానికి నగరానికి వచ్చే రోజును ప్లాన్ చేసి, మీ కొనుగోలుదారుల దగ్గర స్థలం బుక్ చేయండి.';

  @override
  String get noSpaceYet => 'ఇంకా స్థలం బుక్ కాలేదు';

  @override
  String get editTrip => 'ప్రయాణం మార్చండి';

  @override
  String get tripWhen => 'మీరు ఎప్పుడు వస్తున్నారు?';

  @override
  String get tripDateLocked =>
      'స్థలం అభ్యర్థించినప్పుడు లేదా బుక్ అయినప్పుడు తేదీ, వాహనం మార్చలేరు. మార్చడానికి బుకింగ్ రద్దు చేయండి.';

  @override
  String get chooseDate => 'తేదీ ఎంచుకోండి';

  @override
  String get tripVehicle => 'మీ వాహనం';

  @override
  String get tripVehicleHint => 'అది లోపలికి వెళ్లగల స్థలాలే చూపిస్తాము.';

  @override
  String get tripProduce => 'మీరు ఏమి తెస్తారు?';

  @override
  String get tripProduceHint =>
      'పంటలు ఎంచుకోండి. పరిమాణం, ధర ఐచ్ఛికం — యజమానికి ఉపయోగపడతాయి.';

  @override
  String get quantityKg => 'కిలోలు';

  @override
  String get priceKg => 'కిలోకు ₹';

  @override
  String get tripWhere => 'ఎక్కడ అమ్మాలనుకుంటున్నారు?';

  @override
  String get preferredArea => 'ప్రాంతం (ఐచ్ఛికం)';

  @override
  String get preferredAreaHint => 'ఉదా. అమీర్‌పేట్, కూకట్‌పల్లి';

  @override
  String get tripNotes => 'గమనికలు (ఐచ్ఛికం)';

  @override
  String get saveTripFindSpace => 'సేవ్ చేసి స్థలం వెతకండి';

  @override
  String get tripNeedsDateAndCrop => 'తేదీ మరియు కనీసం ఒక పంట ఎంచుకోండి';

  @override
  String get cancelTrip => 'ప్రయాణం రద్దు';

  @override
  String get cancelTripQ => 'ఈ ప్రయాణాన్ని రద్దు చేయాలా?';

  @override
  String get cancelTripBody =>
      'దీని కోసం అభ్యర్థించిన లేదా బుక్ చేసిన స్థలం కూడా రద్దవుతుంది, యజమానికి తెలియజేయబడుతుంది.';

  @override
  String get tripCancelledToast => 'ప్రయాణం రద్దయింది';

  @override
  String get tripDetails => 'ప్రయాణం';

  @override
  String get cancelBookingQ => 'ఈ బుకింగ్‌ను రద్దు చేయాలా?';

  @override
  String get cancelBookingBody =>
      'అవతలి వారికి తెలియజేయబడుతుంది, స్లాట్ మళ్లీ ఖాళీ అవుతుంది.';

  @override
  String get cancelBooking => 'బుకింగ్ రద్దు';

  @override
  String get bookingCancelledToast => 'బుకింగ్ రద్దయింది';

  @override
  String get spaceBookedTitle => 'స్థలం బుక్ అయింది — అక్కడ కలుద్దాం';

  @override
  String get payAtSpace => 'స్థలం వద్ద యజమానికి చెల్లించండి';

  @override
  String get callHost => 'యజమానికి ఫోన్';

  @override
  String get waitingForHostTitle => 'యజమాని కోసం వేచి ఉంది';

  @override
  String get waitingForHostBody =>
      'యజమాని మీ అభ్యర్థనను అంగీకరిస్తారు లేదా తిరస్కరిస్తారు. అంగీకరించిన తర్వాత చిరునామా, ఫోన్ నంబర్ కనిపిస్తాయి.';

  @override
  String get cancelRequest => 'అభ్యర్థన రద్దు';

  @override
  String get spaceForTrip => 'ఈ ప్రయాణానికి స్థలం';

  @override
  String get findSpaceIntro =>
      'ఈ రోజు తెరిచి ఉండి, మీ వాహనానికి సరిపోయే స్థలం వెతకండి.';

  @override
  String get findAnotherSpaceIntro => 'ఈ రోజుకు మరో స్థలం అభ్యర్థించవచ్చు.';

  @override
  String get findSpace => 'స్థలం వెతకండి';

  @override
  String get findAnotherSpace => 'మరో స్థలం వెతకండి';

  @override
  String get tripWasCancelled => 'ఈ ప్రయాణం రద్దయింది.';

  @override
  String get tripIsOver => 'ఈ ప్రయాణం తేదీ గడిచిపోయింది.';

  @override
  String requestSpaceTitle(String title) {
    return '$title అభ్యర్థించండి';
  }

  @override
  String get messageToHost => 'యజమానికి సందేశం (ఐచ్ఛికం)';

  @override
  String get messageToHostHint => 'ఉదా. ఆటోలో 3 టమాటా పెట్టెలతో వస్తాను';

  @override
  String get sendRequest => 'అభ్యర్థన పంపండి';

  @override
  String get requestSentToast =>
      'అభ్యర్థన పంపబడింది. సమాధానం మీ ప్రయాణంలో కనిపిస్తుంది.';

  @override
  String spacesFor(String date) {
    return '$date కి స్థలాలు';
  }

  @override
  String get searchArea => 'ప్రాంతం వెతకండి (ఉదా. అమీర్‌పేట్)';

  @override
  String get clear => 'తీసివేయి';

  @override
  String spacesMatchHint(String vehicle) {
    return 'ఆ రోజు తెరిచి ఉండి, మీ $vehicleకి సరిపోయే స్థలాలు. యజమాని అంగీకరించిన తర్వాత పూర్తి చిరునామా ఇవ్వబడుతుంది.';
  }

  @override
  String get noSpacesThatDay =>
      'ఈ రోజు మీ వాహనానికి సరిపోయే ఖాళీ స్థలాలు లేవు. మరో తేదీ ప్రయత్నించండి.';

  @override
  String get noSpacesInArea =>
      'ఈ రోజు ఈ ప్రాంతంలో ఖాళీ స్థలాలు లేవు. అన్ని ప్రాంతాలు చూడటానికి శోధన తీసివేయండి.';

  @override
  String get requestThisSpace => 'ఈ స్థలం అభ్యర్థించండి';

  @override
  String get bookings => 'బుకింగ్‌లు';

  @override
  String get bookingsHint => 'రైతుల అభ్యర్థనలు మరియు నిర్ధారించిన రోజులు';

  @override
  String requestsWaiting(int count) {
    return '$count రైతులు మీ సమాధానం కోసం వేచి ఉన్నారు';
  }

  @override
  String requestsCount(int count) {
    return 'అభ్యర్థనలు ($count)';
  }

  @override
  String get bookingRequestsTab => 'అభ్యర్థనలు';

  @override
  String get upcomingTab => 'రాబోయేవి';

  @override
  String get pastTab => 'గతం';

  @override
  String get noRequests =>
      'కొత్త అభ్యర్థనలు లేవు. మీ స్థలాల కోసం రైతుల అభ్యర్థనలు ఇక్కడ కనిపిస్తాయి.';

  @override
  String get noUpcoming => 'రాబోయే నిర్ధారిత బుకింగ్‌లు లేవు.';

  @override
  String get noPastBookings => 'ఇంకా గత బుకింగ్‌లు లేవు.';

  @override
  String get reasonForFarmer => 'కారణం (రైతుకు కనిపిస్తుంది)';

  @override
  String get verifiedFarmerTag => 'ధృవీకరించిన రైతు';

  @override
  String get hostAutoDeclined =>
      'ఆటోమేటిగ్గా తిరస్కరించబడింది: ఈ రోజుకు మీరు మరో రైతును నిర్ధారించారు.';

  @override
  String get farmerCancelled => 'రైతు రద్దు చేశారు.';

  @override
  String yourReason(String reason) {
    return 'కారణం: $reason';
  }

  @override
  String get accept => 'అంగీకరించు';

  @override
  String get decline => 'తిరస్కరించు';

  @override
  String get acceptedToast =>
      'అంగీకరించారు. ఇప్పుడు రైతుకు మీ చిరునామా, ఫోన్ కనిపిస్తాయి.';

  @override
  String get declineQ => 'ఈ అభ్యర్థనను తిరస్కరించాలా?';

  @override
  String get qrNotAvailableDay => 'ఆ రోజు స్థలం అందుబాటులో లేదు';

  @override
  String get qrVehicleTooBig => 'వాహనం సరిపోదు';

  @override
  String get qrOnlySomeProduce => 'ఈ రకమైన పంటకు స్థలం ఇవ్వలేను';

  @override
  String get declinedToast => 'అభ్యర్థన తిరస్కరించబడింది';

  @override
  String get callFarmer => 'రైతుకు ఫోన్';

  @override
  String get newRequest => 'కొత్త అభ్యర్థన';

  @override
  String greetingName(String name) {
    return 'నమస్కారం, $name';
  }

  @override
  String get greetingNoName => 'నమస్కారం';

  @override
  String get farmerBannerVerified =>
      'మీరు ధృవీకరించిన రైతు. మీ తదుపరి అమ్మకం రోజును ప్లాన్ చేయండి.';

  @override
  String get farmerBannerNotVerified =>
      'ఒక్కసారి ధృవీకరణ పొందండి, తర్వాత నగరంలో మీ తాజా పంటను అమ్మండి.';

  @override
  String get statUpcomingTrips => 'రాబోయే ప్రయాణాలు';

  @override
  String get statSpacesBooked => 'బుక్ అయిన స్థలాలు';

  @override
  String get statWaitingHost => 'యజమాని కోసం వేచి ఉన్నవి';

  @override
  String get statCompletedTrips => 'పూర్తయిన ప్రయాణాలు';

  @override
  String get nextTrip => 'మీ తదుపరి ప్రయాణం';

  @override
  String get noUpcomingTitle => 'ప్రయాణం ప్లాన్ చేయలేదు';

  @override
  String get noUpcomingBody =>
      'నగరానికి వచ్చే రోజును ఎంచుకుని, కొనుగోలుదారుల దగ్గర స్థలం బుక్ చేయండి.';

  @override
  String get viewTrip => 'ప్రయాణం చూడండి';

  @override
  String get allTrips => 'అన్ని ప్రయాణాలు';

  @override
  String get yourVerification => 'మీ ధృవీకరణ';

  @override
  String get howItWorks => 'ఇది ఎలా పనిచేస్తుంది';

  @override
  String get howStepVerify => 'ధృవీకరణ పొందండి';

  @override
  String get howStepVerifyBody =>
      'మీ వ్యవసాయం గురించి చెప్పి ఒక రుజువు జోడించండి. ధృవీకరణ అధికారి తనిఖీ చేస్తారు.';

  @override
  String get howStepTrip => 'ప్రయాణం ప్లాన్ చేయండి';

  @override
  String get howStepTripBody => 'రోజు, మీ వాహనం, మీరు తెచ్చే పంట ఎంచుకోండి.';

  @override
  String get howStepBook => 'స్థలం బుక్ చేయండి';

  @override
  String get howStepBookBody =>
      'కొనుగోలుదారుల దగ్గర డ్రైవ్‌వే లేదా ప్రాంగణం అభ్యర్థించండి. యజమాని అంగీకరిస్తారు.';

  @override
  String get howStepSell => 'తాజాగా అమ్మండి';

  @override
  String get howStepSellBody =>
      'మీ స్టాల్ పెట్టి దగ్గరి కుటుంబాలకు నేరుగా అమ్మండి.';

  @override
  String bookedAt(String space) {
    return '$space వద్ద బుక్ అయింది';
  }

  @override
  String waitingAt(String space) {
    return '$space అంగీకారం కోసం వేచి ఉంది';
  }

  @override
  String hostBanner(int live, int waiting) {
    return 'లైవ్ స్థలాలు: $live · కొత్త అభ్యర్థనలు: $waiting';
  }

  @override
  String get hostBannerNew =>
      'మీ డ్రైవ్‌వే లేదా ప్రాంగణాన్ని జాబితాలో పెట్టి, రైతులు అమ్మినప్పుడు సంపాదించండి.';

  @override
  String get statNewRequests => 'కొత్త అభ్యర్థనలు';

  @override
  String get statUpcomingBookings => 'రాబోయే బుకింగ్‌లు';

  @override
  String get needsYourAnswer => 'మీ సమాధానం కావాలి';

  @override
  String get viewAll => 'అన్నీ చూడండి';

  @override
  String get nextBooking => 'తదుపరి బుకింగ్';

  @override
  String get noBookingYet =>
      'ఇంకా నిర్ధారిత బుకింగ్‌లు లేవు. అంగీకరించిన అభ్యర్థనలు ఇక్కడ కనిపిస్తాయి.';

  @override
  String get answer => 'సమాధానం';

  @override
  String get hostHowList => 'మీ స్థలాన్ని జాబితాలో పెట్టండి';

  @override
  String get hostHowListBody =>
      'ఫోటోలు, రోజులు, సమయం, రుసుము, మరియు స్థలం ఉపయోగించే హక్కు రుజువు.';

  @override
  String get hostHowApproved => 'ఆమోదం పొందండి';

  @override
  String get hostHowApprovedBody =>
      'మా బృందం ఫోటోలు, లొకేషన్, రుజువు తనిఖీ చేస్తుంది.';

  @override
  String get hostHowRequests => 'రైతులు ఒక రోజు అభ్యర్థిస్తారు';

  @override
  String get hostHowRequestsBody =>
      'ధృవీకరించిన రైతులు తమ అమ్మకం రోజు కోసం మీ స్థలాన్ని అడుగుతారు.';

  @override
  String get hostHowAccept => 'అంగీకరించి స్థలం ఇవ్వండి';

  @override
  String get hostHowAcceptBody =>
      'అంగీకరించి, చిరునామా పంచుకుని, స్థలం వద్ద రుసుము తీసుకోండి.';
}
