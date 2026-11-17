import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'api_dates.dart';

/// What a problem report is about (API names).
const reportCategories = ['NoShow', 'SpaceProblem', 'PaymentDispute', 'Behaviour', 'AppProblem', 'Other'];

/// A problem report, as its reporter sees it (or, with the reporter fields, as an admin sees it).
class ProblemReport {
  ProblemReport.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      category = j['category'] as String,
      message = j['message'] as String,
      status = j['status'] as String,
      resolution = j['resolution'] as String?,
      createdAt = apiInstant(j['createdAt'])!,
      resolvedAt = apiInstant(j['resolvedAt']),
      bookingId = j['bookingId'] as String?,
      spaceTitle = j['spaceTitle'] as String?,
      bookingDate = j['bookingDate'] == null ? null : DateTime.parse(j['bookingDate'] as String),
      reporterName = j['reporterName'] as String?,
      reporterPhone = j['reporterPhone'] as String?,
      reporterRoles = [for (final r in (j['reporterRoles'] as List?) ?? const []) r as String],
      farmerName = j['farmerName'] as String?,
      hostName = j['hostName'] as String?;

  final String id, category, message, status;
  final String? resolution, bookingId, spaceTitle, reporterName, reporterPhone, farmerName, hostName;
  final DateTime createdAt;
  final DateTime? resolvedAt, bookingDate;
  final List<String> reporterRoles;

  bool get isOpen => status == 'Open';
}

/// "Report a problem" for any signed-in user, and the user's own reports.
class ReportsApi {
  ReportsApi(this._dio);
  final Dio _dio;

  /// [bookingId] when reported from a booking (the user must be its farmer or host).
  Future<void> report({required String category, required String message, String? bookingId}) =>
      _dio.post('/reports', data: {'category': category, 'message': message, 'bookingId': bookingId});

  Future<List<ProblemReport>> mine() async => [
    for (final j in (await _dio.get('/reports/mine')).data as List) ProblemReport.fromJson(j as Map<String, dynamic>),
  ];
}

/// Admins: open and resolved reports, and resolving one with a note the reporter sees.
class OpsReportsApi {
  OpsReportsApi(this._dio);
  final Dio _dio;

  /// status: Open or Resolved.
  Future<List<ProblemReport>> list(String status) async => [
    for (final j in (await _dio.get('/ops/reports', queryParameters: {'status': status})).data as List)
      ProblemReport.fromJson(j as Map<String, dynamic>),
  ];

  Future<void> resolve(String id, String resolution) =>
      _dio.post('/ops/reports/$id/resolve', data: {'resolution': resolution});
}

final reportsApiProvider = Provider((ref) => ReportsApi(ref.watch(dioProvider)));
final opsReportsApiProvider = Provider((ref) => OpsReportsApi(ref.watch(dioProvider)));

final myReportsProvider = FutureProvider.autoDispose<List<ProblemReport>>(
  (ref) => ref.watch(reportsApiProvider).mine(),
);

/// Keyed by status: Open or Resolved.
final opsReportsProvider = FutureProvider.autoDispose.family<List<ProblemReport>, String>(
  (ref, status) => ref.watch(opsReportsApiProvider).list(status),
);
