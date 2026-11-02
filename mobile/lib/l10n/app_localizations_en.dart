// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Aangan Mandi';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get continueButton => 'Continue';

  @override
  String get enterPhone => 'Enter your mobile number';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String enterOtp(String phone) {
    return 'Enter the 6-digit OTP sent to $phone';
  }

  @override
  String get verify => 'Verify';

  @override
  String testOtp(String code) {
    return 'Test OTP: $code';
  }

  @override
  String get testOtpHint => 'Testing mode: no SMS is sent';

  @override
  String get useTestOtp => 'Fill it in';

  @override
  String get whoAreYou => 'How will you use Aangan Mandi?';

  @override
  String get roleFarmer => 'I am a farmer';

  @override
  String get roleFarmerHint => 'Sell your own produce near buyers';

  @override
  String get roleHost => 'I have a space';

  @override
  String get roleHostHint => 'Lend a driveway or courtyard for a few hours';

  @override
  String get roleBuyer => 'I want fresh produce';

  @override
  String get roleBuyerHint => 'Get alerts when a farmer is nearby';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get farmerHome => 'My trips';

  @override
  String get hostHome => 'My spaces';

  @override
  String get buyerHome => 'Stalls near me';

  @override
  String get opsHome => 'Operations';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get tagline => 'Fresh from the farm, at your gate';

  @override
  String get featureVerified =>
      'Only verified farmers selling their own produce';

  @override
  String get featureSpaces =>
      'Neighbours lend a driveway or courtyard for a few hours';

  @override
  String get featureAlerts => 'Buyers nearby get an alert when a stall opens';

  @override
  String get logout => 'Log out';

  @override
  String get retry => 'Try again';

  @override
  String get refresh => 'Refresh';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get save => 'Save';

  @override
  String get required => 'Required';

  @override
  String get verifyNotStartedTitle => 'Get verified to start selling';

  @override
  String get startVerification => 'Start verification';

  @override
  String get continueVerification => 'Continue verification';

  @override
  String get verifyPendingTitle => 'Under review';

  @override
  String get verifyPendingBody =>
      'Our team is checking your details. This usually takes up to 48 hours.';

  @override
  String get verifiedTitle => 'Verified farmer';

  @override
  String get verifiedBody =>
      'You are verified. Trips and space bookings open soon.';

  @override
  String get rejectedTitle => 'Verification needs changes';

  @override
  String rejectedReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get fixAndResubmit => 'Fix and resubmit';

  @override
  String get stepAboutYou => 'About you';

  @override
  String get stepReview => 'Submit';

  @override
  String get verifyNotStartedBody =>
      'We check that you are a genuine farmer. It takes about 5 minutes. Keep one proof of farming ready: your AgriStack Farmer ID, a land or cultivation record, FPO membership, or a letter from an agriculture officer.';

  @override
  String get consentText =>
      'I confirm these details are true. I agree that Aangan Mandi stores this proof to verify me.';

  @override
  String get stepEvidence => 'Farming proof';

  @override
  String get farmSizeOptional => 'Approximate farm size in acres (optional)';

  @override
  String get farmSizeInvalid => 'Enter a size between 0 and 1000 acres';

  @override
  String get produceSourceQuestion => 'Do you sell what you grow?';

  @override
  String get sourceOwnFarm => 'Yes, only what I grow';

  @override
  String get sourceOwnAndOthers => 'Mostly mine, some from other farmers';

  @override
  String get sourceOthers => 'No, I buy from other farmers and sell';

  @override
  String get evidenceQuestion => 'Choose one proof that you are a farmer';

  @override
  String get evidenceSubtitle =>
      'A verifier checks it and approves you, usually within 48 hours.';

  @override
  String get evidenceAgriStack => 'AgriStack Farmer ID';

  @override
  String get evidenceAgriStackHint => 'Your Farmer ID card or SMS';

  @override
  String get evidenceLandRecord => 'Land or cultivation record';

  @override
  String get evidenceLandRecordHint =>
      'Pattadar passbook, ROR-1B, lease agreement or crop record';

  @override
  String get evidenceFpo => 'FPO membership or referral';

  @override
  String get evidenceFpoHint =>
      'Membership card or letter from your farmer producer organisation';

  @override
  String get evidenceOfficer => 'Reference from an agriculture officer';

  @override
  String get evidenceOfficerHint =>
      'Letter from your agriculture extension officer or a recognised farmer organisation';

  @override
  String get detailsAgriStack => 'Farmer ID number';

  @override
  String get detailsLandRecord => 'Survey number (optional)';

  @override
  String get detailsFpo => 'FPO name, or who referred you';

  @override
  String get detailsOfficer => 'Officer\'s or organisation\'s name and phone';

  @override
  String get evidencePhoto => 'Photo of the proof';

  @override
  String get evidencePhotoHint => 'Make sure your name can be read';

  @override
  String get fullName => 'Full name';

  @override
  String get village => 'Village';

  @override
  String get district => 'District';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get retakePhoto => 'Retake';

  @override
  String get uploaded => 'Uploaded';

  @override
  String get uploading => 'Uploading…';

  @override
  String get cropsYouGrow => 'Crops you grow';

  @override
  String get useMyLocation => 'Use my current location';

  @override
  String get locationDenied => 'Allow location access to continue';

  @override
  String get reviewChecklist => 'Check everything before you submit';

  @override
  String get submitForReview => 'Submit for review';

  @override
  String get completeAllSteps => 'Complete every step before submitting';

  @override
  String get submittedMessage =>
      'Submitted. We will review it within 48 hours.';

  @override
  String get addSpace => 'Add a space';

  @override
  String get noSpacesTitle => 'List your first space';

  @override
  String get noSpacesBody =>
      'Lend a driveway, courtyard or open area to a verified farmer for a few hours. Neighbours get fresh produce at the gate.';

  @override
  String get spaceDetails => 'Space details';

  @override
  String get spaceName => 'Name of the space';

  @override
  String get spaceNameHint => 'For example: Green Villa courtyard';

  @override
  String get spaceType => 'Type of space';

  @override
  String get driveway => 'Driveway';

  @override
  String get courtyard => 'Courtyard';

  @override
  String get openArea => 'Open area';

  @override
  String get commercialFrontage => 'Shop frontage';

  @override
  String get address => 'Full address';

  @override
  String get addressHint =>
      'Shown to the farmer only after you approve a booking';

  @override
  String get locality => 'Locality / area';

  @override
  String get spaceLocation => 'Space location';

  @override
  String get enterCoordinates => 'Enter coordinates instead';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get areaSqFt => 'Usable area (sq ft)';

  @override
  String get maxVehicle => 'Largest vehicle that can enter';

  @override
  String get twoWheeler => 'Two-wheeler';

  @override
  String get auto => 'Auto';

  @override
  String get miniTruck => 'Mini-truck';

  @override
  String get tractor => 'Tractor';

  @override
  String get amenities => 'Amenities';

  @override
  String get water => 'Water';

  @override
  String get shade => 'Shade';

  @override
  String get powerPoint => 'Power point';

  @override
  String get buyerParking => 'Parking for buyers';

  @override
  String get loadingAccess => 'Loading access';

  @override
  String get toilet => 'Toilet access';

  @override
  String get pricing => 'Pricing';

  @override
  String get freeSpace => 'Free community space';

  @override
  String get feePerSlot => 'Fee per slot (₹)';

  @override
  String get availability => 'Availability';

  @override
  String get availableDays => 'Available days';

  @override
  String get openFrom => 'From';

  @override
  String get openTo => 'To';

  @override
  String get slotRule => 'Each slot must be 2 to 6 hours';

  @override
  String get houseRules => 'House rules (optional)';

  @override
  String get houseRulesHint =>
      'For example: no fish or meat, clean up after selling';

  @override
  String get spacePhotos => 'Photos of the space (3 to 8)';

  @override
  String get addPhotos => 'Add photos';

  @override
  String get proofOfRight => 'Proof you can use this space';

  @override
  String get proofHint =>
      'Ownership document, rent agreement or society letter. Never shown to buyers.';

  @override
  String get submitSpace => 'Submit for approval';

  @override
  String get spaceSubmitted =>
      'Sent for approval. We usually review within 48 hours.';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusPendingReview => 'Waiting for approval';

  @override
  String get statusLive => 'Live';

  @override
  String get statusRejected => 'Needs changes';

  @override
  String perSlot(String fee) {
    return '₹$fee per slot';
  }

  @override
  String get free => 'Free';

  @override
  String get photosNeeded => 'Add at least 3 photos and the proof document';

  @override
  String get finishAndSubmit => 'Finish and submit';

  @override
  String get addMorePhotos => 'Add more photos';

  @override
  String get buyerComingSoon =>
      'Live stalls near you will appear here once farmers start selling.';
}
