import 'package:aangan_mandi/core/api/app_api.dart';
import 'package:aangan_mandi/core/api/models.dart';
import 'package:aangan_mandi/core/storage/prefs.dart';
import 'package:aangan_mandi/core/widgets/feedback.dart';
import 'package:aangan_mandi/features/profile/profile_screen.dart';
import 'package:aangan_mandi/features/trips/trip_widgets.dart';
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

/// The real notifier reads the saved theme from device storage too.
class _SystemTheme extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.system;
}

/// A screen with one button that runs [action] through runWithToast, inside an app wired like the real one
/// (root navigator and messenger keys).
Widget _app(Future<void> Function() action, {String? success}) => ProviderScope(
      overrides: [localeProvider.overrideWith(_English.new)],
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        scaffoldMessengerKey: rootMessengerKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => runWithToast(context, action, success: success),
              child: const Text('Go'),
            ),
          ),
        ),
      ),
    );

DioException _dioError({DioExceptionType type = DioExceptionType.badResponse, int? status, String? title}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status, data: {'status': status, 'title': ?title}),
  );
}

Profile _profile(List<String> roles) => Profile.fromJson({
      'name': 'Anjali Sharma',
      'phone': '+919000000003',
      'email': null,
      'language': 'en',
      'roles': roles,
      'memberSince': '2026-11-01T10:00:00',
    });

void main() {
  testWidgets('no internet shows an error pop-up that is closed with OK', (tester) async {
    await tester.pumpWidget(_app(() async => throw _dioError(type: DioExceptionType.connectionError)));
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text("That didn't work"), findsOneWidget);
    expect(find.textContaining("Can't reach Aangan Mandi"), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets("the server's reason is shown, but not the details of a server crash", (tester) async {
    await tester.pumpWidget(_app(() async => throw _dioError(status: 429, title: 'Please wait 30 seconds before asking for a new OTP')));
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(find.text('Please wait 30 seconds before asking for a new OTP'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_app(() async => throw _dioError(status: 500, title: 'NullReferenceException at Foo')));
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Something went wrong on our side'), findsOneWidget);
    expect(find.textContaining('NullReference'), findsNothing);
  });

  testWidgets('success shows a green card with a check mark', (tester) async {
    await tester.pumpWidget(_app(() async {}, success: 'Saved'));
    await tester.tap(find.text('Go'));
    await tester.pump();
    expect(find.text('Saved'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  Future<void> pumpProfile(WidgetTester tester, List<String> roles) async {
    await tester.binding.setSurfaceSize(const Size(420, 2000));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        localeProvider.overrideWith(_English.new),
        themeModeProvider.overrideWith(_SystemTheme.new),
        profileProvider.overrideWith((ref) async => _profile(roles)),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('deleting an account needs the tick box first', (tester) async {
    await pumpProfile(tester, ['Buyer']);
    await tester.ensureVisible(find.text('Delete my account'));
    await tester.tap(find.text('Delete my account'));
    await tester.pumpAndSettle();

    expect(find.text('Delete your account?'), findsOneWidget);
    FilledButton button() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Delete my account'));
    expect(button().onPressed, isNull);
    await tester.tap(find.text('I understand this cannot be undone'));
    await tester.pump();
    expect(button().onPressed, isNotNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('staff accounts have no delete option', (tester) async {
    await pumpProfile(tester, ['Verifier']);
    expect(find.text('Delete my account'), findsNothing);
  });
}
