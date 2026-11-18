/// Ratings after a stall and each user's own record (v1 API).
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'trip_models.dart';

/// The signed-in user's record: as a farmer (hosts' stars, stalls, recent no-shows and the limit) and as a host.
class MyRecord {
  MyRecord.fromJson(Map<String, dynamic> j)
    : asFarmer = j['asFarmer'] == null ? null : FarmerRecord.fromJson(j['asFarmer'] as Map<String, dynamic>),
      asHost = j['asHost'] == null ? null : Stars.fromJson(j['asHost'] as Map<String, dynamic>);

  final FarmerRecord? asFarmer;
  final Stars? asHost;
}

class FarmerRecord {
  FarmerRecord.fromJson(Map<String, dynamic> j)
    : stars = Stars.fromJson(j),
      completedStalls = j['completedStalls'] as int,
      recentNoShows = j['recentNoShows'] as int,
      noShowLimit = j['noShowLimit'] as int,
      noShowWindowDays = j['noShowWindowDays'] as int;

  final Stars stars;
  final int completedStalls, recentNoShows, noShowLimit, noShowWindowDays;
}

class RatingApi {
  RatingApi(this._dio);
  final Dio _dio;

  /// Rates a booking that is over: as its farmer (the space) or its host (the farmer). Once per side.
  Future<void> rate(String bookingId, int stars, String? comment) =>
      _dio.post('/bookings/$bookingId/rating', data: {'stars': stars, 'comment': comment});

  Future<MyRecord> mine() async => MyRecord.fromJson((await _dio.get('/users/me/record')).data as Map<String, dynamic>);
}

final ratingApiProvider = Provider((ref) => RatingApi(ref.watch(dioProvider)));
final myRecordProvider = FutureProvider.autoDispose<MyRecord>((ref) => ref.watch(ratingApiProvider).mine());
