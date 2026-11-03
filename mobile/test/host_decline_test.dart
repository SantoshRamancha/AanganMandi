import 'package:aangan_mandi/core/api/app_api.dart';
import 'package:aangan_mandi/core/api/trip_api.dart';
import 'package:aangan_mandi/core/api/trip_models.dart';
import 'package:aangan_mandi/core/storage/prefs.dart';
import 'package:aangan_mandi/features/host/host_bookings_screen.dart';
import 'package:aangan_mandi/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records declines instead of calling the API.
class _FakeHostBookingApi extends HostBookingApi {
  _FakeHostBookingApi() : super(Dio());
  final declined = <(String, String)>[];

  @override
  Future<void> decline(String id, String reason) async => declined.add((id, reason));
}

final _request = HostBooking.fromJson({
  'id': 'b1',
  'status': 'Requested',
  'date': '2026-11-07',
  'from': '16:00:00',
  'to': '20:00:00',
  'fee': 1000,
  'message': 'Coming in an auto',
  'reason': null,
  'slotTaken': false,
  'cancelledBy': null,
  'spaceId': 's1',
  'spaceTitle': 'Green villa courtyard',
  'vehicle': 'Auto',
  'produce': <Object>[],
  'farmer': {'name': 'Ramesh Reddy', 'village': 'Nelakondapalli', 'district': 'Medak', 'phone': null},
  'requestedAt': '2026-11-03T10:00:00',
});

void main() {
  testWidgets('declining with a typed reason sends it and closes cleanly', (tester) async {
    final api = _FakeHostBookingApi();
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        hostBookingApiProvider.overrideWithValue(api),
        localeProvider.overrideWith(_English.new),
        cropsProvider.overrideWith((ref) async => []),
        hostBookingsProvider.overrideWith((ref, view) async => view == 'requests' ? [_request] : <HostBooking>[]),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HostBookingsScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Decline'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Family function that day');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Decline'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(api.declined, [('b1', 'Family function that day')]);
    expect(find.byType(AlertDialog), findsNothing);
  });
}

/// The real notifier reads the saved language from device storage, which tests do not open.
class _English extends LocaleNotifier {
  @override
  String build() => 'en';
}
