import 'package:aangan_mandi/core/api/trip_api.dart';
import 'package:aangan_mandi/core/api/trip_models.dart';
import 'package:aangan_mandi/features/trips/space_search_screen.dart';
import 'package:aangan_mandi/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Records booking requests instead of calling the API.
class _FakeTripApi extends TripApi {
  _FakeTripApi() : super(Dio());
  final requests = <(String, String, String?)>[];

  @override
  Future<void> book(String id, String spaceId, String? message) async => requests.add((id, spaceId, message));
}

final _trip = Trip.fromJson({
  'id': 't1',
  'date': '2026-11-07',
  'vehicle': 'Auto',
  'preferredArea': null,
  'notes': null,
  'status': 'Planned',
  'produce': [
    {'cropCode': 'BANANA', 'quantityKg': 120, 'pricePerKg': 30},
  ],
  'booking': null,
});

final _space = SpaceCard.fromJson({
  'id': 's1',
  'title': 'Green villa courtyard',
  'type': 'Courtyard',
  'locality': 'Ameerpet',
  'areaSqFt': 1089,
  'maxStallSize': '10x10 ft',
  'maxVehicle': 'MiniTruck',
  'amenities': ['Water'],
  'isFree': false,
  'fee': 1000,
  'openFrom': '16:00:00',
  'openTo': '20:00:00',
  'rules': null,
  'photoUrls': <String>[],
});

void main() {
  testWidgets('requesting a space with a message sends it and returns to the trip', (tester) async {
    final api = _FakeTripApi();
    final router = GoRouter(initialLocation: '/trip', routes: [
      GoRoute(
        path: '/trip',
        builder: (_, _) => const Scaffold(body: Text('trip page')),
        routes: [GoRoute(path: 'spaces', builder: (_, _) => const SpaceSearchScreen(tripId: 't1'))],
      ),
    ]);
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tripApiProvider.overrideWithValue(api),
        tripProvider.overrideWith((ref, id) async => _trip),
        tripSpacesProvider.overrideWith((ref, key) async => [_space]),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    router.push('/trip/spaces');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Request this space'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Coming in an auto with bananas');
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(api.requests, [('t1', 's1', 'Coming in an auto with bananas')]);
    expect(find.text('trip page'), findsOneWidget);
  });
}
