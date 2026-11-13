import 'package:aangan_mandi/core/api/app_api.dart';
import 'package:aangan_mandi/core/api/trip_api.dart';
import 'package:aangan_mandi/core/api/trip_models.dart';
import 'package:aangan_mandi/core/storage/prefs.dart';
import 'package:aangan_mandi/features/buyer/buyer_home.dart';
import 'package:aangan_mandi/features/host/host_bookings_screen.dart';
import 'package:aangan_mandi/features/trips/trip_detail_screen.dart';
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

class _FakeHostBookingApi extends HostBookingApi {
  _FakeHostBookingApi() : super(Dio());
  final noShows = <String>[];

  @override
  Future<void> markNoShow(String id) async => noShows.add(id);
}

final _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
final _tomorrow = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));

Map<String, dynamic> _space() => {
      'id': 's1',
      'title': 'Green villa courtyard',
      'type': 'Courtyard',
      'locality': 'Ameerpet',
      'areaSqFt': 1089,
      'maxStallSize': '10x10 ft',
      'maxVehicle': 'MiniTruck',
      'amenities': <String>[],
      'isFree': true,
      'fee': 0,
      'openFrom': '16:00:00',
      'openTo': '20:00:00',
      'rules': null,
      'photoUrls': <String>[],
    };

Trip _trip({String? arrivedAt}) => Trip.fromJson({
      'id': 't1',
      'date': _today,
      'vehicle': 'Auto',
      'preferredArea': null,
      'notes': null,
      'status': 'Planned',
      'produce': [
        {'cropCode': 'custom:Tomato', 'quantityKg': 50, 'pricePerKg': 30},
      ],
      'booking': {
        'id': 'b1',
        'status': 'Accepted',
        'date': _today,
        'from': '16:00:00',
        'to': '20:00:00',
        'fee': 0,
        'message': null,
        'reason': null,
        'slotTaken': false,
        'cancelledBy': null,
        'space': _space(),
        'host': {'name': 'Lakshmi', 'phone': '+919000000002', 'address': '1 Road, Ameerpet', 'latitude': 17.4, 'longitude': 78.4},
        'arrivedAt': arrivedAt,
        'noShow': false,
      },
    });

HostBooking _hostBooking({String? arrivedAt, bool canMarkNoShow = false}) => HostBooking.fromJson({
      'id': 'hb1',
      'status': 'Accepted',
      'date': _today,
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
      'produce': <Object>[],
      'farmer': {'name': 'Ramesh Reddy', 'village': 'Nelakondapalli', 'district': 'Medak', 'phone': '+919000000001'},
      'requestedAt': '2026-11-03T10:00:00',
      'arrivedAt': arrivedAt,
      'noShow': false,
      'canMarkNoShow': canMarkNoShow,
    });

NearbyStall _stall({required bool sellingNow, required String date}) => NearbyStall.fromJson({
      'bookingId': sellingNow ? 'n1' : 'n2',
      'date': date,
      'from': '16:00:00',
      'to': '20:00:00',
      'sellingNow': sellingNow,
      'farmerName': sellingNow ? 'Ramesh Reddy' : 'Sita Devi',
      'village': 'Nelakondapalli',
      'produce': [
        {'cropCode': 'custom:Tomato', 'quantityKg': null, 'pricePerKg': 30},
      ],
      'spaceTitle': 'Green villa courtyard',
      'locality': 'Ameerpet',
      'address': sellingNow ? '1 Road, Ameerpet' : null,
      'latitude': sellingNow ? 17.4 : null,
      'longitude': sellingNow ? 78.4 : null,
      'distanceKm': 1.2,
    });

Future<void> _pump(WidgetTester tester, Widget home, List overrides) async {
  await tester.binding.setSurfaceSize(const Size(420, 1400));
  await tester.pumpWidget(ProviderScope(
    overrides: [localeProvider.overrideWith(_English.new), cropsProvider.overrideWith((ref) async => []), ...overrides.cast()],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('farmer on the booking day', () {
    testWidgets('a confirmed booking for today offers "I\'ve arrived"', (tester) async {
      await _pump(tester, const TripDetailScreen(id: 't1'), [tripProvider.overrideWith((ref, id) async => _trip())]);
      expect(tester.takeException(), isNull);
      expect(find.text("I've arrived"), findsOneWidget);
      expect(find.textContaining('within 200 m'), findsOneWidget);
    });

    testWidgets('after checking in it shows the time instead of the button', (tester) async {
      await _pump(tester, const TripDetailScreen(id: 't1'),
          [tripProvider.overrideWith((ref, id) async => _trip(arrivedAt: '2026-11-12T10:35:00Z'))]);
      expect(find.text("I've arrived"), findsNothing);
      expect(find.textContaining('You checked in at'), findsOneWidget);
    });
  });

  group('host', () {
    testWidgets('sees when the farmer arrived', (tester) async {
      await _pump(tester, const Scaffold(body: HostBookingsScreen()), [
        hostBookingsProvider.overrideWith(
            (ref, view) async => view == 'upcoming' ? [_hostBooking(arrivedAt: '2026-11-12T10:35:00Z')] : <HostBooking>[]),
      ]);
      await tester.tap(find.textContaining('Upcoming'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Arrived at'), findsOneWidget);
      expect(find.text("Didn't come"), findsNothing);
    });

    testWidgets('marks a no-show after confirming', (tester) async {
      final api = _FakeHostBookingApi();
      await _pump(tester, const Scaffold(body: HostBookingsScreen()), [
        hostBookingApiProvider.overrideWithValue(api),
        hostBookingsProvider.overrideWith(
            (ref, view) async => view == 'upcoming' ? [_hostBooking(canMarkNoShow: true)] : <HostBooking>[]),
      ]);
      await tester.tap(find.textContaining('Upcoming'));
      await tester.pumpAndSettle();
      expect(find.text('Not arrived yet'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, "Didn't come"));
      await tester.pumpAndSettle();
      expect(find.text("Mark that the farmer didn't come?"), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, "Didn't come"));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(api.noShows, ['hb1']);
    });
  });

  group('buyer', () {
    testWidgets('without an area is asked for one', (tester) async {
      await _pump(tester, const Scaffold(body: BuyerHome()), [
        buyerSettingsProvider.overrideWith((ref) async => BuyerSettings.fromJson({'area': null, 'hasEmail': false})),
      ]);
      expect(tester.takeException(), isNull);
      expect(find.text('Fresh produce from farmers near you'), findsOneWidget);
      expect(find.text('Use my current location'), findsOneWidget);
      // Save waits for a location.
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save')).onPressed, isNull);
    });

    testWidgets('sees who is selling now with the place, and tomorrow by area only', (tester) async {
      await _pump(tester, const Scaffold(body: BuyerHome()), [
        buyerSettingsProvider.overrideWith((ref) async => BuyerSettings.fromJson({
              'area': {'latitude': 17.4, 'longitude': 78.4, 'radiusKm': 2, 'alertsOn': true},
              'hasEmail': true,
            })),
        nearbyStallsProvider.overrideWith(
            (ref) async => [_stall(sellingNow: true, date: _today), _stall(sellingNow: false, date: _tomorrow)]),
      ]);
      expect(tester.takeException(), isNull);
      expect(find.text('Within 2 km of your saved place'), findsOneWidget);
      expect(find.text('Selling now'), findsOneWidget);
      expect(find.text('1 Road, Ameerpet'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Exact place shows when the farmer arrives'), findsOneWidget);
      expect(find.textContaining('Add your email'), findsNothing);
    });
  });
}
