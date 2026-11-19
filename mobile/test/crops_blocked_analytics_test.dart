import 'package:aangan_mandi/core/api/analytics_api.dart';
import 'package:aangan_mandi/core/api/app_api.dart';
import 'package:aangan_mandi/core/api/models.dart';
import 'package:aangan_mandi/core/api/trip_api.dart';
import 'package:aangan_mandi/core/api/trip_models.dart';
import 'package:aangan_mandi/core/storage/prefs.dart';
import 'package:aangan_mandi/features/buyer/buyer_home.dart';
import 'package:aangan_mandi/features/host/blocked_dates.dart';
import 'package:aangan_mandi/features/ops/analytics_page.dart';
import 'package:aangan_mandi/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _English extends LocaleNotifier {
  @override
  String build() => 'en';
}

final _crops = [
  Crop.fromJson({'code': 'TOMATO', 'nameEn': 'Tomato', 'nameTe': 'టమాట', 'nameHi': 'टमाटर', 'category': 'Vegetable'}),
  Crop.fromJson({'code': 'ONION', 'nameEn': 'Onion', 'nameTe': 'ఉల్లిపాయ', 'nameHi': 'प्याज', 'category': 'Vegetable'}),
];

class _FakeBuyerApi extends BuyerApi {
  _FakeBuyerApi() : super(Dio());
  final saved = <List<String>>[];

  @override
  Future<BuyerSettings> saveCrops(List<String> crops) async {
    saved.add(crops);
    return BuyerSettings.fromJson({'area': null, 'hasEmail': true});
  }
}

class _FakeHostApi extends HostApi {
  _FakeHostApi() : super(Dio());
  final blocked = <(DateTime, String?)>[];
  final opened = <DateTime>[];

  @override
  Future<int> blockDate(String spaceId, DateTime date, String? note) async {
    blocked.add((date, note));
    return 1;
  }

