import 'package:aangan_mandi/core/api/app_api.dart';
import 'package:aangan_mandi/core/api/rating_api.dart';
import 'package:aangan_mandi/core/api/trip_api.dart';
import 'package:aangan_mandi/core/api/trip_models.dart';
import 'package:aangan_mandi/core/storage/prefs.dart';
import 'package:aangan_mandi/features/host/host_bookings_screen.dart';
import 'package:aangan_mandi/features/ratings/ratings.dart';
import 'package:aangan_mandi/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// The real notifier reads the saved language from device storage, which tests do not open.
class _English extends LocaleNotifier {
  @override
  String build() => 'en';
}

class _FakeRatingApi extends RatingApi {
  _FakeRatingApi() : super(Dio());
  final sent = <(String, int, String?)>[];

  @override
  Future<void> rate(String bookingId, int stars, String? comment) async => sent.add((bookingId, stars, comment));
}

HostBooking _past({bool canRate = true, int? myStars, int noShows = 1}) => HostBooking.fromJson({
  'id': 'hb9',
  'status': 'Accepted',
  'date': DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1))),
  'from': '16:00:00',
  'to': '20:00:00',
  'fee': 0,
  'message': null,
  'reason': null,
  'slotTaken': false,
  'cancelledBy': null,
  'spaceId': 's1',
  'spaceTitle': 'Green villa courtyard',
  'vehicle': 'Auto',
  'produce': [
    {'cropCode': 'custom:Tomato', 'quantityKg': 50, 'pricePerKg': 30},
  ],
  'farmer': {
    'name': 'Ramesh Reddy',
    'village': 'Nelakondapalli',
    'district': 'Medak',
    'phone': '+919000000001',
    'rating': 4.5,
    'ratingCount': 2,
    'recentNoShows': noShows,
    'completedStalls': 3,
  },
  'requestedAt': '2026-11-03T10:00:00Z',
  'arrivedAt': null,
  'noShow': false,
  'canMarkNoShow': false,
  'canRate': canRate,
  'myStars': myStars,
});

Future<void> _pump(WidgetTester tester, HostBooking b, _FakeRatingApi api) async {
  await tester.binding.setSurfaceSize(const Size(420, 1400));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith(_English.new),
        cropsProvider.overrideWith((ref) async => []),
        ratingApiProvider.overrideWithValue(api),
        hostBookingsProvider.overrideWith((ref, view) async => view == 'past' ? [b] : <HostBooking>[]),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: HostBookingsScreen(initialTab: 2)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a host sees the farmer record and rates the farmer after the stall', (tester) async {
    final api = _FakeRatingApi();
    await _pump(tester, _past(), api);

    expect(find.text('4.5'), findsOneWidget);
    expect(find.text(' · 2 ratings'), findsOneWidget);
    expect(find.text('3 stalls done'), findsOneWidget);
    expect(find.text('1 no-show in 90 days'), findsOneWidget);

    await tester.tap(find.text('Rate the farmer'));
    await tester.pumpAndSettle();
    expect(find.text('How was Ramesh Reddy at your space?'), findsOneWidget);
    // Nothing to send until stars are chosen.
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send rating')).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('star4')));
    await tester.enterText(find.byType(TextField), '  On time, polite  ');
    await tester.pump();
    await tester.tap(find.text('Send rating'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(api.sent, [('hb9', 4, 'On time, polite')]);
    expect(find.text('Thanks for rating'), findsOneWidget);
  });

  testWidgets('once rated the stars are shown instead of the button, and no no-show line when there are none', (
    tester,
  ) async {
    await _pump(tester, _past(canRate: false, myStars: 3, noShows: 0), _FakeRatingApi());
    expect(find.text('Rate the farmer'), findsNothing);
    expect(find.text('You rated'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(1 + 3)); // the average's star + three given
    expect(find.textContaining('no-show'), findsNothing);
  });

  testWidgets('a space nobody rated yet says so', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: StarsLabel(Stars(null, 0))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('New, no ratings yet'), findsOneWidget);
  });
}
