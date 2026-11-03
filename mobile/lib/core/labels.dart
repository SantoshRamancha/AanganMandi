import '../l10n/app_localizations.dart';

/// Translated labels for the API's enum values, which travel as their C# names ("PendingReview").
extension ApiLabels on AppLocalizations {
  String farmerStatus(String s) => switch (s) {
        'Pending' => farmerStatusPending,
        'Verified' => farmerStatusVerified,
        'Rejected' => farmerStatusRejected,
        _ => farmerStatusNotStarted,
      };

  /// Staff wording ("Rejected"); hosts see the softer statusRejected ("Needs changes").
  String spaceStatus(String s) => switch (s) {
        'PendingReview' => statusPendingReview,
        'Live' => statusLive,
        'Rejected' => farmerStatusRejected,
        _ => statusDraft,
      };

  String evidence(String? t) => switch (t) {
        'AgriStackFarmerId' => evidenceAgriStack,
        'LandRecord' => evidenceLandRecord,
        'FpoMembership' => evidenceFpo,
        'OfficerReference' => evidenceOfficer,
        _ => '–',
      };

  /// How a reviewer checks each kind of evidence.
  String evidenceHowToCheck(String? t) => switch (t) {
        'AgriStackFarmerId' => howCheckAgriStack,
        'LandRecord' => howCheckLandRecord,
        'FpoMembership' => howCheckFpo,
        'OfficerReference' => howCheckOfficer,
        _ => '',
      };

  /// What the farmer sells, in the third person (for reviewers).
  String produceSource(String? s) => switch (s) {
        'OwnFarm' => sellsOwnFarm,
        'OwnAndOtherFarmers' => sellsOwnAndOthers,
        'OtherFarmers' => sellsOthers,
        _ => '–',
      };

  String spaceKind(String t) => switch (t) {
        'Driveway' => driveway,
        'Courtyard' => courtyard,
        'OpenArea' => openArea,
        'CommercialFrontage' => commercialFrontage,
        _ => t,
      };

  String vehicle(String v) => switch (v) {
        'TwoWheeler' => twoWheeler,
        'Auto' => auto,
        'MiniTruck' => miniTruck,
        'Tractor' => tractor,
        _ => v,
      };

  String amenity(String a) => switch (a) {
        'Water' => water,
        'Shade' => shade,
        'PowerPoint' => powerPoint,
        'BuyerParking' => buyerParking,
        'LoadingAccess' => loadingAccess,
        'Toilet' => toilet,
        _ => a,
      };

  String roleName(String r) => switch (r) {
        'Farmer' => roleNameFarmer,
        'Host' => roleNameHost,
        'Buyer' => roleNameBuyer,
        'Verifier' => roleNameVerifier,
        'Admin' => roleNameAdmin,
        _ => r,
      };
}