  @override
  Future<void> unblockDate(String spaceId, DateTime date) async => opened.add(date);
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
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _area(List<String> crops) => {
  'area': {'latitude': 17.44, 'longitude': 78.39, 'radiusKm': 2, 'alertsOn': true, 'crops': crops},
  'hasEmail': true,
};

NearbyStall _stall({List<String> matched = const ['custom:Tomato']}) => NearbyStall.fromJson({
  'bookingId': 'b1',
  'date': DateTime.now().toIso8601String().substring(0, 10),
  'from': '16:00:00',
  'to': '20:00:00',
  'sellingNow': false,
  'farmerName': 'Ramesh Reddy',
  'village': 'Nelakondapalli',
  'produce': [
    {'cropCode': 'ONION', 'quantityKg': 40, 'pricePerKg': null},
    {'cropCode': 'custom:Tomato', 'quantityKg': 50, 'pricePerKg': 30},
  ],
  'spaceTitle': 'Green villa courtyard',
  'locality': 'Madhapur',
  'address': null,
  'latitude': null,
  'longitude': null,
  'distanceKm': 1.2,
  'matched': matched,
});

void main() {
  group('Buyer crop search', () {
    testWidgets('shows the crops looked for, marks the matching produce, and removes a crop', (tester) async {
      final api = _FakeBuyerApi();
      await _pump(tester, const BuyerHome(), [
        buyerApiProvider.overrideWithValue(api),
        buyerSettingsProvider.overrideWith((ref) async => BuyerSettings.fromJson(_area(['TOMATO']))),
        nearbyStallsProvider.overrideWith((ref) async => [_stall()]),
      ]);

      expect(find.text('Looking for'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'Tomato'), findsOneWidget);
      // The typed-in "Tomato" the farmer brings is marked; their onions are not.
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.eco_outlined), findsOneWidget);

      await tester.tap(find.descendant(of: find.byType(InputChip), matching: find.byTooltip('Remove')));
      await tester.pumpAndSettle();
      expect(api.saved, [<String>[]]);
    });

    testWidgets('chooses more crops in the sheet', (tester) async {
      final api = _FakeBuyerApi();
      await _pump(tester, const BuyerHome(), [
        buyerApiProvider.overrideWithValue(api),
        buyerSettingsProvider.overrideWith((ref) async => BuyerSettings.fromJson(_area(['TOMATO']))),
        nearbyStallsProvider.overrideWith((ref) async => <NearbyStall>[]),
      ]);
      expect(find.textContaining('No farmer nearby is selling these crops'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('chooseCrops')));
      await tester.pumpAndSettle();
      expect(find.text('Which crops are you looking for?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'Onion'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show farmers with these 2 crops'));
      await tester.pumpAndSettle();
      expect(api.saved, [
        ['TOMATO', 'ONION'],
      ]);
    });

    testWidgets('with no crops chosen everyone is listed', (tester) async {
      await _pump(tester, const BuyerHome(), [
        buyerSettingsProvider.overrideWith((ref) async => BuyerSettings.fromJson(_area([]))),
        nearbyStallsProvider.overrideWith((ref) async => [_stall(matched: const [])]),
      ]);
      expect(find.textContaining('All crops.'), findsOneWidget);
      expect(find.text('Choose crops'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });
  });

  group('Host blocked days', () {
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
    final tomorrow = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));

    testWidgets('lists blocked days and opens one again', (tester) async {
      final api = _FakeHostApi();
      await _pump(tester, SingleChildScrollView(child: BlockedDatesSection(space: space)), [
        hostApiProvider.overrideWithValue(api),
        blockedDatesProvider.overrideWith(
          (ref, id) async => [
            BlockedDate.fromJson({'date': tomorrow.toIso8601String().substring(0, 10), 'note': 'Wedding at home'}),
          ],
        ),
      ]);
      expect(find.text('Days you are closed'), findsOneWidget);
      expect(find.text('Wedding at home'), findsOneWidget);

      await tester.tap(find.byTooltip('Open this day again'));
      await tester.pumpAndSettle();
      expect(api.opened, [tomorrow]);
      expect(find.text('Day open again'), findsOneWidget);
    });

    testWidgets('blocks a day with a note and says how many requests were declined', (tester) async {
      final api = _FakeHostApi();
      await _pump(tester, SingleChildScrollView(child: BlockedDatesSection(space: space)), [
        hostApiProvider.overrideWithValue(api),
        blockedDatesProvider.overrideWith((ref, id) async => <BlockedDate>[]),
      ]);
      expect(find.text('No days blocked'), findsOneWidget);

      await tester.tap(find.text('Block a day'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK')); // today, the first open day
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), ' Family function ');
      await tester.tap(find.widgetWithText(FilledButton, 'Block a day'));
      await tester.pumpAndSettle();

      expect(api.blocked, [(DateUtils.dateOnly(DateTime.now()), 'Family function')]);
      expect(find.text('Day blocked, 1 request declined'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Analytics shows the figures for the chosen period', (tester) async {
    final asked = <int>[];
    Map<String, dynamic> json(int days) => {
      'days': days,
      'from': '2026-11-13',
      'to': '2026-11-19',
      'people': {
        'users': 120,
        'newUsers': 9,
        'farmers': 40,
        'verifiedFarmers': 31,
        'farmersWaiting': 4,
        'hosts': 22,
        'buyers': 58,
        'buyersWithArea': 41,
        'spacesLive': 17,
        'spacesWaiting': 2,
      },
      'requests': {'made': 12, 'waiting': 2, 'accepted': 6, 'declined': 3, 'cancelled': 1, 'acceptanceRate': 67},
      'stalls': {'confirmed': 4, 'held': 3, 'noShows': 1, 'showRate': 75, 'hostFees': 1500},
      'ratings': {'given': 5, 'spaceAverage': 4.4, 'farmerAverage': null},
      'reports': {'opened': 2, 'resolved': 1, 'openNow': 1},
      'daily': [
        for (var i = 13; i <= 19; i++) {'date': '2026-11-$i', 'requests': i % 3, 'stalls': i % 2, 'held': i % 2},
      ],
      'topCrops': [
        {'key': 'TOMATO', 'stalls': 3},
        {'key': 'custom:Drumstick', 'stalls': 1},
      ],
      'topAreas': [
        {'key': 'Madhapur', 'stalls': 4},
      ],
    };
    await _pump(tester, const AnalyticsPage(), [
      analyticsProvider.overrideWith((ref, days) async {
        asked.add(days);
        return Analytics.fromJson(json(days));
      }),
    ]);

    expect(asked, [30]);
    expect(find.text('67%'), findsOneWidget);
    expect(find.text('3 / 4'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('6 accepted · 3 declined · 2 waiting'), findsOneWidget);
    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('Drumstick'), findsOneWidget);
    expect(find.text('Madhapur'), findsOneWidget);
    expect(find.text('4 stalls'), findsOneWidget);
    expect(find.text('★ 4.4'), findsOneWidget);
    expect(find.text('–'), findsOneWidget); // no farmer ratings yet

    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();
    expect(asked, [30, 7]);
    expect(tester.takeException(), isNull);
  });
}
