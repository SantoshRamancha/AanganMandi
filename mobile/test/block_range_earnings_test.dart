import 'package:aangan_mandi/core/api/app_api.dart';
import 'package:aangan_mandi/core/api/models.dart';
import 'package:aangan_mandi/core/api/summary_api.dart';
import 'package:aangan_mandi/core/storage/prefs.dart';
import 'package:aangan_mandi/features/host/blocked_dates.dart';
import 'package:aangan_mandi/features/summary/summary_screens.dart';
import 'package:aangan_mandi/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

class _English extends LocaleNotifier {
  @override
  String build() => 'en';
}

final _crops = [
  Crop.fromJson({'code': 'TOMATO', 'nameEn': 'Tomato', 'nameTe': 'టమాట', 'nameHi': 'टमाटर', 'category': 'Vegetable'}),
];

class _FakeHostApi extends HostApi {
  _FakeHostApi() : super(Dio());
  final ranges = <(DateTime, DateTime, String?)>[];

  @override
  Future<BlockRangeResult> blockRange(String spaceId, DateTime from, DateTime to, String? note) async {
    ranges.add((from, to, note));
    String d(int add) => DateUtils.dateOnly(from).add(Duration(days: add)).toIso8601String().substring(0, 10);
    return BlockRangeResult.fromJson({
      'blocked': [d(1), d(2)],
      'booked': [d(0)],
      'declinedRequests': 1,
    });
  }
}

Future<void> _pump(WidgetTester tester, Widget child, List overrides) async {
  await tester.binding.setSurfaceSize(const Size(480, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith(_English.new),
        cropsProvider.overrideWith((ref) async => _crops),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('blocks several days and says which stayed open for a confirmed farmer', (tester) async {
    final space = Space.fromJson({
      'id': 's1',
      'title': 'Green villa courtyard',
      'type': 'Courtyard',
      'address': '1 Road',
      'locality': 'Ameerpet',
      'areaSqFt': 1089,
      'isFree': true,
      'fee': 0,
      'availableDays': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
      'openFrom': '16:00:00',
      'openTo': '20:00:00',
      'status': 'Live',
      'rejectionReason': null,
      'photoUrls': <String>[],
      'hasProof': false,
      'photos': <Object>[],
      'proof': null,
    });
    final api = _FakeHostApi();
    await _pump(
      tester,
      Scaffold(
        body: SingleChildScrollView(child: BlockedDatesSection(space: space)),
      ),
      [hostApiProvider.overrideWithValue(api), blockedDatesProvider.overrideWith((ref, id) async => <BlockedDate>[])],
    );

    await tester.tap(find.text('Block several days'));
    await tester.pumpAndSettle();
    // Type the dates instead of tapping the calendar, so the test does not depend on where the month ends.
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    final today = DateUtils.dateOnly(DateTime.now());
    final from = today.add(const Duration(days: 1)), to = today.add(const Duration(days: 3));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), DateFormat('MM/dd/yyyy').format(from));
    await tester.enterText(fields.at(1), DateFormat('MM/dd/yyyy').format(to));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Close from'), findsOneWidget);
    await tester.enterText(find.byType(TextField), ' Travelling ');
    await tester.tap(find.widgetWithText(FilledButton, 'Block several days'));
    await tester.pumpAndSettle();

    expect(api.ranges, [(from, to, 'Travelling')]);
    expect(find.text('2 days blocked · 1 request declined'), findsOneWidget);
    expect(find.text('Some days are still open'), findsOneWidget);
    expect(find.textContaining(DateFormat.MMMEd('en').format(from)), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Some days are still open'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a host sees their earnings and can look at a whole year', (tester) async {
    final asked = <int>[];
    await _pump(tester, const EarningsScreen(), [
      hostSummaryProvider.overrideWith((ref, days) async {
        asked.add(days);
        return HostSummary.fromJson({
          'days': days,
          'held': 3,
          'noShows': 1,
          'feesEarned': 1500,
          'upcoming': 2,
          'feesExpected': 1000,
          'requests': 7,
          'accepted': 5,
          'declined': 2,
          'rating': 4.5,
          'ratingCount': 2,
          'spaces': [
            {'id': 'a', 'title': 'Green villa courtyard', 'held': 3, 'fees': 1500},
            {'id': 'b', 'title': 'Terrace', 'held': 0, 'fees': 0},
          ],
        });
      }),
    ]);

    expect(asked, [30]);
    expect(find.text('₹1,500'), findsNWidgets(2)); // the total and the one space that earned it
    expect(find.text('₹1,000 expected'), findsOneWidget);
    expect(find.text('5 accepted · 2 declined'), findsOneWidget);
    expect(find.text('★ 4.5'), findsOneWidget);
    expect(find.text('Terrace'), findsOneWidget);

    await tester.tap(find.text('1 year'));
    await tester.pumpAndSettle();
    expect(asked, [30, 365]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a farmer sees their stalls, what sold and where', (tester) async {
    await _pump(tester, const MyStallsScreen(), [
      farmerSummaryProvider.overrideWith(
        (ref, days) async => FarmerSummary.fromJson({
          'days': days,
          'trips': 5,
          'held': 4,
          'noShows': 0,
          'feesPaid': 200.5,
          'upcoming': 1,
          'rating': null,
          'ratingCount': 0,
          'crops': [
            {'key': 'TOMATO', 'stalls': 4},
            {'key': 'custom:Drumstick', 'stalls': 1},
          ],
          'places': [
            {'key': 'Green villa courtyard', 'stalls': 4},
          ],
        }),
      ),
    ]);

    expect(find.text('₹200.50'), findsOneWidget);
    expect(find.text('–'), findsOneWidget); // not rated yet
    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('Drumstick'), findsOneWidget);
    expect(find.text('Green villa courtyard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the home cards sum up the last 30 days', (tester) async {
    await _pump(tester, const Scaffold(body: Column(children: [EarningsCard(), MyStallsCard()])), [
      hostSummaryProvider.overrideWith(
        (ref, days) async => HostSummary.fromJson({'days': days, 'held': 1, 'feesEarned': 500, 'spaces': <Object>[]}),
      ),
      farmerSummaryProvider.overrideWith(
        (ref, days) async =>
            FarmerSummary.fromJson({'days': days, 'held': 2, 'feesPaid': 0, 'crops': <Object>[], 'places': <Object>[]}),
      ),
    ]);
    expect(find.text('₹500 from 1 stall in the last 30 days'), findsOneWidget);
    expect(find.text('2 stalls held, ₹0 in fees, in the last 30 days'), findsOneWidget);
  });
}
