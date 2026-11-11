import 'package:aangan_mandi/core/api/app_api.dart';
import 'package:aangan_mandi/core/api/models.dart';
import 'package:aangan_mandi/core/api/trip_api.dart';
import 'package:aangan_mandi/core/storage/prefs.dart';
import 'package:aangan_mandi/features/farmer/farmer_home.dart';
import 'package:aangan_mandi/features/host/space_detail_screen.dart';
import 'package:aangan_mandi/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The real notifier reads the saved language from device storage, which tests do not open.
class _English extends LocaleNotifier {
  @override
  String build() => 'en';
}

/// Serves one space and records deletes instead of calling the API.
class _FakeHostApi extends HostApi {
  _FakeHostApi() : super(Dio());
  final deleted = <String>[];

  @override
  Future<Space> get(String id) async => Space.fromJson({
        'id': id,
        'title': 'Green villa courtyard',
        'type': 'Courtyard',
        'address': '1 Road',
        'locality': 'Ameerpet',
        'areaSqFt': 1089,
        'isFree': true,
        'fee': 0,
        'availableDays': ['Saturday'],
        'openFrom': '16:00:00',
        'openTo': '20:00:00',
        'status': 'Live',
        'rejectionReason': null,
        'photoUrls': <String>[],
        'hasProof': false,
        'photos': <Object>[],
        'proof': null,
      });

  @override
  Future<int> deleteSpace(String spaceId) async {
    deleted.add(spaceId);
    return 1;
  }
}

/// Records resets instead of calling the API.
class _FakeFarmerApi extends FarmerApi {
  _FakeFarmerApi() : super(Dio());
  var resets = 0;

  @override
  Future<bool> resetVerification() async {
    resets++;
    return true;
  }
}

Farmer _farmer(String status) => Farmer.fromJson({
      'name': 'Ramesh Reddy',
      'village': 'Nelakondapalli',
      'district': 'Medak',
      'cropCodes': ['BANANA'],
      'farmSizeAcres': 2.5,
      'produceSource': 'OwnFarm',
      'evidenceType': 'LandRecord',
      'evidenceDetails': null,
      'hasEvidencePhoto': false,
      'evidencePhotoAt': null,
      'status': status,
      'level': 1,
      'rejectionReason': status == 'Rejected' ? 'Photo is blurred' : null,
      'missing': <String>[],
    });

Widget _app(List overrides, Widget home) => ProviderScope(
      overrides: [localeProvider.overrideWith(_English.new), cropsProvider.overrideWith((ref) async => []), ...overrides.cast()],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

void main() {
  testWidgets('host deletes a space after confirming, and returns to the list', (tester) async {
    final api = _FakeHostApi();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(_app(
      [hostApiProvider.overrideWithValue(api)],
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpaceDetailScreen(id: 's1'))),
            child: const Text('My spaces'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('My spaces'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete space'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this space?'), findsOneWidget);
    expect(find.textContaining('each farmer is told'), findsOneWidget);

    // Cancel keeps it.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(api.deleted, isEmpty);

    await tester.tap(find.byTooltip('Delete space'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(api.deleted, ['s1']);
    expect(find.byType(SpaceDetailScreen), findsNothing);
    expect(find.text('Space deleted. 1 booking was cancelled.'), findsOneWidget);
  });

  testWidgets('a waiting farmer can clear verification, and is told it leaves the queue', (tester) async {
    final api = _FakeFarmerApi();
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    await tester.pumpWidget(_app([
      farmerApiProvider.overrideWithValue(api),
      farmerProvider.overrideWith((ref) async => _farmer('Pending')),
    ], const Scaffold(body: FarmerHome())));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Clear and start over'));
    await tester.tap(find.text('Clear and start over'));
    await tester.pumpAndSettle();
    expect(find.text('Clear your verification?'), findsOneWidget);
    expect(find.textContaining('takes it out of the queue'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(api.resets, 1);
    expect(find.text('Verification cleared. You can start again.'), findsOneWidget);
  });

  testWidgets('a verified farmer has nothing to clear', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    await tester.pumpWidget(_app([
      farmerProvider.overrideWith((ref) async => _farmer('Verified')),
      tripsProvider.overrideWith((ref) async => []),
    ], const Scaffold(body: FarmerHome())));
    await tester.pumpAndSettle();
    expect(find.text('Clear and start over'), findsNothing);
  });
}
