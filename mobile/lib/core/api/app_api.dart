import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'models.dart';

/// Builds a multipart file from a picked photo (works on Android and web).
Future<MultipartFile> _photoPart(XFile photo) async {
  final bytes = await photo.readAsBytes();
  final mime = photo.mimeType ??
      (photo.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');
  final parts = mime.split('/');
  return MultipartFile.fromBytes(bytes,
      filename: photo.name.isEmpty ? 'photo.jpg' : photo.name, contentType: DioMediaType(parts[0], parts[1]));
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

  Future<void> submit() => _dio.post('/farmers/me/submit');
}

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

  Future<void> addPhoto(String spaceId, XFile photo, {bool isProof = false}) async {
    await _dio.post('/hosts/me/spaces/$spaceId/photos',
        data: FormData.fromMap({'file': await _photoPart(photo), 'isProof': isProof}));
  }

  Future<void> submit(String spaceId) => _dio.post('/hosts/me/spaces/$spaceId/submit');
}

final farmerApiProvider = Provider((ref) => FarmerApi(ref.watch(dioProvider)));
final hostApiProvider = Provider((ref) => HostApi(ref.watch(dioProvider)));

final cropsProvider = FutureProvider<List<Crop>>((ref) async {
  final res = await ref.watch(dioProvider).get('/master/crops');
  return (res.data as List).map((j) => Crop.fromJson(j as Map<String, dynamic>)).toList();
});

final farmerProvider = FutureProvider.autoDispose<Farmer>((ref) => ref.watch(farmerApiProvider).me());

final mySpacesProvider = FutureProvider.autoDispose<List<Space>>((ref) => ref.watch(hostApiProvider).mySpaces());
