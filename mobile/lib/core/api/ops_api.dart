
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

// Staff (Verifier / Admin) API: farmer verification, space approvals and, for admins, verifier management.
// Labels for its enum values are in core/labels.dart, translated like the rest of the app.

/// The API stores UTC without a "Z"; read it as UTC and show it in local time.
DateTime? _utc(Object? v) {
  if (v is! String) return null;
  return DateTime.parse(v.endsWith('Z') ? v : '${v}Z').toLocal();
}

class OpsDashboard {
  OpsDashboard.fromJson(Map<String, dynamic> j)
      : name = j['name'] as String?,
        isAdmin = j['isAdmin'] as bool,
        farmersWaiting = j['farmersWaiting'] as int,
        farmersUnassigned = j['farmersUnassigned'] as int,
        farmersVerified = j['farmersVerified'] as int,
        verifiers = j['verifiers'] as int,
        spacesWaiting = j['spacesWaiting'] as int,
        spacesLive = j['spacesLive'] as int;

  final String? name;
  final bool isAdmin;
  final int farmersWaiting, farmersUnassigned, farmersVerified, verifiers, spacesWaiting, spacesLive;
}

class OpsFarmerRow {
  OpsFarmerRow.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        name = j['name'] as String?,
        phone = j['phone'] as String,
        village = j['village'] as String?,
        district = j['district'] as String?,
        evidenceType = j['evidenceType'] as String?,
        submittedAt = _utc(j['submittedAt']),
        verifierName = j['verifierName'] as String?;

  final String id, phone;
  final String? name, village, district, evidenceType, verifierName;
  final DateTime? submittedAt;
}

class VerifierOption {
  VerifierOption.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        name = j['name'] as String,
        waiting = j['waiting'] as int;

  final String id, name;
  final int waiting;
}

class OpsFarmer {
  OpsFarmer.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        name = j['name'] as String?,
        phone = j['phone'] as String,
        village = j['village'] as String?,
        district = j['district'] as String?,
        crops = (j['crops'] as List).cast<String>(),
        farmSizeAcres = (j['farmSizeAcres'] as num?)?.toDouble(),
        produceSource = j['produceSource'] as String?,
        evidenceType = j['evidenceType'] as String?,
        evidenceDetails = j['evidenceDetails'] as String?,
        evidencePhoto = j['evidencePhoto'] as String?,
        olderDocuments = [
          for (final d in j['olderDocuments'] as List) (type: d['type'] as String, path: d['path'] as String),
        ],
        status = j['status'] as String,
        rejectionReason = j['rejectionReason'] as String?,
        submittedAt = _utc(j['submittedAt']),
        assignedVerifierId = j['assignedVerifierId'] as String?,
        assignedVerifierName = j['assignedVerifierName'] as String?,
        assignedAt = _utc(j['assignedAt']),
        reviewedByName = j['reviewedByName'] as String?,
        reviewedAt = _utc(j['reviewedAt']),
        canDecide = j['canDecide'] as bool,
        canAssign = j['canAssign'] as bool,
        verifiers = [for (final v in j['verifiers'] as List) VerifierOption.fromJson(v as Map<String, dynamic>)];

  final String id, phone, status;
  final String? name, village, district, produceSource, evidenceType, evidenceDetails, evidencePhoto;
  final String? rejectionReason, assignedVerifierId, assignedVerifierName, reviewedByName;
  final List<String> crops;
  final double? farmSizeAcres;
  final List<({String type, String path})> olderDocuments;
  final DateTime? submittedAt, assignedAt, reviewedAt;
  final bool canDecide, canAssign;
  final List<VerifierOption> verifiers;
}

class OpsSpaceRow {
  OpsSpaceRow.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        title = j['title'] as String,
        type = j['type'] as String,
        locality = j['locality'] as String,
        hostName = j['hostName'] as String,
        updatedAt = _utc(j['updatedAt'])!;

  final String id, title, type, locality, hostName;
  final DateTime updatedAt;
}

class OpsSpace {
  OpsSpace.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        title = j['title'] as String,
        type = j['type'] as String,
        address = j['address'] as String,
        locality = j['locality'] as String,
        latitude = (j['latitude'] as num).toDouble(),
        longitude = (j['longitude'] as num).toDouble(),
        areaSqFt = j['areaSqFt'] as int,
        maxStallSize = j['maxStallSize'] as String,
        maxVehicle = j['maxVehicle'] as String,
        amenities = (j['amenities'] as List).cast<String>(),
        isFree = j['isFree'] as bool,
        fee = (j['fee'] as num).toDouble(),
        rules = j['rules'] as String?,
        availableDays = (j['availableDays'] as List).cast<String>(),
        openFrom = j['openFrom'] as String,
        openTo = j['openTo'] as String,
        status = j['status'] as String,
        rejectionReason = j['rejectionReason'] as String?,
        hostName = j['hostName'] as String,
        hostPhone = j['hostPhone'] as String,
        proof = j['proof'] as String?,
        photos = (j['photos'] as List).cast<String>();

