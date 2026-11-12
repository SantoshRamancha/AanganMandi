import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('te'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Aangan Mandi'**
  String get appTitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get enterPhone;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit OTP sent to {phone}'**
  String enterOtp(String phone);

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @testOtp.
  ///
  /// In en, this message translates to:
  /// **'Test OTP: {code}'**
  String testOtp(String code);

  /// No description provided for @testOtpHint.
  ///
  /// In en, this message translates to:
  /// **'Testing mode: no SMS is sent'**
  String get testOtpHint;

  /// No description provided for @useTestOtp.
  ///
  /// In en, this message translates to:
  /// **'Fill it in'**
  String get useTestOtp;

  /// No description provided for @whoAreYou.
  ///
  /// In en, this message translates to:
  /// **'How will you use Aangan Mandi?'**
  String get whoAreYou;

  /// No description provided for @roleFarmer.
  ///
  /// In en, this message translates to:
  /// **'I am a farmer'**
  String get roleFarmer;

  /// No description provided for @roleFarmerHint.
  ///
  /// In en, this message translates to:
  /// **'Sell your own produce near buyers'**
  String get roleFarmerHint;

  /// No description provided for @roleHost.
  ///
  /// In en, this message translates to:
  /// **'I have a space'**
  String get roleHost;

  /// No description provided for @roleHostHint.
  ///
  /// In en, this message translates to:
  /// **'Lend a driveway or courtyard for a few hours'**
  String get roleHostHint;

  /// No description provided for @roleBuyer.
  ///
  /// In en, this message translates to:
  /// **'I want fresh produce'**
  String get roleBuyer;

  /// No description provided for @roleBuyerHint.
  ///
  /// In en, this message translates to:
  /// **'Get alerts when a farmer is nearby'**
  String get roleBuyerHint;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @farmerHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get farmerHome;

  /// No description provided for @hostHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get hostHome;

  /// No description provided for @buyerHome.
  ///
  /// In en, this message translates to:
  /// **'Stalls near me'**
  String get buyerHome;

  /// No description provided for @opsHome.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get opsHome;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Fresh from the farm, at your gate'**
  String get tagline;

  /// No description provided for @featureVerified.
  ///
  /// In en, this message translates to:
  /// **'Only verified farmers selling their own produce'**
  String get featureVerified;

  /// No description provided for @featureSpaces.
  ///
  /// In en, this message translates to:
  /// **'Neighbours lend a driveway or courtyard for a few hours'**
  String get featureSpaces;

  /// No description provided for @featureAlerts.
  ///
  /// In en, this message translates to:
  /// **'Buyers nearby get an alert when a stall opens'**
  String get featureAlerts;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @verifyNotStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Get verified to start selling'**
  String get verifyNotStartedTitle;

  /// No description provided for @startVerification.
  ///
  /// In en, this message translates to:
  /// **'Start verification'**
  String get startVerification;

  /// No description provided for @continueVerification.
  ///
  /// In en, this message translates to:
  /// **'Continue verification'**
  String get continueVerification;

  /// No description provided for @verifyPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get verifyPendingTitle;

  /// No description provided for @verifyPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Our team is checking your details. This usually takes up to 48 hours.'**
  String get verifyPendingBody;

  /// No description provided for @verifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified farmer'**
  String get verifiedTitle;

  /// No description provided for @verifiedBody.
  ///
  /// In en, this message translates to:
  /// **'You are verified. Plan a trip and book a space to start selling.'**
  String get verifiedBody;

  /// No description provided for @rejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification needs changes'**
  String get rejectedTitle;

  /// No description provided for @rejectedReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String rejectedReason(String reason);

  /// No description provided for @fixAndResubmit.
  ///
  /// In en, this message translates to:
  /// **'Fix and resubmit'**
  String get fixAndResubmit;

  /// No description provided for @stepAboutYou.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get stepAboutYou;

  /// No description provided for @stepReview.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get stepReview;

  /// No description provided for @verifyNotStartedBody.
  ///
  /// In en, this message translates to:
  /// **'We check that you are a genuine farmer. It takes about 5 minutes. Keep one proof of farming ready: your AgriStack Farmer ID, a land or cultivation record, FPO membership, or a letter from an agriculture officer.'**
  String get verifyNotStartedBody;

  /// No description provided for @consentText.
  ///
  /// In en, this message translates to:
  /// **'I confirm these details are true. I agree that Aangan Mandi stores this proof to verify me.'**
  String get consentText;

  /// No description provided for @stepEvidence.
  ///
  /// In en, this message translates to:
  /// **'Farming proof'**
  String get stepEvidence;

  /// No description provided for @farmSizeOptional.
  ///
  /// In en, this message translates to:
  /// **'Approximate farm size in acres (optional)'**
  String get farmSizeOptional;

  /// No description provided for @farmSizeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a size between 0 and 1000 acres'**
  String get farmSizeInvalid;

  /// No description provided for @produceSourceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you sell what you grow?'**
  String get produceSourceQuestion;

  /// No description provided for @sourceOwnFarm.
  ///
  /// In en, this message translates to:
  /// **'Yes, only what I grow'**
  String get sourceOwnFarm;

  /// No description provided for @sourceOwnAndOthers.
  ///
  /// In en, this message translates to:
  /// **'Mostly mine, some from other farmers'**
  String get sourceOwnAndOthers;

  /// No description provided for @sourceOthers.
  ///
  /// In en, this message translates to:
  /// **'No, I buy from other farmers and sell'**
  String get sourceOthers;

  /// No description provided for @evidenceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Choose one proof that you are a farmer'**
  String get evidenceQuestion;

  /// No description provided for @evidenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A verifier checks it and approves you, usually within 48 hours.'**
  String get evidenceSubtitle;

  /// No description provided for @evidenceAgriStack.
  ///
  /// In en, this message translates to:
  /// **'AgriStack Farmer ID'**
  String get evidenceAgriStack;

  /// No description provided for @evidenceAgriStackHint.
  ///
  /// In en, this message translates to:
  /// **'Your Farmer ID card or SMS'**
  String get evidenceAgriStackHint;

  /// No description provided for @evidenceLandRecord.
  ///
  /// In en, this message translates to:
  /// **'Land or cultivation record'**
  String get evidenceLandRecord;

  /// No description provided for @evidenceLandRecordHint.
  ///
  /// In en, this message translates to:
  /// **'Pattadar passbook, ROR-1B, lease agreement or crop record'**
  String get evidenceLandRecordHint;

  /// No description provided for @evidenceFpo.
  ///
  /// In en, this message translates to:
  /// **'FPO membership or referral'**
  String get evidenceFpo;

  /// No description provided for @evidenceFpoHint.
  ///
  /// In en, this message translates to:
  /// **'Membership card or letter from your farmer producer organisation'**
  String get evidenceFpoHint;

  /// No description provided for @evidenceOfficer.
  ///
  /// In en, this message translates to:
  /// **'Reference from an agriculture officer'**
  String get evidenceOfficer;

  /// No description provided for @evidenceOfficerHint.
  ///
  /// In en, this message translates to:
  /// **'Letter from your agriculture extension officer or a recognised farmer organisation'**
  String get evidenceOfficerHint;

  /// No description provided for @detailsAgriStack.
  ///
  /// In en, this message translates to:
  /// **'Farmer ID number'**
  String get detailsAgriStack;

  /// No description provided for @detailsLandRecord.
  ///
  /// In en, this message translates to:
  /// **'Survey number (optional)'**
  String get detailsLandRecord;

  /// No description provided for @detailsFpo.
  ///
  /// In en, this message translates to:
  /// **'FPO name, or who referred you'**
  String get detailsFpo;

  /// No description provided for @detailsOfficer.
  ///
  /// In en, this message translates to:
  /// **'Officer\'s or organisation\'s name and phone'**
  String get detailsOfficer;

  /// No description provided for @evidencePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo of the proof'**
  String get evidencePhoto;

  /// No description provided for @evidencePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure your name can be read'**
  String get evidencePhotoHint;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @village.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get village;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @retakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retakePhoto;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploading;

  /// No description provided for @cropsYouGrow.
  ///
  /// In en, this message translates to:
  /// **'Crops you grow'**
  String get cropsYouGrow;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get useMyLocation;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow location access to continue'**
  String get locationDenied;

  /// No description provided for @reviewChecklist.
  ///
  /// In en, this message translates to:
  /// **'Check everything before you submit'**
  String get reviewChecklist;

  /// No description provided for @submitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get submitForReview;

  /// No description provided for @completeAllSteps.
  ///
  /// In en, this message translates to:
  /// **'Complete every step before submitting'**
  String get completeAllSteps;

  /// No description provided for @submittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Submitted. We will review it within 48 hours.'**
  String get submittedMessage;

  /// No description provided for @addSpace.
  ///
  /// In en, this message translates to:
  /// **'Add a space'**
  String get addSpace;

  /// No description provided for @noSpacesTitle.
  ///
  /// In en, this message translates to:
  /// **'List your first space'**
  String get noSpacesTitle;

  /// No description provided for @noSpacesBody.
  ///
  /// In en, this message translates to:
  /// **'Lend a driveway, courtyard or open area to a verified farmer for a few hours. Neighbours get fresh produce at the gate.'**
  String get noSpacesBody;

  /// No description provided for @spaceDetails.
  ///
  /// In en, this message translates to:
  /// **'Space details'**
  String get spaceDetails;

  /// No description provided for @spaceName.
  ///
  /// In en, this message translates to:
  /// **'Name of the space'**
  String get spaceName;

  /// No description provided for @spaceNameHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Green Villa courtyard'**
  String get spaceNameHint;

  /// No description provided for @spaceType.
  ///
  /// In en, this message translates to:
  /// **'Type of space'**
  String get spaceType;

  /// No description provided for @driveway.
  ///
  /// In en, this message translates to:
  /// **'Driveway'**
  String get driveway;

  /// No description provided for @courtyard.
  ///
  /// In en, this message translates to:
  /// **'Courtyard'**
  String get courtyard;

  /// No description provided for @openArea.
  ///
  /// In en, this message translates to:
  /// **'Open area'**
  String get openArea;

  /// No description provided for @commercialFrontage.
  ///
  /// In en, this message translates to:
  /// **'Shop frontage'**
  String get commercialFrontage;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Full address'**
  String get address;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'Shown to the farmer only after you approve a booking'**
  String get addressHint;

  /// No description provided for @locality.
  ///
  /// In en, this message translates to:
  /// **'Locality / area'**
  String get locality;

  /// No description provided for @spaceLocation.
  ///
  /// In en, this message translates to:
  /// **'Space location'**
  String get spaceLocation;

  /// No description provided for @enterCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Enter coordinates instead'**
  String get enterCoordinates;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @areaSqFt.
  ///
  /// In en, this message translates to:
  /// **'Usable area (sq ft)'**
  String get areaSqFt;

  /// No description provided for @maxVehicle.
  ///
  /// In en, this message translates to:
  /// **'Largest vehicle that can enter'**
  String get maxVehicle;

  /// No description provided for @twoWheeler.
  ///
  /// In en, this message translates to:
  /// **'Two-wheeler'**
  String get twoWheeler;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @miniTruck.
  ///
  /// In en, this message translates to:
  /// **'Mini-truck'**
  String get miniTruck;

  /// No description provided for @tractor.
  ///
  /// In en, this message translates to:
  /// **'Tractor'**
  String get tractor;

  /// No description provided for @amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenities;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @shade.
  ///
  /// In en, this message translates to:
  /// **'Shade'**
  String get shade;

  /// No description provided for @powerPoint.
  ///
  /// In en, this message translates to:
  /// **'Power point'**
  String get powerPoint;

  /// No description provided for @buyerParking.
  ///
  /// In en, this message translates to:
  /// **'Parking for buyers'**
  String get buyerParking;

  /// No description provided for @loadingAccess.
  ///
  /// In en, this message translates to:
  /// **'Loading access'**
  String get loadingAccess;

  /// No description provided for @toilet.
  ///
  /// In en, this message translates to:
  /// **'Toilet access'**
  String get toilet;

  /// No description provided for @pricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get pricing;

  /// No description provided for @freeSpace.
  ///
  /// In en, this message translates to:
  /// **'Free community space'**
  String get freeSpace;

  /// No description provided for @feePerSlot.
  ///
  /// In en, this message translates to:
  /// **'Fee per slot (₹)'**
  String get feePerSlot;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @availableDays.
  ///
  /// In en, this message translates to:
  /// **'Available days'**
  String get availableDays;

  /// No description provided for @openFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get openFrom;

  /// No description provided for @openTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get openTo;

  /// No description provided for @slotRule.
  ///
  /// In en, this message translates to:
  /// **'Each slot must be 2 to 6 hours'**
  String get slotRule;

  /// No description provided for @houseRules.
  ///
  /// In en, this message translates to:
  /// **'House rules (optional)'**
  String get houseRules;

  /// No description provided for @houseRulesHint.
  ///
  /// In en, this message translates to:
  /// **'For example: no fish or meat, clean up after selling'**
  String get houseRulesHint;

  /// No description provided for @spacePhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos of the space (3 to 8)'**
  String get spacePhotos;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get addPhotos;

  /// No description provided for @proofOfRight.
  ///
  /// In en, this message translates to:
  /// **'Proof you can use this space'**
  String get proofOfRight;

  /// No description provided for @proofHint.
  ///
  /// In en, this message translates to:
  /// **'Ownership document, rent agreement or society letter. Never shown to buyers.'**
  String get proofHint;

  /// No description provided for @submitSpace.
  ///
  /// In en, this message translates to:
  /// **'Submit for approval'**
  String get submitSpace;

  /// No description provided for @spaceSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Sent for approval. We usually review within 48 hours.'**
  String get spaceSubmitted;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get statusPendingReview;

  /// No description provided for @statusLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get statusLive;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Needs changes'**
  String get statusRejected;

  /// No description provided for @perSlot.
  ///
  /// In en, this message translates to:
  /// **'₹{fee} per slot'**
  String perSlot(String fee);

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @photosNeeded.
  ///
  /// In en, this message translates to:
  /// **'Add at least 3 photos and the proof document'**
  String get photosNeeded;

  /// No description provided for @finishAndSubmit.
  ///
  /// In en, this message translates to:
  /// **'Finish and submit'**
  String get finishAndSubmit;

  /// No description provided for @addMorePhotos.
  ///
  /// In en, this message translates to:
  /// **'Add more photos'**
  String get addMorePhotos;

  /// No description provided for @buyerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Live stalls near you will appear here once farmers start selling.'**
  String get buyerComingSoon;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get profileTitle;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get accountDetails;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not added yet'**
  String get nameNotSet;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumber;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSince;

  /// No description provided for @yourRoles.
  ///
  /// In en, this message translates to:
  /// **'Using the app as'**
  String get yourRoles;

  /// No description provided for @roleNameFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get roleNameFarmer;

  /// No description provided for @roleNameHost.
  ///
  /// In en, this message translates to:
  /// **'Space host'**
  String get roleNameHost;

  /// No description provided for @roleNameBuyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get roleNameBuyer;

  /// No description provided for @roleNameVerifier.
  ///
  /// In en, this message translates to:
  /// **'Verifier'**
  String get roleNameVerifier;

  /// No description provided for @roleNameAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleNameAdmin;

  /// No description provided for @verificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verificationStatus;

  /// No description provided for @farmDetails.
  ///
  /// In en, this message translates to:
  /// **'Farming details'**
  String get farmDetails;

  /// No description provided for @crops.
  ///
  /// In en, this message translates to:
  /// **'Crops'**
  String get crops;

  /// No description provided for @mySpaces.
  ///
  /// In en, this message translates to:
  /// **'My spaces'**
  String get mySpaces;

  /// No description provided for @mySpacesSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} listed · {live} live'**
  String mySpacesSummary(int count, int live);

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystemHint.
  ///
  /// In en, this message translates to:
  /// **'System follows your phone or computer setting.'**
  String get themeSystemHint;

  /// No description provided for @staffAccessRevokedTitle.
  ///
  /// In en, this message translates to:
  /// **'You no longer have staff access'**
  String get staffAccessRevokedTitle;

  /// No description provided for @staffAccessRevokedBody.
  ///
  /// In en, this message translates to:
  /// **'Ask an admin if you think this is a mistake. Log out to continue with your other account.'**
  String get staffAccessRevokedBody;

  /// No description provided for @opsTabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get opsTabDashboard;

  /// No description provided for @opsTabFarmers.
  ///
  /// In en, this message translates to:
  /// **'Farmers'**
  String get opsTabFarmers;

  /// No description provided for @opsTabSpaces.
  ///
  /// In en, this message translates to:
  /// **'Spaces'**
  String get opsTabSpaces;

  /// No description provided for @opsTabVerifiers.
  ///
  /// In en, this message translates to:
  /// **'Verifiers'**
  String get opsTabVerifiers;

  /// No description provided for @opsHello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String opsHello(String name);

  /// No description provided for @opsHelloNoName.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get opsHelloNoName;

  /// No description provided for @opsAdminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Admin · you see every farmer and manage verifiers'**
  String get opsAdminSubtitle;

  /// No description provided for @opsVerifierSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verifier · you review the farmers assigned to you'**
  String get opsVerifierSubtitle;

  /// No description provided for @statFarmersWaitingAll.
  ///
  /// In en, this message translates to:
  /// **'Farmers waiting for review'**
  String get statFarmersWaitingAll;

  /// No description provided for @statFarmersWaitingYou.
  ///
  /// In en, this message translates to:
  /// **'Farmers waiting for you'**
  String get statFarmersWaitingYou;

  /// No description provided for @statUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Waiting with no verifier'**
  String get statUnassigned;

  /// No description provided for @statSpacesWaiting.
  ///
  /// In en, this message translates to:
  /// **'Spaces waiting for approval'**
  String get statSpacesWaiting;

  /// No description provided for @statVerifiedAll.
  ///
  /// In en, this message translates to:
  /// **'Verified farmers'**
  String get statVerifiedAll;

  /// No description provided for @statVerifiedYou.
  ///
  /// In en, this message translates to:
  /// **'Farmers you verified'**
  String get statVerifiedYou;

  /// No description provided for @statSpacesLive.
  ///
  /// In en, this message translates to:
  /// **'Live spaces'**
  String get statSpacesLive;

  /// No description provided for @couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load. Pull down or tap refresh to try again.'**
  String get couldNotLoad;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Try again.'**
  String get couldNotSave;

  /// No description provided for @emptyList.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this list.'**
  String get emptyList;

  /// No description provided for @noName.
  ///
  /// In en, this message translates to:
  /// **'(no name)'**
  String get noName;

  /// No description provided for @decision.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get decision;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (required to reject; they will see it)'**
  String get reasonLabel;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @rejectedWith.
  ///
  /// In en, this message translates to:
  /// **'Rejected: {reason}'**
  String rejectedWith(String reason);

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @farmerStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for review'**
  String get farmerStatusPending;

  /// No description provided for @farmerStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get farmerStatusVerified;

  /// No description provided for @farmerStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get farmerStatusRejected;

  /// No description provided for @farmerStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not submitted'**
  String get farmerStatusNotStarted;

  /// No description provided for @farmerVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Farmer verification'**
  String get farmerVerificationTitle;

  /// No description provided for @farmerQueueAdminHint.
  ///
  /// In en, this message translates to:
  /// **'All farmers. Each submission goes to the verifier with the fewest waiting.'**
  String get farmerQueueAdminHint;

  /// No description provided for @farmerQueueVerifierHint.
  ///
  /// In en, this message translates to:
  /// **'Farmers assigned to you, oldest first.'**
  String get farmerQueueVerifierHint;

  /// No description provided for @noVerifierWarnTitle.
  ///
  /// In en, this message translates to:
  /// **'Some farmers have no verifier'**
  String get noVerifierWarnTitle;

  /// No description provided for @noVerifierWarnBody.
  ///
  /// In en, this message translates to:
  /// **'Add a verifier and they are assigned automatically, or open a farmer to assign one.'**
  String get noVerifierWarnBody;

  /// No description provided for @submittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted {when}'**
  String submittedOn(String when);

  /// No description provided for @verifierIs.
  ///
  /// In en, this message translates to:
  /// **'Verifier: {name}'**
  String verifierIs(String name);

  /// No description provided for @reviewFarmer.
  ///
  /// In en, this message translates to:
  /// **'Review farmer'**
  String get reviewFarmer;

  /// No description provided for @qrFarmerPhotoUnclear.
  ///
  /// In en, this message translates to:
  /// **'Evidence photo is unclear — please retake it'**
  String get qrFarmerPhotoUnclear;

  /// No description provided for @qrFarmerNameMismatch.
  ///
  /// In en, this message translates to:
  /// **'Name on the evidence does not match'**
  String get qrFarmerNameMismatch;

  /// No description provided for @qrFarmerIdUnconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm the Farmer ID'**
  String get qrFarmerIdUnconfirmed;

  /// No description provided for @qrFarmerRefereeNo.
  ///
  /// In en, this message translates to:
  /// **'The referee did not confirm you'**
  String get qrFarmerRefereeNo;

  /// No description provided for @qrFarmerNotGrower.
  ///
  /// In en, this message translates to:
  /// **'You sell only produce bought from other farmers'**
  String get qrFarmerNotGrower;

  /// No description provided for @phoneOtpVerified.
  ///
  /// In en, this message translates to:
  /// **'{phone} (OTP verified)'**
  String phoneOtpVerified(String phone);

  /// No description provided for @farmSize.
  ///
  /// In en, this message translates to:
  /// **'Farm size'**
  String get farmSize;

  /// No description provided for @notGiven.
  ///
  /// In en, this message translates to:
  /// **'Not given'**
  String get notGiven;

  /// No description provided for @aboutAcres.
  ///
  /// In en, this message translates to:
  /// **'About {acres} acres'**
  String aboutAcres(String acres);

  /// No description provided for @sells.
  ///
  /// In en, this message translates to:
  /// **'Sells'**
  String get sells;

  /// No description provided for @sellsOwnFarm.
  ///
  /// In en, this message translates to:
  /// **'Only what they grow'**
  String get sellsOwnFarm;

  /// No description provided for @sellsOwnAndOthers.
  ///
  /// In en, this message translates to:
  /// **'Own crops, plus some from other farmers'**
  String get sellsOwnAndOthers;

  /// No description provided for @sellsOthers.
  ///
  /// In en, this message translates to:
  /// **'Only produce from other farmers (not a grower)'**
  String get sellsOthers;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @farmingEvidence.
  ///
  /// In en, this message translates to:
  /// **'Farming evidence'**
  String get farmingEvidence;

  /// No description provided for @factType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get factType;

  /// No description provided for @factDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get factDetails;

  /// No description provided for @noPhoto.
  ///
  /// In en, this message translates to:
  /// **'No photo'**
  String get noPhoto;

  /// No description provided for @olderDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents from the earlier verification flow'**
  String get olderDocuments;

  /// No description provided for @howCheckAgriStack.
  ///
  /// In en, this message translates to:
  /// **'Check the Farmer ID number and name in the AgriStack farmer registry.'**
  String get howCheckAgriStack;

  /// No description provided for @howCheckLandRecord.
  ///
  /// In en, this message translates to:
  /// **'Check the owner or cultivator name and survey number on the Bhu Bharati portal.'**
  String get howCheckLandRecord;

  /// No description provided for @howCheckFpo.
  ///
  /// In en, this message translates to:
  /// **'Call the FPO (or the person who referred them) and confirm they know this farmer.'**
  String get howCheckFpo;

  /// No description provided for @howCheckOfficer.
  ///
  /// In en, this message translates to:
  /// **'Call the officer or organisation and confirm they know this farmer.'**
  String get howCheckOfficer;

  /// No description provided for @farmerApproveGuidance.
  ///
  /// In en, this message translates to:
  /// **'Approve only if the evidence is real, the name on it matches this farmer, and they grow what they sell.'**
  String get farmerApproveGuidance;

  /// No description provided for @farmerApproveLabel.
  ///
  /// In en, this message translates to:
  /// **'Approve — verified farmer'**
  String get farmerApproveLabel;

  /// No description provided for @farmerApprovedToast.
  ///
  /// In en, this message translates to:
  /// **'Approved: {name} is a verified farmer'**
  String farmerApprovedToast(String name);

  /// No description provided for @farmerRejectedToast.
  ///
  /// In en, this message translates to:
  /// **'Rejected. The farmer will see your reason.'**
  String get farmerRejectedToast;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get assignedTo;

  /// No description provided for @assignedOn.
  ///
  /// In en, this message translates to:
  /// **'Assigned on'**
  String get assignedOn;

  /// No description provided for @reviewedBy.
  ///
  /// In en, this message translates to:
  /// **'Reviewed by'**
  String get reviewedBy;

  /// No description provided for @verifierAssignedToast.
  ///
  /// In en, this message translates to:
  /// **'Verifier assigned'**
  String get verifierAssignedToast;

  /// No description provided for @noVerifiersYetAssign.
  ///
  /// In en, this message translates to:
  /// **'There are no verifiers yet. Add one on the Verifiers tab.'**
  String get noVerifiersYetAssign;

  /// No description provided for @chooseVerifier.
  ///
  /// In en, this message translates to:
  /// **'Choose a verifier'**
  String get chooseVerifier;

  /// No description provided for @verifierOption.
  ///
  /// In en, this message translates to:
  /// **'{name} ({count} waiting)'**
  String verifierOption(String name, int count);

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @reassign.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get reassign;

  /// No description provided for @spaceApprovals.
  ///
  /// In en, this message translates to:
  /// **'Space approvals'**
  String get spaceApprovals;

  /// No description provided for @hostedBy.
  ///
  /// In en, this message translates to:
  /// **'Host: {host} · updated {when}'**
  String hostedBy(String host, String when);

  /// No description provided for @reviewSpace.
  ///
  /// In en, this message translates to:
  /// **'Review space'**
  String get reviewSpace;

  /// No description provided for @qrSpacePublicRoad.
  ///
  /// In en, this message translates to:
  /// **'Space is on a public road or footpath'**
  String get qrSpacePublicRoad;

  /// No description provided for @qrSpacePhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos are unclear or do not show the space'**
  String get qrSpacePhotos;

  /// No description provided for @qrSpaceProof.
  ///
  /// In en, this message translates to:
  /// **'Proof document does not show the right to use this space'**
  String get qrSpaceProof;

  /// No description provided for @qrSpacePin.
  ///
  /// In en, this message translates to:
  /// **'Location pin does not match the address'**
  String get qrSpacePin;

  /// No description provided for @spaceSection.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get spaceSection;

  /// No description provided for @usableArea.
  ///
  /// In en, this message translates to:
  /// **'Usable area'**
  String get usableArea;

  /// No description provided for @areaValue.
  ///
  /// In en, this message translates to:
  /// **'{area} sq ft (stall up to {stall})'**
  String areaValue(int area, String stall);

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open location in maps'**
  String get openInMaps;

  /// No description provided for @availabilityAndHost.
  ///
  /// In en, this message translates to:
  /// **'Availability and host'**
  String get availabilityAndHost;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @fee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get fee;

  /// No description provided for @freeCommunitySpace.
  ///
  /// In en, this message translates to:
  /// **'Free community space'**
  String get freeCommunitySpace;

  /// No description provided for @rules.
  ///
  /// In en, this message translates to:
  /// **'House rules'**
  String get rules;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @proofMissing.
  ///
  /// In en, this message translates to:
  /// **'Proof is missing'**
  String get proofMissing;

  /// No description provided for @photosCount.
  ///
  /// In en, this message translates to:
  /// **'Photos ({count})'**
  String photosCount(int count);

  /// No description provided for @spaceApproveGuidance.
  ///
  /// In en, this message translates to:
  /// **'Approve only if it is private space (not a road or footpath), the photos match the location, and the proof names the host or allows the use.'**
  String get spaceApproveGuidance;

  /// No description provided for @spaceApproveLabel.
  ///
  /// In en, this message translates to:
  /// **'Approve — make live'**
  String get spaceApproveLabel;

  /// No description provided for @spaceLiveToast.
  ///
  /// In en, this message translates to:
  /// **'{title} is live'**
  String spaceLiveToast(String title);

  /// No description provided for @spaceRejectedToast.
  ///
  /// In en, this message translates to:
  /// **'Rejected. The host will see your reason.'**
  String get spaceRejectedToast;

  /// No description provided for @verifiersHint.
  ///
  /// In en, this message translates to:
  /// **'Each farmer who submits goes to the verifier with the fewest farmers waiting; a resubmission goes back to the same verifier.'**
  String get verifiersHint;

  /// No description provided for @addVerifierTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a verifier'**
  String get addVerifierTitle;

  /// No description provided for @addVerifierButton.
  ///
  /// In en, this message translates to:
  /// **'Add verifier'**
  String get addVerifierButton;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter the name'**
  String get enterName;

  /// No description provided for @enterTenDigits.
  ///
  /// In en, this message translates to:
  /// **'Enter a 10-digit number'**
  String get enterTenDigits;

  /// No description provided for @verifierAddedToast.
  ///
  /// In en, this message translates to:
  /// **'Added {name}. They can sign in with +91 {phone}.'**
  String verifierAddedToast(String name, String phone);

  /// No description provided for @farmersAssignedToNew.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 waiting farmer was assigned to them.} other{{count} waiting farmers were assigned to them.}}'**
  String farmersAssignedToNew(int count);

  /// No description provided for @removeVerifierQ.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeVerifierQ(String name);

  /// No description provided for @removeVerifierBody.
  ///
  /// In en, this message translates to:
  /// **'They can no longer review farmers or spaces.'**
  String get removeVerifierBody;

  /// No description provided for @removeVerifierMoves.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Their 1 waiting farmer moves to the other verifiers.} other{Their {count} waiting farmers move to the other verifiers.}}'**
  String removeVerifierMoves(int count);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @verifierRemovedToast.
  ///
  /// In en, this message translates to:
  /// **'Removed {name}.'**
  String verifierRemovedToast(String name);

  /// No description provided for @farmersMoved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 waiting farmer moved to other verifiers.} other{{count} waiting farmers moved to other verifiers.}}'**
  String farmersMoved(int count);

  /// No description provided for @farmersNowUnassigned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 farmer is now unassigned: add a verifier to pick them up.} other{{count} farmers are now unassigned: add a verifier to pick them up.}}'**
  String farmersNowUnassigned(int count);

  /// No description provided for @noVerifiersBody.
  ///
  /// In en, this message translates to:
  /// **'No verifiers yet. Farmers who submit stay unassigned until you add one.'**
  String get noVerifiersBody;

  /// No description provided for @verifierAddedOn.
  ///
  /// In en, this message translates to:
  /// **'{phone} · added {when}'**
  String verifierAddedOn(String phone, String when);

  /// No description provided for @verifierCounts.
  ///
  /// In en, this message translates to:
  /// **'{waiting} waiting · {reviewed} reviewed'**
  String verifierCounts(int waiting, int reviewed);

  /// No description provided for @removeVerifierTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove verifier'**
  String get removeVerifierTooltip;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @reupload.
  ///
  /// In en, this message translates to:
  /// **'Reupload'**
  String get reupload;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload photo'**
  String get uploadPhoto;

  /// No description provided for @downloadSaved.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloadSaved;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not download. Try again.'**
  String get downloadFailed;

  /// No description provided for @deleteDocumentQ.
  ///
  /// In en, this message translates to:
  /// **'Delete this photo?'**
  String get deleteDocumentQ;

  /// No description provided for @deleteDocumentBody.
  ///
  /// In en, this message translates to:
  /// **'You can upload a new one afterwards.'**
  String get deleteDocumentBody;

  /// No description provided for @documentLocked.
  ///
  /// In en, this message translates to:
  /// **'Approved — this can no longer be changed.'**
  String get documentLocked;

  /// No description provided for @evidenceWithdrawWarning.
  ///
  /// In en, this message translates to:
  /// **'Your verification is waiting for review. Deleting the evidence takes it out of the queue: upload a new photo and submit again.'**
  String get evidenceWithdrawWarning;

  /// No description provided for @evidenceWithdrawnToast.
  ///
  /// In en, this message translates to:
  /// **'Photo deleted. Upload a new one and submit again.'**
  String get evidenceWithdrawnToast;

  /// No description provided for @spaceWithdrawWarning.
  ///
  /// In en, this message translates to:
  /// **'This space is waiting for approval. If it ends up with fewer than 3 photos or no proof, it goes back to draft and you submit it again.'**
  String get spaceWithdrawWarning;

  /// No description provided for @spaceWithdrawnToast.
  ///
  /// In en, this message translates to:
  /// **'Photo deleted. The space went back to draft: add what is missing and submit again.'**
  String get spaceWithdrawnToast;

  /// No description provided for @photoDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'Photo deleted'**
  String get photoDeletedToast;

  /// No description provided for @photoNumber.
  ///
  /// In en, this message translates to:
  /// **'Photo {number}'**
  String photoNumber(int number);

  /// No description provided for @yourDocument.
  ///
  /// In en, this message translates to:
  /// **'Your document'**
  String get yourDocument;

  /// No description provided for @yourDocumentPendingHint.
  ///
  /// In en, this message translates to:
  /// **'You can still replace or delete it while it waits for review.'**
  String get yourDocumentPendingHint;

  /// No description provided for @bookingRequested.
  ///
  /// In en, this message translates to:
  /// **'Waiting for host'**
  String get bookingRequested;

  /// No description provided for @bookingAccepted.
  ///
  /// In en, this message translates to:
  /// **'Space booked'**
  String get bookingAccepted;

  /// No description provided for @bookingDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get bookingDeclined;

  /// No description provided for @bookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingCancelled;

  /// No description provided for @tripPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get tripPlanned;

  /// No description provided for @tripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tripCompleted;

  /// No description provided for @kgAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} kg'**
  String kgAmount(String amount);

  /// No description provided for @pricePerKgAmount.
  ///
  /// In en, this message translates to:
  /// **'₹{price}/kg'**
  String pricePerKgAmount(String price);

  /// No description provided for @bookingSlotTaken.
  ///
  /// In en, this message translates to:
  /// **'The host confirmed another farmer for this day.'**
  String get bookingSlotTaken;

  /// No description provided for @bookingDeclinedBecause.
  ///
  /// In en, this message translates to:
  /// **'The host declined: {reason}'**
  String bookingDeclinedBecause(String reason);

  /// No description provided for @bookingHostCancelled.
  ///
  /// In en, this message translates to:
  /// **'The host cancelled: {reason}'**
  String bookingHostCancelled(String reason);

  /// No description provided for @bookingYouCancelled.
  ///
  /// In en, this message translates to:
  /// **'You cancelled this booking.'**
  String get bookingYouCancelled;

  /// No description provided for @upToVehicle.
  ///
  /// In en, this message translates to:
  /// **'Fits up to a {vehicle}'**
  String upToVehicle(String vehicle);

  /// No description provided for @myTrips.
  ///
  /// In en, this message translates to:
  /// **'My trips'**
  String get myTrips;

  /// No description provided for @planTrip.
  ///
  /// In en, this message translates to:
  /// **'Plan a trip'**
  String get planTrip;

  /// No description provided for @noTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get noTripsTitle;

  /// No description provided for @noTripsBody.
  ///
  /// In en, this message translates to:
  /// **'Plan the day you will come to the city to sell, then book a space near your buyers.'**
  String get noTripsBody;

  /// No description provided for @noSpaceYet.
  ///
  /// In en, this message translates to:
  /// **'No space booked yet'**
  String get noSpaceYet;

  /// No description provided for @editTrip.
  ///
  /// In en, this message translates to:
  /// **'Edit trip'**
  String get editTrip;

  /// No description provided for @tripWhen.
  ///
  /// In en, this message translates to:
  /// **'When are you coming?'**
  String get tripWhen;

  /// No description provided for @tripDateLocked.
  ///
  /// In en, this message translates to:
  /// **'Date and vehicle are fixed while a space is requested or booked. Cancel the booking to change them.'**
  String get tripDateLocked;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get chooseDate;

  /// No description provided for @tripVehicle.
  ///
  /// In en, this message translates to:
  /// **'Your vehicle'**
  String get tripVehicle;

  /// No description provided for @tripVehicleHint.
  ///
  /// In en, this message translates to:
  /// **'We only show spaces it can enter.'**
  String get tripVehicleHint;

  /// No description provided for @tripProduce.
  ///
  /// In en, this message translates to:
  /// **'What will you bring?'**
  String get tripProduce;

  /// No description provided for @tripProduceHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the crops. Quantity and price are optional and help the host.'**
  String get tripProduceHint;

  /// No description provided for @quantityKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get quantityKg;

  /// No description provided for @priceKg.
  ///
  /// In en, this message translates to:
  /// **'₹ per kg'**
  String get priceKg;

  /// No description provided for @tripWhere.
  ///
  /// In en, this message translates to:
  /// **'Where would you like to sell?'**
  String get tripWhere;

  /// No description provided for @preferredArea.
  ///
  /// In en, this message translates to:
  /// **'Area (optional)'**
  String get preferredArea;

  /// No description provided for @preferredAreaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ameerpet, Kukatpally'**
  String get preferredAreaHint;

  /// No description provided for @tripNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get tripNotes;

  /// No description provided for @saveTripFindSpace.
  ///
  /// In en, this message translates to:
  /// **'Save and find a space'**
  String get saveTripFindSpace;

  /// No description provided for @tripNeedsDateAndCrop.
  ///
  /// In en, this message translates to:
  /// **'Choose a date and at least one crop'**
  String get tripNeedsDateAndCrop;

  /// No description provided for @cancelTrip.
  ///
  /// In en, this message translates to:
  /// **'Cancel trip'**
  String get cancelTrip;

  /// No description provided for @cancelTripQ.
  ///
  /// In en, this message translates to:
  /// **'Cancel this trip?'**
  String get cancelTripQ;

  /// No description provided for @cancelTripBody.
  ///
  /// In en, this message translates to:
  /// **'Any space you requested or booked for it is cancelled too, and the host is told.'**
  String get cancelTripBody;

  /// No description provided for @tripCancelledToast.
  ///
  /// In en, this message translates to:
  /// **'Trip cancelled'**
  String get tripCancelledToast;

  /// No description provided for @tripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get tripDetails;

  /// No description provided for @cancelBookingQ.
  ///
  /// In en, this message translates to:
  /// **'Cancel this booking?'**
  String get cancelBookingQ;

  /// No description provided for @cancelBookingBody.
  ///
  /// In en, this message translates to:
  /// **'The other side is told and the slot opens again.'**
  String get cancelBookingBody;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get cancelBooking;

  /// No description provided for @bookingCancelledToast.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get bookingCancelledToast;

  /// No description provided for @spaceBookedTitle.
  ///
  /// In en, this message translates to:
  /// **'Space booked — see you there'**
  String get spaceBookedTitle;

  /// No description provided for @payAtSpace.
  ///
  /// In en, this message translates to:
  /// **'pay the host at the space'**
  String get payAtSpace;

  /// No description provided for @callHost.
  ///
  /// In en, this message translates to:
  /// **'Call host'**
  String get callHost;

  /// No description provided for @waitingForHostTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the host'**
  String get waitingForHostTitle;

  /// No description provided for @waitingForHostBody.
  ///
  /// In en, this message translates to:
  /// **'The host will accept or decline your request. You will see the address and phone number once they accept.'**
  String get waitingForHostBody;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequest;

  /// No description provided for @spaceForTrip.
  ///
  /// In en, this message translates to:
  /// **'Space for this trip'**
  String get spaceForTrip;

  /// No description provided for @findSpaceIntro.
  ///
  /// In en, this message translates to:
  /// **'Find a space that is open on this day and fits your vehicle.'**
  String get findSpaceIntro;

  /// No description provided for @findAnotherSpaceIntro.
  ///
  /// In en, this message translates to:
  /// **'You can request another space for this day.'**
  String get findAnotherSpaceIntro;

  /// No description provided for @findSpace.
  ///
  /// In en, this message translates to:
  /// **'Find a space'**
  String get findSpace;

  /// No description provided for @findAnotherSpace.
  ///
  /// In en, this message translates to:
  /// **'Find another space'**
  String get findAnotherSpace;

  /// No description provided for @tripWasCancelled.
  ///
  /// In en, this message translates to:
  /// **'This trip was cancelled.'**
  String get tripWasCancelled;

  /// No description provided for @tripIsOver.
  ///
  /// In en, this message translates to:
  /// **'This trip date has passed.'**
  String get tripIsOver;

  /// No description provided for @requestSpaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Request {title}'**
  String requestSpaceTitle(String title);

  /// No description provided for @messageToHost.
  ///
  /// In en, this message translates to:
  /// **'Message to the host (optional)'**
  String get messageToHost;

  /// No description provided for @messageToHostHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. I will come in an auto with 3 crates of tomatoes'**
  String get messageToHostHint;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequest;

  /// No description provided for @requestSentToast.
  ///
  /// In en, this message translates to:
  /// **'Request sent. You will see the answer on your trip.'**
  String get requestSentToast;

  /// No description provided for @spacesFor.
  ///
  /// In en, this message translates to:
  /// **'Spaces for {date}'**
  String spacesFor(String date);

  /// No description provided for @searchArea.
  ///
  /// In en, this message translates to:
  /// **'Search an area (e.g. Ameerpet)'**
  String get searchArea;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @spacesMatchHint.
  ///
  /// In en, this message translates to:
  /// **'Spaces open that day that fit your {vehicle}. The exact address is shared once the host accepts.'**
  String spacesMatchHint(String vehicle);

  /// No description provided for @noSpacesThatDay.
  ///
  /// In en, this message translates to:
  /// **'No free spaces fit your vehicle on this day. Try another date.'**
  String get noSpacesThatDay;

  /// No description provided for @noSpacesInArea.
  ///
  /// In en, this message translates to:
  /// **'No free spaces in this area on this day. Clear the search to see all areas.'**
  String get noSpacesInArea;

  /// No description provided for @requestThisSpace.
  ///
  /// In en, this message translates to:
  /// **'Request this space'**
  String get requestThisSpace;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @bookingsHint.
  ///
  /// In en, this message translates to:
  /// **'Farmers\' requests and confirmed days'**
  String get bookingsHint;

  /// No description provided for @requestsWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 farmer is waiting for your answer} other{{count} farmers are waiting for your answer}}'**
  String requestsWaiting(int count);

  /// No description provided for @requestsCount.
  ///
  /// In en, this message translates to:
  /// **'Requests ({count})'**
  String requestsCount(int count);

  /// No description provided for @bookingRequestsTab.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get bookingRequestsTab;

  /// No description provided for @upcomingTab.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingTab;

  /// No description provided for @pastTab.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get pastTab;

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'No new requests. Farmers\' requests for your spaces appear here.'**
  String get noRequests;

  /// No description provided for @noUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No confirmed bookings coming up.'**
  String get noUpcoming;

  /// No description provided for @noPastBookings.
  ///
  /// In en, this message translates to:
  /// **'No past bookings yet.'**
  String get noPastBookings;

  /// No description provided for @reasonForFarmer.
  ///
  /// In en, this message translates to:
  /// **'Reason (the farmer will see it)'**
  String get reasonForFarmer;

  /// No description provided for @verifiedFarmerTag.
  ///
  /// In en, this message translates to:
  /// **'verified farmer'**
  String get verifiedFarmerTag;

  /// No description provided for @hostAutoDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined automatically: you confirmed another farmer for this day.'**
  String get hostAutoDeclined;

  /// No description provided for @farmerCancelled.
  ///
  /// In en, this message translates to:
  /// **'The farmer cancelled.'**
  String get farmerCancelled;

  /// No description provided for @yourReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String yourReason(String reason);

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @acceptedToast.
  ///
  /// In en, this message translates to:
  /// **'Accepted. The farmer can now see your address and phone.'**
  String get acceptedToast;

  /// No description provided for @declineQ.
  ///
  /// In en, this message translates to:
  /// **'Decline this request?'**
  String get declineQ;

  /// No description provided for @qrNotAvailableDay.
  ///
  /// In en, this message translates to:
  /// **'The space is not available that day'**
  String get qrNotAvailableDay;

  /// No description provided for @qrVehicleTooBig.
  ///
  /// In en, this message translates to:
  /// **'The vehicle will not fit'**
  String get qrVehicleTooBig;

  /// No description provided for @qrOnlySomeProduce.
  ///
  /// In en, this message translates to:
  /// **'I can\'t host this kind of produce'**
  String get qrOnlySomeProduce;

  /// No description provided for @declinedToast.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get declinedToast;

  /// No description provided for @callFarmer.
  ///
  /// In en, this message translates to:
  /// **'Call farmer'**
  String get callFarmer;

  /// No description provided for @newRequest.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get newRequest;

  /// No description provided for @greetingName.
  ///
  /// In en, this message translates to:
  /// **'Namaste, {name}'**
  String greetingName(String name);

  /// No description provided for @greetingNoName.
  ///
  /// In en, this message translates to:
  /// **'Namaste'**
  String get greetingNoName;

  /// No description provided for @farmerBannerVerified.
  ///
  /// In en, this message translates to:
  /// **'You are a verified farmer. Plan your next selling day.'**
  String get farmerBannerVerified;

  /// No description provided for @farmerBannerNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Get verified once, then sell your fresh produce in the city.'**
  String get farmerBannerNotVerified;

  /// No description provided for @statUpcomingTrips.
  ///
  /// In en, this message translates to:
  /// **'Upcoming trips'**
  String get statUpcomingTrips;

  /// No description provided for @statSpacesBooked.
  ///
  /// In en, this message translates to:
  /// **'Spaces booked'**
  String get statSpacesBooked;

  /// No description provided for @statWaitingHost.
  ///
  /// In en, this message translates to:
  /// **'Waiting for host'**
  String get statWaitingHost;

  /// No description provided for @statCompletedTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips done'**
  String get statCompletedTrips;

  /// No description provided for @nextTrip.
  ///
  /// In en, this message translates to:
  /// **'Your next trip'**
  String get nextTrip;

  /// No description provided for @noUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'No trip planned'**
  String get noUpcomingTitle;

  /// No description provided for @noUpcomingBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a day to come to the city, then book a space near buyers.'**
  String get noUpcomingBody;

  /// No description provided for @viewTrip.
  ///
  /// In en, this message translates to:
  /// **'View trip'**
  String get viewTrip;

  /// No description provided for @allTrips.
  ///
  /// In en, this message translates to:
  /// **'All trips'**
  String get allTrips;

  /// No description provided for @yourVerification.
  ///
  /// In en, this message translates to:
  /// **'Your verification'**
  String get yourVerification;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @howStepVerify.
  ///
  /// In en, this message translates to:
  /// **'Get verified'**
  String get howStepVerify;

  /// No description provided for @howStepVerifyBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your farming and add one proof. A verifier checks it.'**
  String get howStepVerifyBody;

  /// No description provided for @howStepTrip.
  ///
  /// In en, this message translates to:
  /// **'Plan a trip'**
  String get howStepTrip;

  /// No description provided for @howStepTripBody.
  ///
  /// In en, this message translates to:
  /// **'Pick the day, your vehicle and what you will bring.'**
  String get howStepTripBody;

  /// No description provided for @howStepBook.
  ///
  /// In en, this message translates to:
  /// **'Book a space'**
  String get howStepBook;

  /// No description provided for @howStepBookBody.
  ///
  /// In en, this message translates to:
  /// **'Request a driveway or courtyard near buyers. The host accepts.'**
  String get howStepBookBody;

  /// No description provided for @howStepSell.
  ///
  /// In en, this message translates to:
  /// **'Sell fresh'**
  String get howStepSell;

  /// No description provided for @howStepSellBody.
  ///
  /// In en, this message translates to:
  /// **'Set up your stall and sell straight to families nearby.'**
  String get howStepSellBody;

  /// No description provided for @bookedAt.
  ///
  /// In en, this message translates to:
  /// **'Booked at {space}'**
  String bookedAt(String space);

  /// No description provided for @waitingAt.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {space} to accept'**
  String waitingAt(String space);

  /// No description provided for @hostBanner.
  ///
  /// In en, this message translates to:
  /// **'Spaces live: {live} · New requests: {waiting}'**
  String hostBanner(int live, int waiting);

  /// No description provided for @hostBannerNew.
  ///
  /// In en, this message translates to:
  /// **'List your driveway or courtyard and earn when farmers sell there.'**
  String get hostBannerNew;

  /// No description provided for @statNewRequests.
  ///
  /// In en, this message translates to:
  /// **'New requests'**
  String get statNewRequests;

  /// No description provided for @statUpcomingBookings.
  ///
  /// In en, this message translates to:
  /// **'Upcoming bookings'**
  String get statUpcomingBookings;

  /// No description provided for @needsYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Needs your answer'**
  String get needsYourAnswer;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @nextBooking.
  ///
  /// In en, this message translates to:
  /// **'Next booking'**
  String get nextBooking;

  /// No description provided for @noBookingYet.
  ///
  /// In en, this message translates to:
  /// **'No confirmed bookings yet. Accepted requests show here.'**
  String get noBookingYet;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @hostHowList.
  ///
  /// In en, this message translates to:
  /// **'List your space'**
  String get hostHowList;

  /// No description provided for @hostHowListBody.
  ///
  /// In en, this message translates to:
  /// **'Photos, days and hours, fee, and proof you can use the space.'**
  String get hostHowListBody;

  /// No description provided for @hostHowApproved.
  ///
  /// In en, this message translates to:
  /// **'Get approved'**
  String get hostHowApproved;

  /// No description provided for @hostHowApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'Our team checks the photos, location and proof.'**
  String get hostHowApprovedBody;

  /// No description provided for @hostHowRequests.
  ///
  /// In en, this message translates to:
  /// **'Farmers request a day'**
  String get hostHowRequests;

  /// No description provided for @hostHowRequestsBody.
  ///
  /// In en, this message translates to:
  /// **'Verified farmers ask for your space for their selling day.'**
  String get hostHowRequestsBody;

  /// No description provided for @hostHowAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept and host'**
  String get hostHowAccept;

  /// No description provided for @hostHowAcceptBody.
  ///
  /// In en, this message translates to:
  /// **'Accept, share your address, and collect the fee at the space.'**
  String get hostHowAcceptBody;

  /// No description provided for @catVegetable.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get catVegetable;

  /// No description provided for @catLeafy.
  ///
  /// In en, this message translates to:
  /// **'Leafy greens'**
  String get catLeafy;

  /// No description provided for @catFruit.
  ///
  /// In en, this message translates to:
  /// **'Fruits'**
  String get catFruit;

  /// No description provided for @catGrain.
  ///
  /// In en, this message translates to:
  /// **'Grains and millets'**
  String get catGrain;

  /// No description provided for @catPulse.
  ///
  /// In en, this message translates to:
  /// **'Pulses'**
  String get catPulse;

  /// No description provided for @catOilseed.
  ///
  /// In en, this message translates to:
  /// **'Oilseeds'**
  String get catOilseed;

  /// No description provided for @catSpice.
  ///
  /// In en, this message translates to:
  /// **'Spices'**
  String get catSpice;

  /// No description provided for @catFlower.
  ///
  /// In en, this message translates to:
  /// **'Flowers'**
  String get catFlower;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @searchCrops.
  ///
  /// In en, this message translates to:
  /// **'Search crops (any language)'**
  String get searchCrops;

  /// No description provided for @yourCrops.
  ///
  /// In en, this message translates to:
  /// **'Your crops'**
  String get yourCrops;

  /// No description provided for @addedByYou.
  ///
  /// In en, this message translates to:
  /// **'Added by you'**
  String get addedByYou;

  /// No description provided for @addAnotherCrop.
  ///
  /// In en, this message translates to:
  /// **'Add another crop'**
  String get addAnotherCrop;

  /// No description provided for @addCropTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a crop'**
  String get addCropTitle;

  /// No description provided for @addCropBody.
  ///
  /// In en, this message translates to:
  /// **'Not in the list? Type its name in any language. It is shown exactly as you type it.'**
  String get addCropBody;

  /// No description provided for @addCropHint.
  ///
  /// In en, this message translates to:
  /// **'Crop name'**
  String get addCropHint;

  /// No description provided for @addCropInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 2 to 30 letters'**
  String get addCropInvalid;

  /// No description provided for @addCropNamed.
  ///
  /// In en, this message translates to:
  /// **'Add “{name}”'**
  String addCropNamed(String name);

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// No description provided for @noCropsMatch.
  ///
  /// In en, this message translates to:
  /// **'No crop in the list has that name.'**
  String get noCropsMatch;

  /// No description provided for @logoutQ.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutQ;

  /// No description provided for @logoutBody.
  ///
  /// In en, this message translates to:
  /// **'To come back, you will sign in again with your mobile number and an OTP.'**
  String get logoutBody;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {phone}'**
  String signedInAs(String phone);

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailNotSet.
  ///
  /// In en, this message translates to:
  /// **'Add your email to get updates'**
  String get emailNotSet;

  /// No description provided for @changeButton.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeButton;

  /// No description provided for @emailDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Email for updates'**
  String get emailDialogTitle;

  /// No description provided for @emailDialogBody.
  ///
  /// In en, this message translates to:
  /// **'We email you about your verification, spaces and bookings, in your app language. Leave it empty to stop emails.'**
  String get emailDialogBody;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address, like name@example.com'**
  String get emailInvalid;

  /// No description provided for @emailSaved.
  ///
  /// In en, this message translates to:
  /// **'Email saved'**
  String get emailSaved;

  /// No description provided for @emailRemoved.
  ///
  /// In en, this message translates to:
  /// **'Email removed'**
  String get emailRemoved;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptional;

  /// No description provided for @verifierEmailHint.
  ///
  /// In en, this message translates to:
  /// **'They get a welcome email and one for each farmer assigned to them.'**
  String get verifierEmailHint;

  /// No description provided for @deleteSpace.
  ///
  /// In en, this message translates to:
  /// **'Delete space'**
  String get deleteSpace;

  /// No description provided for @deleteSpaceQ.
  ///
  /// In en, this message translates to:
  /// **'Delete this space?'**
  String get deleteSpaceQ;

  /// No description provided for @deleteSpaceBody.
  ///
  /// In en, this message translates to:
  /// **'Its photos and proof are deleted and it leaves search. This cannot be undone.'**
  String get deleteSpaceBody;

  /// No description provided for @deleteSpaceBookings.
  ///
  /// In en, this message translates to:
  /// **'Waiting and confirmed bookings from today on are cancelled, and each farmer is told.'**
  String get deleteSpaceBookings;

  /// No description provided for @spaceDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Space deleted} =1{Space deleted. 1 booking was cancelled.} other{Space deleted. {count} bookings were cancelled.}}'**
  String spaceDeletedToast(int count);

  /// No description provided for @resetVerification.
  ///
  /// In en, this message translates to:
  /// **'Clear and start over'**
  String get resetVerification;

  /// No description provided for @resetVerificationQ.
  ///
  /// In en, this message translates to:
  /// **'Clear your verification?'**
  String get resetVerificationQ;

  /// No description provided for @resetVerificationBody.
  ///
  /// In en, this message translates to:
  /// **'Your farming details, crops, evidence and evidence photo are deleted. Your name stays. This cannot be undone.'**
  String get resetVerificationBody;

  /// No description provided for @resetWithdrawWarning.
  ///
  /// In en, this message translates to:
  /// **'Your verification is waiting for review. Clearing it takes it out of the queue, so you will need to submit again.'**
  String get resetWithdrawWarning;

  /// No description provided for @verificationResetToast.
  ///
  /// In en, this message translates to:
  /// **'Verification cleared. You can start again.'**
  String get verificationResetToast;

  /// No description provided for @iveArrived.
  ///
  /// In en, this message translates to:
  /// **'I\'ve arrived'**
  String get iveArrived;

  /// No description provided for @checkInHint.
  ///
  /// In en, this message translates to:
  /// **'Tap this when you reach the space. Your phone\'s location must be within 200 m of it.'**
  String get checkInHint;

  /// No description provided for @locationNeededToCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to check in'**
  String get locationNeededToCheckIn;

  /// No description provided for @checkedInToast.
  ///
  /// In en, this message translates to:
  /// **'Checked in. The host has been told.'**
  String get checkedInToast;

  /// No description provided for @checkedInAt.
  ///
  /// In en, this message translates to:
  /// **'You checked in at {time}. The host and nearby buyers were told.'**
  String checkedInAt(String time);

  /// No description provided for @noShowFarmerNote.
  ///
  /// In en, this message translates to:
  /// **'The host marked that you did not come.'**
  String get noShowFarmerNote;

  /// No description provided for @arrivedAt.
  ///
  /// In en, this message translates to:
  /// **'Arrived at {time}'**
  String arrivedAt(String time);

  /// No description provided for @notArrivedYet.
  ///
  /// In en, this message translates to:
  /// **'Not arrived yet'**
  String get notArrivedYet;

  /// No description provided for @didNotCome.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t come'**
  String get didNotCome;

  /// No description provided for @markNoShowQ.
  ///
  /// In en, this message translates to:
  /// **'Mark that the farmer didn\'t come?'**
  String get markNoShowQ;

  /// No description provided for @markNoShowBody.
  ///
  /// In en, this message translates to:
  /// **'Do this only if the farmer never reached your space. It is saved on the booking.'**
  String get markNoShowBody;

  /// No description provided for @noShowMarkedToast.
  ///
  /// In en, this message translates to:
  /// **'Marked as not come'**
  String get noShowMarkedToast;

  /// No description provided for @nearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Selling near you'**
  String get nearbyTitle;

  /// No description provided for @nearbySetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Fresh produce from farmers near you'**
  String get nearbySetupTitle;

  /// No description provided for @nearbySetupBody.
  ///
  /// In en, this message translates to:
  /// **'Save where you live to see verified farmers selling close by today and tomorrow, and get an email before they come.'**
  String get nearbySetupBody;

  /// No description provided for @locationSaved.
  ///
  /// In en, this message translates to:
  /// **'Location captured'**
  String get locationSaved;

  /// No description provided for @howFar.
  ///
  /// In en, this message translates to:
  /// **'How far will you go?'**
  String get howFar;

  /// No description provided for @radiusKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String radiusKm(int km);

  /// No description provided for @emailAlerts.
  ///
  /// In en, this message translates to:
  /// **'Email alerts'**
  String get emailAlerts;

  /// No description provided for @emailAlertsBody.
  ///
  /// In en, this message translates to:
  /// **'The evening before, and when a farmer arrives'**
  String get emailAlertsBody;

  /// No description provided for @addEmailForAlerts.
  ///
  /// In en, this message translates to:
  /// **'Add your email in My profile to get these alerts.'**
  String get addEmailForAlerts;

  /// No description provided for @areaSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Area saved'**
  String get areaSavedToast;

  /// No description provided for @changeArea.
  ///
  /// In en, this message translates to:
  /// **'Change area'**
  String get changeArea;

  /// No description provided for @removeArea.
  ///
  /// In en, this message translates to:
  /// **'Remove my area'**
  String get removeArea;

  /// No description provided for @areaRemovedToast.
  ///
  /// In en, this message translates to:
  /// **'Area removed'**
  String get areaRemovedToast;

  /// No description provided for @withinKm.
  ///
  /// In en, this message translates to:
  /// **'Within {km} km of your saved place'**
  String withinKm(int km);

  /// No description provided for @sellingNow.
  ///
  /// In en, this message translates to:
  /// **'Selling now'**
  String get sellingNow;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String kmAway(String km);

  /// No description provided for @untilTime.
  ///
  /// In en, this message translates to:
  /// **'until {time}'**
  String untilTime(String time);

  /// No description provided for @nearbyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No farmers are booked near you for today or tomorrow yet. We\'ll email you when one is.'**
  String get nearbyEmpty;

  /// No description provided for @exactPlaceLater.
  ///
  /// In en, this message translates to:
  /// **'Exact place shows when the farmer arrives'**
  String get exactPlaceLater;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
