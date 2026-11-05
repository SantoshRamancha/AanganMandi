/// Plain JSON models for the v1 API. Enum values travel as their C# names (e.g. "Pending").
library;

class Crop {
  Crop.fromJson(Map<String, dynamic> j)
      : code = j['code'] as String,
        nameEn = j['nameEn'] as String,
        nameTe = j['nameTe'] as String,
        nameHi = j['nameHi'] as String,
        category = j['category'] as String? ?? 'Other';

  final String code, nameEn, nameTe, nameHi;

  /// Vegetable, Leafy, Fruit, Grain, Pulse, Oilseed, Spice, Flower (or Other).
  final String category;

  String name(String lang) => switch (lang) { 'te' => nameTe, 'hi' => nameHi, _ => nameEn };

  /// Whether [query] is part of the name in any language (search works whatever the app language).
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    return nameEn.toLowerCase().contains(q) || nameTe.contains(q) || nameHi.contains(q);
  }
}

/// Verification status: NotStarted, Pending, Verified or Rejected.
/// produceSource: OwnFarm, OwnAndOtherFarmers or OtherFarmers.
/// evidenceType: AgriStackFarmerId, LandRecord, FpoMembership or OfficerReference.
class Farmer {
  Farmer.fromJson(Map<String, dynamic> j)
      : name = j['name'] as String?,
        village = j['village'] as String?,
        district = j['district'] as String?,
        cropCodes = (j['cropCodes'] as List).cast<String>(),
        farmSizeAcres = (j['farmSizeAcres'] as num?)?.toDouble(),
        produceSource = j['produceSource'] as String?,
        evidenceType = j['evidenceType'] as String?,
        evidenceDetails = j['evidenceDetails'] as String?,
        hasEvidencePhoto = j['hasEvidencePhoto'] as bool,
        evidencePhotoAt = j['evidencePhotoAt'] as String?,
        status = j['status'] as String,
        level = j['level'] as int,
        rejectionReason = j['rejectionReason'] as String?,
        missing = (j['missing'] as List).cast<String>();

  final String? name, village, district, produceSource, evidenceType, evidenceDetails, rejectionReason;

  /// When the evidence photo was uploaded (also its cache key).
  final String? evidencePhotoAt;
  final List<String> cropCodes;
  final double? farmSizeAcres;
  final bool hasEvidencePhoto;
  final String status;
  final int level;
  final List<String> missing;

  bool get canEdit => status == 'NotStarted' || status == 'Rejected';
  /// True once any verification step was saved (the name alone may come from sign-up).
  bool get hasStarted => village != null || evidenceType != null || hasEvidencePhoto;
}

/// Space status: Draft, PendingReview, Live or Rejected.
class Space {
  Space.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        title = j['title'] as String,
        type = j['type'] as String,
        address = j['address'] as String,
        locality = j['locality'] as String,
        areaSqFt = j['areaSqFt'] as int,
        isFree = j['isFree'] as bool,
        fee = (j['fee'] as num).toDouble(),
        availableDays = (j['availableDays'] as List).cast<String>(),
        openFrom = j['openFrom'] as String,
        openTo = j['openTo'] as String,
        status = j['status'] as String,
        rejectionReason = j['rejectionReason'] as String?,
        photoUrls = (j['photoUrls'] as List).cast<String>(),
        hasProof = j['hasProof'] as bool,
        photos = [for (final p in j['photos'] as List) SpaceFile.fromJson(p as Map<String, dynamic>)],
        proof = j['proof'] == null ? null : SpaceFile.fromJson(j['proof'] as Map<String, dynamic>);

  final String id, title, type, address, locality, openFrom, openTo, status;
  final String? rejectionReason;
  final int areaSqFt;
  final bool isFree, hasProof;
  final double fee;
  final List<String> availableDays, photoUrls;
  final List<SpaceFile> photos;
  final SpaceFile? proof;

  bool get canSubmit => status == 'Draft' || status == 'Rejected';

  /// Photos and proof can be replaced or deleted until the space is approved (live).
  bool get canChangeFiles => status != 'Live';
}

/// One stored space photo or the proof; uploadedAt doubles as its cache key.
class SpaceFile {
  SpaceFile.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        uploadedAt = j['uploadedAt'] as String;

  final String id, uploadedAt;
}

/// The signed-in user's own account (GET /users/me). roles: Farmer, Host, Buyer, Verifier, Admin.
class Profile {
  Profile.fromJson(Map<String, dynamic> j)
      : name = j['name'] as String?,
        phone = j['phone'] as String,
        email = j['email'] as String?,
        language = j['language'] as String,
        roles = (j['roles'] as List).cast<String>(),
        // The API stores UTC without a "Z".
        memberSince = DateTime.parse('${(j['memberSince'] as String).replaceAll('Z', '')}Z').toLocal();

  final String? name;

  /// Where email updates go; null when the user has not added one.
  final String? email;
  final String phone, language;
  final List<String> roles;
  final DateTime memberSince;
}