  final String id, title, type, address, locality, maxStallSize, maxVehicle, openFrom, openTo, status, hostName, hostPhone;
  final String? rules, rejectionReason, proof;
  final double latitude, longitude, fee;
  final int areaSqFt;
  final bool isFree;
  final List<String> amenities, availableDays, photos;
}

class VerifierRow {
  VerifierRow.fromJson(Map<String, dynamic> j)
      : userId = j['userId'] as String,
        name = j['name'] as String?,
        phone = j['phone'] as String,
        addedAt = _utc(j['addedAt'])!,
        waiting = j['waiting'] as int,
        reviewed = j['reviewed'] as int;

  final String userId, phone;
  final String? name;
  final DateTime addedAt;
  final int waiting, reviewed;
}

class OpsApi {
  OpsApi(this._dio);
  final Dio _dio;

  Future<OpsDashboard> dashboard() async =>
      OpsDashboard.fromJson((await _dio.get('/ops/dashboard')).data as Map<String, dynamic>);

  /// status: Pending, Verified, Rejected or NotStarted.
  Future<List<OpsFarmerRow>> farmers(String status) async =>
      [for (final j in (await _dio.get('/ops/farmers', queryParameters: {'status': status})).data as List)
        OpsFarmerRow.fromJson(j as Map<String, dynamic>)];

  Future<OpsFarmer> farmer(String id) async =>
      OpsFarmer.fromJson((await _dio.get('/ops/farmers/$id')).data as Map<String, dynamic>);

  Future<void> assignFarmer(String id, String verifierId) =>
      _dio.post('/ops/farmers/$id/assign', data: {'verifierId': verifierId});

  Future<void> decideFarmer(String id, {required bool approve, String? reason}) =>
      _dio.post('/ops/farmers/$id/decision', data: {'approve': approve, 'reason': reason});

  /// status: PendingReview, Live, Rejected or Draft.
  Future<List<OpsSpaceRow>> spaces(String status) async =>
      [for (final j in (await _dio.get('/ops/spaces', queryParameters: {'status': status})).data as List)
        OpsSpaceRow.fromJson(j as Map<String, dynamic>)];

  Future<OpsSpace> space(String id) async =>
      OpsSpace.fromJson((await _dio.get('/ops/spaces/$id')).data as Map<String, dynamic>);

  Future<void> decideSpace(String id, {required bool approve, String? reason}) =>
      _dio.post('/ops/spaces/$id/decision', data: {'approve': approve, 'reason': reason});

  Future<List<VerifierRow>> verifiers() async =>
      [for (final j in (await _dio.get('/ops/verifiers')).data as List) VerifierRow.fromJson(j as Map<String, dynamic>)];

  /// Returns how many waiting farmers with no verifier were assigned to the new one.
  Future<int> addVerifier({required String name, required String phone}) async =>
      (await _dio.post('/ops/verifiers', data: {'name': name, 'phone': phone})).data['assigned'] as int;

  /// Returns how many of their waiting farmers moved to other verifiers, and how many were left unassigned.
  Future<({int moved, int unassigned})> removeVerifier(String userId) async {
    final data = (await _dio.delete('/ops/verifiers/$userId')).data as Map<String, dynamic>;
    return (moved: data['assigned'] as int, unassigned: data['unassigned'] as int);
  }

}

final opsApiProvider = Provider((ref) => OpsApi(ref.watch(dioProvider)));

final opsDashboardProvider = FutureProvider.autoDispose<OpsDashboard>((ref) => ref.watch(opsApiProvider).dashboard());
final opsFarmersProvider =
    FutureProvider.autoDispose.family<List<OpsFarmerRow>, String>((ref, status) => ref.watch(opsApiProvider).farmers(status));
final opsFarmerProvider =
    FutureProvider.autoDispose.family<OpsFarmer, String>((ref, id) => ref.watch(opsApiProvider).farmer(id));
final opsSpacesProvider =
    FutureProvider.autoDispose.family<List<OpsSpaceRow>, String>((ref, status) => ref.watch(opsApiProvider).spaces(status));
final opsSpaceProvider = FutureProvider.autoDispose.family<OpsSpace, String>((ref, id) => ref.watch(opsApiProvider).space(id));
final verifiersProvider = FutureProvider.autoDispose<List<VerifierRow>>((ref) => ref.watch(opsApiProvider).verifiers());

/// Refetches every staff list and the dashboard (after a decision, or the app bar's refresh).
void refreshOps(WidgetRef ref) {
  ref.invalidate(opsDashboardProvider);
  ref.invalidate(opsFarmersProvider);
  ref.invalidate(opsSpacesProvider);
  ref.invalidate(verifiersProvider);
}
