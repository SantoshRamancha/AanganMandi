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
  /// **'My trips'**
  String get farmerHome;

  /// No description provided for @hostHome.
  ///
  /// In en, this message translates to:
  /// **'My spaces'**
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
  /// **'You are verified. Trips and space bookings open soon.'**
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
