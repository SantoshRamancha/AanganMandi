import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

// Admin analytics (GET /ops/analytics?days=7|30|90): figures only, no names or phone numbers.

int _i(Object? v) => (v as num?)?.toInt() ?? 0;
int? _iOrNull(Object? v) => (v as num?)?.toInt();
double? _dOrNull(Object? v) => (v as num?)?.toDouble();
Map<String, dynamic> _m(Object? v) => v as Map<String, dynamic>;

class Analytics {
  Analytics.fromJson(Map<String, dynamic> j)
    : days = _i(j['days']),
      from = DateTime.parse(j['from'] as String),
      to = DateTime.parse(j['to'] as String),
      people = PeopleNow.fromJson(_m(j['people'])),
      requests = RequestFunnel.fromJson(_m(j['requests'])),
      stalls = StallSummary.fromJson(_m(j['stalls'])),
      ratings = RatingSummary.fromJson(_m(j['ratings'])),
      reports = ReportSummary.fromJson(_m(j['reports'])),
      daily = [for (final d in j['daily'] as List) DayCount.fromJson(_m(d))],
      topCrops = [for (final t in j['topCrops'] as List) TopItem.fromJson(_m(t))],
      topAreas = [for (final t in j['topAreas'] as List) TopItem.fromJson(_m(t))];

  final int days;
  final DateTime from, to;
  final PeopleNow people;
  final RequestFunnel requests;
  final StallSummary stalls;
  final RatingSummary ratings;
  final ReportSummary reports;
  final List<DayCount> daily;

  /// Crop codes (`custom:<name>` for typed-in ones) and areas, with how many confirmed stalls had them.
  final List<TopItem> topCrops, topAreas;
}

/// Who is on Aangan Mandi now (not limited to the period), except [newUsers].
class PeopleNow {
  PeopleNow.fromJson(Map<String, dynamic> j)
    : users = _i(j['users']),
      newUsers = _i(j['newUsers']),
      farmers = _i(j['farmers']),
      verifiedFarmers = _i(j['verifiedFarmers']),
      farmersWaiting = _i(j['farmersWaiting']),
      hosts = _i(j['hosts']),
      buyers = _i(j['buyers']),
      buyersWithArea = _i(j['buyersWithArea']),
      spacesLive = _i(j['spacesLive']),
      spacesWaiting = _i(j['spacesWaiting']);

  final int users, newUsers, farmers, verifiedFarmers, farmersWaiting, hosts, buyers, buyersWithArea;
  final int spacesLive, spacesWaiting;
}

/// Requests made in the period. [acceptanceRate]: accepted out of answered, in percent (null with none answered).
class RequestFunnel {
  RequestFunnel.fromJson(Map<String, dynamic> j)
    : made = _i(j['made']),
      waiting = _i(j['waiting']),
      accepted = _i(j['accepted']),
      declined = _i(j['declined']),
      cancelled = _i(j['cancelled']),
      acceptanceRate = _iOrNull(j['acceptanceRate']);

  final int made, waiting, accepted, declined, cancelled;
  final int? acceptanceRate;
}

/// Confirmed stalls dated in the period. [showRate]: held out of those whose day is over, in percent.
class StallSummary {
  StallSummary.fromJson(Map<String, dynamic> j)
    : confirmed = _i(j['confirmed']),
      held = _i(j['held']),
      noShows = _i(j['noShows']),
      showRate = _iOrNull(j['showRate']),
      hostFees = (j['hostFees'] as num).toDouble();

  final int confirmed, held, noShows;
  final int? showRate;
  final double hostFees;
}

class RatingSummary {
  RatingSummary.fromJson(Map<String, dynamic> j)
    : given = _i(j['given']),
      spaceAverage = _dOrNull(j['spaceAverage']),
      farmerAverage = _dOrNull(j['farmerAverage']);

  final int given;
  final double? spaceAverage, farmerAverage;
}

class ReportSummary {
  ReportSummary.fromJson(Map<String, dynamic> j)
    : opened = _i(j['opened']),
      resolved = _i(j['resolved']),
      openNow = _i(j['openNow']);

  final int opened, resolved, openNow;
}

class DayCount {
  DayCount.fromJson(Map<String, dynamic> j)
    : date = DateTime.parse(j['date'] as String),
      requests = _i(j['requests']),
      stalls = _i(j['stalls']),
      held = _i(j['held']);

  final DateTime date;
  final int requests, stalls, held;
}

class TopItem {
  TopItem.fromJson(Map<String, dynamic> j) : key = j['key'] as String, stalls = _i(j['stalls']);

  final String key;
  final int stalls;
}

/// Analytics for the last [days] days (7, 30 or 90).
final analyticsProvider = FutureProvider.autoDispose.family<Analytics, int>((ref, days) async {
  final res = await ref.watch(dioProvider).get('/ops/analytics', queryParameters: {'days': days});
  return Analytics.fromJson(res.data as Map<String, dynamic>);
});
