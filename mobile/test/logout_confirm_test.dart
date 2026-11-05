import 'package:aangan_mandi/features/home/home_screen.dart';
import 'package:aangan_mandi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('log out asks first, and Cancel keeps you signed in', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: LogoutButton())),
      ),
    ));
    await tester.tap(find.byType(LogoutButton));
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(LogoutButton), findsOneWidget);
  });
}
