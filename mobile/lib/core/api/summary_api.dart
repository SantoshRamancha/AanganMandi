import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_api.dart' show TopItem;
import 'api_client.dart';

// A host's "My earnings" (GET /hosts/me/summary) and a farmer's "My stalls" (GET /farmers/me/summary),
// for the last 30, 90 or 365 days.

int _i(Object? v) => (v as num?)?.toInt() ?? 0;
double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
double? _dOrNull(Object? v) => (v as num?)?.toDouble();

/// The periods a host or farmer can pick (the server accepts only these).
const summaryPeriods = [30, 90, 365];

/// One of the host's spaces in the period: stalls held there and the fees from them.
class SpaceEarning {
  SpaceEarning.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      title = j['title'] as String,
      held = _i(j['held']),
      fees = _d(j['fees']);

  final String id, title;
  final int held;
  final double fees;
}

/// [held], [noShows] and [feesEarned]: confirmed stalls dated in the period (fees of the held ones only).
/// [upcoming] and [feesExpected]: confirmed stalls still to come. [rating]: farmers' stars, all time.
class HostSummary {
  HostSummary.fromJson(Map<String, dynamic> j)
    : days = _i(j['days']),
      held = _i(j['held']),
      noShows = _i(j['noShows']),
      feesEarned = _d(j['feesEarned']),
      upcoming = _i(j['upcoming']),
      feesExpected = _d(j['feesExpected']),
      requests = _i(j['requests']),
      accepted = _i(j['accepted']),
      declined = _i(j['declined']),
      rating = _dOrNull(j['rating']),
      ratingCount = _i(j['ratingCount']),
      spaces = [for (final s in j['spaces'] as List) SpaceEarning.fromJson(s as Map<String, dynamic>)];

  final int days, held, noShows, upcoming, requests, accepted, declined, ratingCount;
  final double feesEarned, feesExpected;
  final double? rating;
  final List<SpaceEarning> spaces;
}

/// [trips]: selling days planned in the period. [crops] (codes) and [places] (space titles): by held stalls.
class FarmerSummary {
  FarmerSummary.fromJson(Map<String, dynamic> j)
    : days = _i(j['days']),
      trips = _i(j['trips']),
      held = _i(j['held']),
      noShows = _i(j['noShows']),
      feesPaid = _d(j['feesPaid']),
      upcoming = _i(j['upcoming']),
      rating = _dOrNull(j['rating']),
      ratingCount = _i(j['ratingCount']),
      crops = [for (final t in j['crops'] as List) TopItem.fromJson(t as Map<String, dynamic>)],
      places = [for (final t in j['places'] as List) TopItem.fromJson(t as Map<String, dynamic>)];

  final int days, trips, held, noShows, upcoming, ratingCount;
  final double feesPaid;
  final double? rating;
  final List<TopItem> crops, places;
}

final hostSummaryProvider = FutureProvider.autoDispose.family<HostSummary, int>((ref, days) async {
  final res = await ref.watch(dioProvider).get('/hosts/me/summary', queryParameters: {'days': days});
  return HostSummary.fromJson(res.data as Map<String, dynamic>);
});

final farmerSummaryProvider = FutureProvider.autoDispose.family<FarmerSummary, int>((ref, days) async {
  final res = await ref.watch(dioProvider).get('/farmers/me/summary', queryParameters: {'days': days});
  return FarmerSummary.fromJson(res.data as Map<String, dynamic>);
});
