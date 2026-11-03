import 'package:aangan_mandi/core/api/app_api.dart';
import 'package:aangan_mandi/core/api/models.dart';
import 'package:aangan_mandi/core/api/trip_api.dart';
import 'package:aangan_mandi/core/api/trip_models.dart';
import 'package:aangan_mandi/core/storage/prefs.dart';
import 'package:aangan_mandi/features/farmer/farmer_home.dart';
import 'package:aangan_mandi/features/host/host_home.dart';
import 'package:aangan_mandi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The real notifier reads the saved language from device storage, which tests do not open.
class _English extends LocaleNotifier {
  @override
  String build() => 'en';
}

Farmer _farmer(String status) => Farmer.fromJson({
      'name': 'Ramesh Reddy',
      'village': 'Nelakondapalli',
      'district': 'Medak',
      'cropCodes': ['BANANA'],
      'farmSizeAcres': 2.5,
      'produceSource': 'OwnFarm',
      'evidenceType': 'AgriStackFarmerId',
      'evidenceDetails': '123',
      'hasEvidencePhoto': false,
      'evidencePhotoAt': null,
      'status': status,
      'level': status == 'Verified' ? 2 : 1,
      'rejectionReason': null,
      'missing': <String>[],
    });

Map<String, dynamic> _space(String status) => {
      'id': 'sp-$status',
      'title': 'Green villa courtyard',
      'type': 'Courtyard',
      'address': '1 Road',
      'locality': 'Ameerpet',
      'areaSqFt': 1089,
      'isFree': false,
      'fee': 1000,
      'availableDays': ['Saturday'],
      'openFrom': '16:00:00',
      'openTo': '20:00:00',
      'status': status,
      'rejectionReason': null,
      'photoUrls': <String>[],
      'hasProof': true,
      'photos': <Object>[],
      'proof': null,
    };

final _bookedTrip = Trip.fromJson({
  'id': 't1',
  'date': '2026-11-07',
  'vehicle': 'Auto',
  'preferredArea': 'Ameerpet',
  'notes': null,
  'status': 'Planned',
  'produce': [
    {'cropCode': 'BANANA', 'quantityKg': 120, 'pricePerKg': 30},
  ],
  'booking': {
    'id': 'b1',
    'status': 'Accepted',
    'date': '2026-11-07',
    'from': '16:00:00',
    'to': '20:00:00',
    'fee': 1000,
    'message': null,
    'reason': null,
    'slotTaken': false,
    'cancelledBy': null,
    'space': {
      'id': 's1',
      'title': 'Green villa courtyard',
      'type': 'Courtyard',
      'locality': 'Ameerpet',
      'areaSqFt': 1089,
      'maxStallSize': '10x10 ft',
      'maxVehicle': 'MiniTruck',
      'amenities': <String>[],
      'isFree': false,
      'fee': 1000,
      'openFrom': '16:00:00',
      'openTo': '20:00:00',
      'rules': null,
      'photoUrls': <String>[],
    },
    'host': {'name': 'Lakshmi', 'phone': '+919000000002', 'address': 'Ameerpet', 'latitude': 17.4, 'longitude': 78.4},
  },
});

HostBooking _hostBooking(String status) => HostBooking.fromJson({
      'id': 'hb-$status',
      'status': status,
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
      'produce': [
        {'cropCode': 'BANANA', 'quantityKg': 120, 'pricePerKg': 30},
      ],
      'farmer': {
        'name': 'Ramesh Reddy',
        'village': 'Nelakondapalli',
        'district': 'Medak',
        'phone': status == 'Accepted' ? '+919000000001' : null,
      },
      'requestedAt': '2026-11-03T10:00:00',
    });

Future<void> _pump(WidgetTester tester, Size size, Widget home, List overrides) async {
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      localeProvider.overrideWith(_English.new),
      cropsProvider.overrideWith((ref) async => []),
      ...overrides.cast(),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: home),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in const [Size(390, 844), Size(1280, 900)]) {
    testWidgets('verified farmer dashboard at ${size.width.toInt()} px', (tester) async {
      await _pump(tester, size, const FarmerHome(), [
        farmerProvider.overrideWith((ref) async => _farmer('Verified')),
        tripsProvider.overrideWith((ref) async => [_bookedTrip]),
      ]);
      expect(tester.takeException(), isNull);
      expect(find.text('Namaste, Ramesh'), findsOneWidget);
      expect(find.text('Your next trip'), findsOneWidget);
      expect(find.text('Booked at Green villa courtyard'), findsOneWidget);
      expect(find.text('Spaces booked'), findsOneWidget);
    });

    testWidgets('unverified farmer sees verification and how it works at ${size.width.toInt()} px', (tester) async {
      await _pump(tester, size, const FarmerHome(), [
        farmerProvider.overrideWith((ref) async => _farmer('NotStarted')),
      ]);
      expect(tester.takeException(), isNull);
      expect(find.text('How it works'), findsOneWidget);
      expect(find.text('Your next trip'), findsNothing);
    });

    testWidgets('host dashboard at ${size.width.toInt()} px', (tester) async {
      await _pump(tester, size, const HostHome(), [
        mySpacesProvider.overrideWith((ref) async => [Space.fromJson(_space('Live')), Space.fromJson(_space('PendingReview'))]),
        hostBookingsProvider.overrideWith((ref, view) async => switch (view) {
              'requests' => [_hostBooking('Requested')],
              'upcoming' => [_hostBooking('Accepted')],
              _ => <HostBooking>[],
            }),
        profileProvider.overrideWith((ref) async => Profile.fromJson({
              'name': 'Lakshmi Prasad',
              'phone': '+919000000002',
              'language': 'en',
              'roles': ['Host'],
              'memberSince': '2026-10-30T00:00:00',
            })),
      ]);
      expect(tester.takeException(), isNull);
      expect(find.text('Namaste, Lakshmi'), findsOneWidget);
      expect(find.text('Needs your answer'), findsOneWidget);
      expect(find.text('Next booking'), findsOneWidget);
    });
  }
}
