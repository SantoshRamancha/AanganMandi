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
  String get farmerHome => 'Home';

  @override
  String get hostHome => 'Home';

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
      'You are verified. Plan a trip and book a space to start selling.';

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

  @override
  String get profileTitle => 'My profile';

  @override
  String get accountDetails => 'Account details';

  @override
  String get name => 'Name';

  @override
  String get nameNotSet => 'Not added yet';

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get memberSince => 'Member since';

  @override
  String get yourRoles => 'Using the app as';

  @override
  String get roleNameFarmer => 'Farmer';

  @override
  String get roleNameHost => 'Space host';

  @override
  String get roleNameBuyer => 'Buyer';

  @override
  String get roleNameVerifier => 'Verifier';

  @override
  String get roleNameAdmin => 'Admin';

  @override
  String get verificationStatus => 'Verification';

  @override
  String get farmDetails => 'Farming details';

  @override
  String get crops => 'Crops';

  @override
  String get mySpaces => 'My spaces';

  @override
  String mySpacesSummary(int count, int live) {
    return '$count listed · $live live';
  }

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystemHint =>
      'System follows your phone or computer setting.';

  @override
  String get staffAccessRevokedTitle => 'You no longer have staff access';

  @override
  String get staffAccessRevokedBody =>
      'Ask an admin if you think this is a mistake. Log out to continue with your other account.';

  @override
  String get opsTabDashboard => 'Dashboard';

  @override
  String get opsTabFarmers => 'Farmers';

  @override
  String get opsTabSpaces => 'Spaces';

  @override
  String get opsTabVerifiers => 'Verifiers';

  @override
  String opsHello(String name) {
    return 'Hello, $name';
  }

  @override
  String get opsHelloNoName => 'Hello';

  @override
  String get opsAdminSubtitle =>
      'Admin · you see every farmer and manage verifiers';

  @override
  String get opsVerifierSubtitle =>
      'Verifier · you review the farmers assigned to you';

  @override
  String get statFarmersWaitingAll => 'Farmers waiting for review';

  @override
  String get statFarmersWaitingYou => 'Farmers waiting for you';

  @override
  String get statUnassigned => 'Waiting with no verifier';

  @override
  String get statSpacesWaiting => 'Spaces waiting for approval';

  @override
  String get statVerifiedAll => 'Verified farmers';

  @override
  String get statVerifiedYou => 'Farmers you verified';

  @override
  String get statSpacesLive => 'Live spaces';

  @override
  String get couldNotLoad =>
      'Could not load. Pull down or tap refresh to try again.';

  @override
  String get couldNotSave => 'Could not save. Try again.';

  @override
  String get emptyList => 'Nothing in this list.';

  @override
  String get noName => '(no name)';

  @override
  String get decision => 'Decision';

  @override
  String get reasonLabel => 'Reason (required to reject; they will see it)';

  @override
  String get reject => 'Reject';

  @override
  String rejectedWith(String reason) {
    return 'Rejected: $reason';
  }

  @override
  String get unassigned => 'Unassigned';

  @override
  String get farmerStatusPending => 'Waiting for review';

  @override
  String get farmerStatusVerified => 'Verified';

  @override
  String get farmerStatusRejected => 'Rejected';

  @override
  String get farmerStatusNotStarted => 'Not submitted';

  @override
  String get farmerVerificationTitle => 'Farmer verification';

  @override
  String get farmerQueueAdminHint =>
      'All farmers. Each submission goes to the verifier with the fewest waiting.';

  @override
  String get farmerQueueVerifierHint =>
      'Farmers assigned to you, oldest first.';

  @override
  String get noVerifierWarnTitle => 'Some farmers have no verifier';

  @override
  String get noVerifierWarnBody =>
      'Add a verifier and they are assigned automatically, or open a farmer to assign one.';

  @override
  String submittedOn(String when) {
    return 'Submitted $when';
  }

  @override
  String verifierIs(String name) {
    return 'Verifier: $name';
  }

  @override
  String get reviewFarmer => 'Review farmer';

  @override
  String get qrFarmerPhotoUnclear =>
      'Evidence photo is unclear — please retake it';

  @override
  String get qrFarmerNameMismatch => 'Name on the evidence does not match';

  @override
  String get qrFarmerIdUnconfirmed => 'Could not confirm the Farmer ID';

  @override
  String get qrFarmerRefereeNo => 'The referee did not confirm you';

  @override
  String get qrFarmerNotGrower =>
      'You sell only produce bought from other farmers';

  @override
  String phoneOtpVerified(String phone) {
    return '$phone (OTP verified)';
  }

  @override
  String get farmSize => 'Farm size';

  @override
  String get notGiven => 'Not given';

  @override
  String aboutAcres(String acres) {
    return 'About $acres acres';
  }

  @override
  String get sells => 'Sells';

  @override
  String get sellsOwnFarm => 'Only what they grow';

  @override
  String get sellsOwnAndOthers => 'Own crops, plus some from other farmers';

  @override
  String get sellsOthers => 'Only produce from other farmers (not a grower)';

  @override
  String get submitted => 'Submitted';

  @override
  String get farmingEvidence => 'Farming evidence';

  @override
  String get factType => 'Type';

  @override
  String get factDetails => 'Details';

  @override
  String get noPhoto => 'No photo';

  @override
  String get olderDocuments => 'Documents from the earlier verification flow';

  @override
  String get howCheckAgriStack =>
      'Check the Farmer ID number and name in the AgriStack farmer registry.';

  @override
  String get howCheckLandRecord =>
      'Check the owner or cultivator name and survey number on the Bhu Bharati portal.';

  @override
  String get howCheckFpo =>
      'Call the FPO (or the person who referred them) and confirm they know this farmer.';

  @override
  String get howCheckOfficer =>
      'Call the officer or organisation and confirm they know this farmer.';

  @override
  String get farmerApproveGuidance =>
      'Approve only if the evidence is real, the name on it matches this farmer, and they grow what they sell.';

  @override
  String get farmerApproveLabel => 'Approve — verified farmer';

  @override
  String farmerApprovedToast(String name) {
    return 'Approved: $name is a verified farmer';
  }

  @override
  String get farmerRejectedToast =>
      'Rejected. The farmer will see your reason.';

  @override
  String get assignedTo => 'Assigned to';

  @override
  String get assignedOn => 'Assigned on';

  @override
  String get reviewedBy => 'Reviewed by';

  @override
  String get verifierAssignedToast => 'Verifier assigned';

  @override
  String get noVerifiersYetAssign =>
      'There are no verifiers yet. Add one on the Verifiers tab.';

  @override
  String get chooseVerifier => 'Choose a verifier';

  @override
  String verifierOption(String name, int count) {
    return '$name ($count waiting)';
  }

  @override
  String get assign => 'Assign';

  @override
  String get reassign => 'Reassign';

  @override
  String get spaceApprovals => 'Space approvals';

  @override
  String hostedBy(String host, String when) {
    return 'Host: $host · updated $when';
  }

  @override
  String get reviewSpace => 'Review space';

  @override
  String get qrSpacePublicRoad => 'Space is on a public road or footpath';

  @override
  String get qrSpacePhotos => 'Photos are unclear or do not show the space';

  @override
  String get qrSpaceProof =>
      'Proof document does not show the right to use this space';

  @override
  String get qrSpacePin => 'Location pin does not match the address';

  @override
  String get spaceSection => 'Space';

  @override
  String get usableArea => 'Usable area';

  @override
  String areaValue(int area, String stall) {
    return '$area sq ft (stall up to $stall)';
  }

  @override
  String get none => 'None';

  @override
  String get openInMaps => 'Open location in maps';

  @override
  String get availabilityAndHost => 'Availability and host';

  @override
  String get hours => 'Hours';

  @override
  String get fee => 'Fee';

  @override
  String get freeCommunitySpace => 'Free community space';

  @override
  String get rules => 'House rules';

  @override
  String get host => 'Host';

  @override
  String get proofMissing => 'Proof is missing';

  @override
  String photosCount(int count) {
    return 'Photos ($count)';
  }

  @override
  String get spaceApproveGuidance =>
      'Approve only if it is private space (not a road or footpath), the photos match the location, and the proof names the host or allows the use.';

  @override
  String get spaceApproveLabel => 'Approve — make live';

  @override
  String spaceLiveToast(String title) {
    return '$title is live';
  }

  @override
  String get spaceRejectedToast => 'Rejected. The host will see your reason.';

  @override
  String get verifiersHint =>
      'Each farmer who submits goes to the verifier with the fewest farmers waiting; a resubmission goes back to the same verifier.';

  @override
  String get addVerifierTitle => 'Add a verifier';

  @override
  String get addVerifierButton => 'Add verifier';

  @override
  String get enterName => 'Enter the name';

  @override
  String get enterTenDigits => 'Enter a 10-digit number';

  @override
  String verifierAddedToast(String name, String phone) {
    return 'Added $name. They can sign in with +91 $phone.';
  }

  @override
  String farmersAssignedToNew(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waiting farmers were assigned to them.',
      one: '1 waiting farmer was assigned to them.',
    );
    return '$_temp0';
  }

  @override
  String removeVerifierQ(String name) {
    return 'Remove $name?';
  }

  @override
  String get removeVerifierBody =>
      'They can no longer review farmers or spaces.';

  @override
  String removeVerifierMoves(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Their $count waiting farmers move to the other verifiers.',
      one: 'Their 1 waiting farmer moves to the other verifiers.',
    );
    return '$_temp0';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String verifierRemovedToast(String name) {
    return 'Removed $name.';
  }

  @override
  String farmersMoved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waiting farmers moved to other verifiers.',
      one: '1 waiting farmer moved to other verifiers.',
    );
    return '$_temp0';
  }

  @override
  String farmersNowUnassigned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count farmers are now unassigned: add a verifier to pick them up.',
      one: '1 farmer is now unassigned: add a verifier to pick them up.',
    );
    return '$_temp0';
  }

  @override
  String get noVerifiersBody =>
      'No verifiers yet. Farmers who submit stay unassigned until you add one.';

  @override
  String verifierAddedOn(String phone, String when) {
    return '$phone · added $when';
  }

  @override
  String verifierCounts(int waiting, int reviewed) {
    return '$waiting waiting · $reviewed reviewed';
  }

  @override
  String get removeVerifierTooltip => 'Remove verifier';

  @override
  String get preview => 'Preview';

  @override
  String get download => 'Download';

  @override
  String get reupload => 'Reupload';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get uploadPhoto => 'Upload photo';

  @override
  String get downloadSaved => 'Downloaded';

  @override
  String get downloadFailed => 'Could not download. Try again.';

  @override
  String get deleteDocumentQ => 'Delete this photo?';

  @override
  String get deleteDocumentBody => 'You can upload a new one afterwards.';

  @override
  String get documentLocked => 'Approved — this can no longer be changed.';

  @override
  String get evidenceWithdrawWarning =>
      'Your verification is waiting for review. Deleting the evidence takes it out of the queue: upload a new photo and submit again.';

  @override
  String get evidenceWithdrawnToast =>
      'Photo deleted. Upload a new one and submit again.';

  @override
  String get spaceWithdrawWarning =>
      'This space is waiting for approval. If it ends up with fewer than 3 photos or no proof, it goes back to draft and you submit it again.';

  @override
  String get spaceWithdrawnToast =>
      'Photo deleted. The space went back to draft: add what is missing and submit again.';

  @override
  String get photoDeletedToast => 'Photo deleted';

  @override
  String photoNumber(int number) {
    return 'Photo $number';
  }

  @override
  String get yourDocument => 'Your document';

  @override
  String get yourDocumentPendingHint =>
      'You can still replace or delete it while it waits for review.';

  @override
  String get bookingRequested => 'Waiting for host';

  @override
  String get bookingAccepted => 'Space booked';

  @override
  String get bookingDeclined => 'Declined';

  @override
  String get bookingCancelled => 'Cancelled';

  @override
  String get tripPlanned => 'Planned';

  @override
  String get tripCompleted => 'Completed';

  @override
  String kgAmount(String amount) {
    return '$amount kg';
  }

  @override
  String pricePerKgAmount(String price) {
    return '₹$price/kg';
  }

  @override
  String get bookingSlotTaken =>
      'The host confirmed another farmer for this day.';

  @override
  String bookingDeclinedBecause(String reason) {
    return 'The host declined: $reason';
  }

  @override
  String bookingHostCancelled(String reason) {
    return 'The host cancelled: $reason';
  }

  @override
  String get bookingYouCancelled => 'You cancelled this booking.';

  @override
  String upToVehicle(String vehicle) {
    return 'Fits up to a $vehicle';
  }

  @override
  String get myTrips => 'My trips';

  @override
  String get planTrip => 'Plan a trip';

  @override
  String get noTripsTitle => 'No trips yet';

  @override
  String get noTripsBody =>
      'Plan the day you will come to the city to sell, then book a space near your buyers.';

  @override
  String get noSpaceYet => 'No space booked yet';

  @override
  String get editTrip => 'Edit trip';

  @override
  String get tripWhen => 'When are you coming?';

  @override
  String get tripDateLocked =>
      'Date and vehicle are fixed while a space is requested or booked. Cancel the booking to change them.';

  @override
  String get chooseDate => 'Choose a date';

  @override
  String get tripVehicle => 'Your vehicle';

  @override
  String get tripVehicleHint => 'We only show spaces it can enter.';

  @override
  String get tripProduce => 'What will you bring?';

  @override
  String get tripProduceHint =>
      'Choose the crops. Quantity and price are optional and help the host.';

  @override
  String get quantityKg => 'kg';

  @override
  String get priceKg => '₹ per kg';

  @override
  String get tripWhere => 'Where would you like to sell?';

  @override
  String get preferredArea => 'Area (optional)';

  @override
  String get preferredAreaHint => 'e.g. Ameerpet, Kukatpally';

  @override
  String get tripNotes => 'Notes (optional)';

  @override
  String get saveTripFindSpace => 'Save and find a space';

  @override
  String get tripNeedsDateAndCrop => 'Choose a date and at least one crop';

  @override
  String get cancelTrip => 'Cancel trip';

  @override
  String get cancelTripQ => 'Cancel this trip?';

  @override
  String get cancelTripBody =>
      'Any space you requested or booked for it is cancelled too, and the host is told.';

  @override
  String get tripCancelledToast => 'Trip cancelled';

  @override
  String get tripDetails => 'Trip';

  @override
  String get cancelBookingQ => 'Cancel this booking?';

  @override
  String get cancelBookingBody =>
      'The other side is told and the slot opens again.';

  @override
  String get cancelBooking => 'Cancel booking';

  @override
  String get bookingCancelledToast => 'Booking cancelled';

  @override
  String get spaceBookedTitle => 'Space booked — see you there';

  @override
  String get payAtSpace => 'pay the host at the space';

  @override
  String get callHost => 'Call host';

  @override
  String get waitingForHostTitle => 'Waiting for the host';

  @override
  String get waitingForHostBody =>
      'The host will accept or decline your request. You will see the address and phone number once they accept.';

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get spaceForTrip => 'Space for this trip';

  @override
  String get findSpaceIntro =>
      'Find a space that is open on this day and fits your vehicle.';

  @override
  String get findAnotherSpaceIntro =>
      'You can request another space for this day.';

  @override
  String get findSpace => 'Find a space';

  @override
  String get findAnotherSpace => 'Find another space';

  @override
  String get tripWasCancelled => 'This trip was cancelled.';

  @override
  String get tripIsOver => 'This trip date has passed.';

  @override
  String requestSpaceTitle(String title) {
    return 'Request $title';
  }

  @override
  String get messageToHost => 'Message to the host (optional)';

  @override
  String get messageToHostHint =>
      'e.g. I will come in an auto with 3 crates of tomatoes';

  @override
  String get sendRequest => 'Send request';

  @override
  String get requestSentToast =>
      'Request sent. You will see the answer on your trip.';

  @override
  String spacesFor(String date) {
    return 'Spaces for $date';
  }

  @override
  String get searchArea => 'Search an area (e.g. Ameerpet)';

  @override
  String get clear => 'Clear';

  @override
  String spacesMatchHint(String vehicle) {
    return 'Spaces open that day that fit your $vehicle. The exact address is shared once the host accepts.';
  }

  @override
  String get noSpacesThatDay =>
      'No free spaces fit your vehicle on this day. Try another date.';

  @override
  String get noSpacesInArea =>
      'No free spaces in this area on this day. Clear the search to see all areas.';

  @override
  String get requestThisSpace => 'Request this space';

  @override
  String get bookings => 'Bookings';

  @override
  String get bookingsHint => 'Farmers\' requests and confirmed days';

  @override
  String requestsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count farmers are waiting for your answer',
      one: '1 farmer is waiting for your answer',
    );
    return '$_temp0';
  }

  @override
  String requestsCount(int count) {
    return 'Requests ($count)';
  }

  @override
  String get bookingRequestsTab => 'Requests';

  @override
  String get upcomingTab => 'Upcoming';

  @override
  String get pastTab => 'Past';

  @override
  String get noRequests =>
      'No new requests. Farmers\' requests for your spaces appear here.';

  @override
  String get noUpcoming => 'No confirmed bookings coming up.';

  @override
  String get noPastBookings => 'No past bookings yet.';

  @override
  String get reasonForFarmer => 'Reason (the farmer will see it)';

  @override
  String get verifiedFarmerTag => 'verified farmer';

  @override
  String get hostAutoDeclined =>
      'Declined automatically: you confirmed another farmer for this day.';

  @override
  String get farmerCancelled => 'The farmer cancelled.';

  @override
  String yourReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get acceptedToast =>
      'Accepted. The farmer can now see your address and phone.';

  @override
  String get declineQ => 'Decline this request?';

  @override
  String get qrNotAvailableDay => 'The space is not available that day';

  @override
  String get qrVehicleTooBig => 'The vehicle will not fit';

  @override
  String get qrOnlySomeProduce => 'I can\'t host this kind of produce';

  @override
  String get declinedToast => 'Request declined';

  @override
  String get callFarmer => 'Call farmer';

  @override
  String get newRequest => 'New request';

  @override
  String greetingName(String name) {
    return 'Namaste, $name';
  }

  @override
  String get greetingNoName => 'Namaste';

  @override
  String get farmerBannerVerified =>
      'You are a verified farmer. Plan your next selling day.';

  @override
  String get farmerBannerNotVerified =>
      'Get verified once, then sell your fresh produce in the city.';

  @override
  String get statUpcomingTrips => 'Upcoming trips';

  @override
  String get statSpacesBooked => 'Spaces booked';

  @override
  String get statWaitingHost => 'Waiting for host';

  @override
  String get statCompletedTrips => 'Trips done';

  @override
  String get nextTrip => 'Your next trip';

  @override
  String get noUpcomingTitle => 'No trip planned';

  @override
  String get noUpcomingBody =>
      'Choose a day to come to the city, then book a space near buyers.';

  @override
  String get viewTrip => 'View trip';

  @override
  String get allTrips => 'All trips';

  @override
  String get yourVerification => 'Your verification';

  @override
  String get howItWorks => 'How it works';

  @override
  String get howStepVerify => 'Get verified';

  @override
  String get howStepVerifyBody =>
      'Tell us about your farming and add one proof. A verifier checks it.';

  @override
  String get howStepTrip => 'Plan a trip';

  @override
  String get howStepTripBody =>
      'Pick the day, your vehicle and what you will bring.';

  @override
  String get howStepBook => 'Book a space';

  @override
  String get howStepBookBody =>
      'Request a driveway or courtyard near buyers. The host accepts.';

  @override
  String get howStepSell => 'Sell fresh';

  @override
  String get howStepSellBody =>
      'Set up your stall and sell straight to families nearby.';

  @override
  String bookedAt(String space) {
    return 'Booked at $space';
  }

  @override
  String waitingAt(String space) {
    return 'Waiting for $space to accept';
  }

  @override
  String hostBanner(int live, int waiting) {
    return 'Spaces live: $live · New requests: $waiting';
  }

  @override
  String get hostBannerNew =>
      'List your driveway or courtyard and earn when farmers sell there.';

  @override
  String get statNewRequests => 'New requests';

  @override
  String get statUpcomingBookings => 'Upcoming bookings';

  @override
  String get needsYourAnswer => 'Needs your answer';

  @override
  String get viewAll => 'View all';

  @override
  String get nextBooking => 'Next booking';

  @override
  String get noBookingYet =>
      'No confirmed bookings yet. Accepted requests show here.';

  @override
  String get answer => 'Answer';

  @override
  String get hostHowList => 'List your space';

  @override
  String get hostHowListBody =>
      'Photos, days and hours, fee, and proof you can use the space.';

  @override
  String get hostHowApproved => 'Get approved';

  @override
  String get hostHowApprovedBody =>
      'Our team checks the photos, location and proof.';

  @override
  String get hostHowRequests => 'Farmers request a day';

  @override
  String get hostHowRequestsBody =>
      'Verified farmers ask for your space for their selling day.';

  @override
  String get hostHowAccept => 'Accept and host';

  @override
  String get hostHowAcceptBody =>
      'Accept, share your address, and collect the fee at the space.';
}
