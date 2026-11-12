import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'models.dart';

/// The photo's real type from its first bytes: jpeg, png or webp, or null for anything else. The picker's own label
/// can be wrong: on web it re-draws a photo to shrink it, so an AVIF arrives as PNG bytes still labelled image/avif.
String? photoSubtype(List<int> b) {
  bool starts(List<int> sig, [int at = 0]) =>
      b.length >= at + sig.length && [for (var i = 0; i < sig.length; i++) b[at + i] == sig[i]].every((ok) => ok);
  if (starts([0xFF, 0xD8, 0xFF])) return 'jpeg';
  if (starts([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) return 'png';
  if (starts('RIFF'.codeUnits) && starts('WEBP'.codeUnits, 8)) return 'webp';
  return null;
}

/// Builds a multipart file from a picked photo (works on Android and web). The server checks the bytes too, and
/// answers "Only JPEG, PNG or WebP photos are accepted" for anything else (e.g. HEIC on a browser that can't show it).
Future<MultipartFile> _photoPart(XFile photo) async {
  final bytes = await photo.readAsBytes();
  final subtype = photoSubtype(bytes);
  return MultipartFile.fromBytes(bytes,
      filename: 'photo.${subtype == 'jpeg' ? 'jpg' : subtype ?? 'bin'}',
      contentType: subtype == null ? DioMediaType('application', 'octet-stream') : DioMediaType('image', subtype));
}

class FarmerApi {
  FarmerApi(this._dio);
  final Dio _dio;

  Future<Farmer> me() async => Farmer.fromJson((await _dio.get('/farmers/me')).data as Map<String, dynamic>);

  /// produceSource: OwnFarm, OwnAndOtherFarmers or OtherFarmers.
  Future<void> saveDetails({
    required String name,
    required String village,
    required String district,
    required List<String> cropCodes,
    required double? farmSizeAcres,
    required String produceSource,
  }) =>
      _dio.put('/farmers/me/details', data: {
        'name': name,
        'village': village,
        'district': district,
        'cropCodes': cropCodes,
        'farmSizeAcres': farmSizeAcres,
        'produceSource': produceSource,
      });

  /// type: AgriStackFarmerId, LandRecord, FpoMembership or OfficerReference.
  Future<void> saveEvidence({required String type, required String? details}) =>
      _dio.put('/farmers/me/evidence', data: {'type': type, 'details': details});

  Future<void> uploadEvidencePhoto(XFile photo) async {
    await _dio.post('/farmers/me/evidence/photo', data: FormData.fromMap({'file': await _photoPart(photo)}));
  }

  /// True when this withdrew a waiting submission (the farmer must submit again).
  Future<bool> deleteEvidencePhoto() async =>
      ((await _dio.delete('/farmers/me/evidence/photo')).data as Map)['withdrawn'] as bool;

  /// Clears details, crops, evidence and the evidence photo (not the name). True when this withdrew a waiting
  /// submission. Refused once verified.
  Future<bool> resetVerification() async =>
      ((await _dio.delete('/farmers/me/verification')).data as Map)['withdrawn'] as bool;

  Future<void> submit() => _dio.post('/farmers/me/submit');
}

/// API path of the farmer's own evidence photo; [version] (upload time) makes a replaced photo refetch.
String evidencePhotoPath(String? version) => '/farmers/me/evidence/photo?v=$version';

class HostApi {
  HostApi(this._dio);
  final Dio _dio;

  Future<List<Space>> mySpaces() async => ((await _dio.get('/hosts/me/spaces')).data as List)
      .map((j) => Space.fromJson(j as Map<String, dynamic>))
      .toList();

  Future<Space> get(String id) async =>
      Space.fromJson((await _dio.get('/hosts/me/spaces/$id')).data as Map<String, dynamic>);

  Future<Space> create(Map<String, dynamic> body) async =>
      Space.fromJson((await _dio.post('/hosts/me/spaces', data: body)).data as Map<String, dynamic>);

  Future<Space> update(String id, Map<String, dynamic> body) async =>
      Space.fromJson((await _dio.put('/hosts/me/spaces/$id', data: body)).data as Map<String, dynamic>);

  Future<void> addPhoto(String spaceId, XFile photo, {bool isProof = false}) async {
    await _dio.post('/hosts/me/spaces/$spaceId/photos',
        data: FormData.fromMap({'file': await _photoPart(photo), 'isProof': isProof}));
  }

  Future<void> replacePhoto(String spaceId, String photoId, XFile photo) async {
    await _dio.put('/hosts/me/spaces/$spaceId/photos/$photoId', data: FormData.fromMap({'file': await _photoPart(photo)}));
  }

  /// True when this sent a waiting space back to draft (fewer than 3 photos or no proof left).
  Future<bool> deletePhoto(String spaceId, String photoId) async =>
      ((await _dio.delete('/hosts/me/spaces/$spaceId/photos/$photoId')).data as Map)['withdrawn'] as bool;

  Future<void> submit(String spaceId) => _dio.post('/hosts/me/spaces/$spaceId/submit');

  /// Deletes the space with its photos and proof; returns how many upcoming bookings were cancelled.
  Future<int> deleteSpace(String spaceId) async =>
      ((await _dio.delete('/hosts/me/spaces/$spaceId')).data as Map)['cancelledBookings'] as int;
}

/// API path of one of the host's space photos or proof, for preview and download.
String spaceFilePath(String spaceId, SpaceFile f) => '/hosts/me/spaces/$spaceId/photos/${f.id}?v=${f.uploadedAt}';

final farmerApiProvider = Provider((ref) => FarmerApi(ref.watch(dioProvider)));
final hostApiProvider = Provider((ref) => HostApi(ref.watch(dioProvider)));

final cropsProvider = FutureProvider<List<Crop>>((ref) async {
  final res = await ref.watch(dioProvider).get('/master/crops');
  return (res.data as List).map((j) => Crop.fromJson(j as Map<String, dynamic>)).toList();
});

final farmerProvider = FutureProvider.autoDispose<Farmer>((ref) => ref.watch(farmerApiProvider).me());

final mySpacesProvider = FutureProvider.autoDispose<List<Space>>((ref) => ref.watch(hostApiProvider).mySpaces());

final profileProvider = FutureProvider.autoDispose<Profile>(
    (ref) async => Profile.fromJson((await ref.watch(dioProvider).get('/users/me')).data as Map<String, dynamic>));
