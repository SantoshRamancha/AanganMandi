import 'package:aangan_mandi/core/api/api_client.dart';
import 'package:aangan_mandi/features/auth/otp_screen.dart';
import 'package:aangan_mandi/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Records verify calls instead of calling the API. A new user (no roles) goes to the role screen.
class _FakeAuthApi extends AuthApi {
  _FakeAuthApi() : super(Dio());
  final codes = <String>[];

  @override
  Future<List<String>> verifyOtp(String phone, String code) async {
    codes.add(code);
    return [];
  }
}

void main() {
  testWidgets('"Fill it in" verifies the test OTP exactly once', (tester) async {
    final api = _FakeAuthApi();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const OtpScreen(phone: '+919000000001', devCode: '123456')),
      GoRoute(path: '/role', builder: (_, _) => const Text('role screen')),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [authApiProvider.overrideWithValue(api)],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500)); // the OTP cursor blinks forever, so never "settles"

    expect(find.text('Test OTP: 123456'), findsOneWidget);
    await tester.tap(find.text('Fill it in'));
    await tester.pump(const Duration(milliseconds: 500)); // the OTP cursor blinks forever, so never "settles"

    expect(api.codes, ['123456']);
    expect(find.text('role screen'), findsOneWidget);
  });

  testWidgets('no banner when the server sends no test OTP (real SMS)', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const OtpScreen(phone: '+919000000001'),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500)); // the OTP cursor blinks forever, so never "settles"
    expect(find.textContaining('Test OTP'), findsNothing);
  });
}
