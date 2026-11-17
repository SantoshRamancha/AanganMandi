import 'dart:io';

import 'package:aangan_mandi/core/api/api_client.dart';
import 'package:aangan_mandi/core/api/app_api.dart';
import 'package:aangan_mandi/core/api/models.dart';
import 'package:aangan_mandi/core/api/support_api.dart';
import 'package:aangan_mandi/core/storage/prefs.dart';
import 'package:aangan_mandi/core/widgets/feedback.dart';
import 'package:aangan_mandi/features/onboarding/consent_screen.dart';
import 'package:aangan_mandi/features/support/report_problem.dart';
import 'package:aangan_mandi/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The real notifier reads the saved language from device storage, which tests do not open.
class _English extends LocaleNotifier {
  @override
  String build() => 'en';
}

class _FakeReportsApi extends ReportsApi {
  _FakeReportsApi() : super(Dio());
  final sent = <(String, String, String?)>[];

  @override
  Future<void> report({required String category, required String message, String? bookingId}) async =>
      sent.add((category, message, bookingId));
}

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi() : super(Dio());
  final accepted = <String>[];

  @override
  Future<void> acceptTerms(String version) async => accepted.add(version);
}

Profile _profile() => Profile.fromJson({
  'name': 'Ramesh',
  'phone': '+919000000001',
  'email': null,
  'language': 'en',
  'roles': ['Farmer'],
  'memberSince': '2026-11-01T10:00:00Z',
  'termsAccepted': false,
  'termsVersion': '2026-11-17',
});

void main() {
  // The consent screen reads the saved role to know where to go next.
  setUpAll(() async => Prefs.initAt((await Directory.systemTemp.createTemp('prefs')).path));

  testWidgets('a report needs a category and a real description, then is sent with its booking', (tester) async {
    final api = _FakeReportsApi();
    await tester.binding.setSurfaceSize(const Size(420, 1200));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localeProvider.overrideWith(_English.new), reportsApiProvider.overrideWithValue(api)],
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          scaffoldMessengerKey: rootMessengerKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showReportProblemSheet(context, bookingId: 'b1'),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    FilledButton send() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send report'));
    expect(send().onPressed, isNull);
    await tester.tap(find.text('Someone did not come'));
    await tester.enterText(find.byType(TextField), 'short');
    await tester.pump();
    expect(send().onPressed, isNull); // under 10 characters
    await tester.enterText(find.byType(TextField), 'The farmer never came to my gate.');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Send report'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(api.sent, [('NoShow', 'The farmer never came to my gate.', 'b1')]);
    expect(find.text('Report sent. We will get back to you.'), findsOneWidget);
  });

  testWidgets('consent needs the tick box, then records the server\'s version and goes on', (tester) async {
    final auth = _FakeAuthApi();
    final router = GoRouter(
      initialLocation: '/consent',
      routes: [
        GoRoute(path: '/consent', builder: (_, _) => const ConsentScreen()),
        GoRoute(path: '/role', builder: (_, _) => const Text('ROLE SCREEN')),
        GoRoute(path: '/home', builder: (_, _) => const Text('HOME SCREEN')),
      ],
    );
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeProvider.overrideWith(_English.new),
          authApiProvider.overrideWithValue(auth),
          profileProvider.overrideWith((ref) async => _profile()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Before you start'), findsOneWidget);
    expect(find.text('Terms of use'), findsOneWidget);
    expect(find.text('Privacy policy'), findsOneWidget);
    FilledButton agree() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Agree and continue'));
    expect(agree().onPressed, isNull);

    await tester.tap(find.textContaining('I have read and agree'));
    await tester.pump();
    await tester.tap(find.text('Agree and continue'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(auth.accepted, ['2026-11-17']);
    expect(find.text('ROLE SCREEN'), findsOneWidget); // no role saved yet in tests
  });
}
