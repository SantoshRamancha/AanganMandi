import 'package:aangan_mandi/core/api/app_api.dart';
import 'package:aangan_mandi/core/api/trip_api.dart';
import 'package:aangan_mandi/core/api/trip_models.dart';
import 'package:aangan_mandi/core/storage/prefs.dart';
import 'package:aangan_mandi/features/host/host_bookings_screen.dart';
import 'package:aangan_mandi/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final shared = <String>[];

  @override
  Future<String> shareLink(String id) async {
    shared.add(id);
    return 'http://192.168.1.5:5080/s/7kQ2mNp4xR';
  }
}

HostBooking _booking({bool canMarkNoShow = false}) => HostBooking.fromJson({
      'id': 'hb1',
      'status': 'Accepted',
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1))),
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
      'produce': [
        {'cropCode': 'custom:Tomato', 'quantityKg': 50, 'pricePerKg': 30},
        {'cropCode': 'custom:Onion', 'quantityKg': null, 'pricePerKg': null},
      ],
      'farmer': {'name': 'Ramesh Reddy', 'village': 'Nelakondapalli', 'district': 'Medak', 'phone': '+919000000001'},
      'requestedAt': '2026-11-03T10:00:00',
      'arrivedAt': null,
      'noShow': false,
      'canMarkNoShow': canMarkNoShow,
    });

Future<void> _pump(WidgetTester tester, _FakeHostBookingApi api, HostBooking b) async {
  await tester.binding.setSurfaceSize(const Size(420, 1400));
  await tester.pumpWidget(ProviderScope(
    overrides: [
      localeProvider.overrideWith(_English.new),
      cropsProvider.overrideWith((ref) async => []),
      hostBookingApiProvider.overrideWithValue(api),
      hostBookingsProvider.overrideWith((ref, view) async => view == 'upcoming' ? [b] : <HostBooking>[]),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: HostBookingsScreen()),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Upcoming'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('host shares a confirmed stall with a ready message and the public link', (tester) async {
    final api = _FakeHostBookingApi();
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });

    await _pump(tester, api, _booking());
    await tester.tap(find.text('Share with neighbours'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(api.shared, ['hb1']);
    expect(find.text('Tell your neighbours'), findsOneWidget);
    expect(find.textContaining('Tomato ₹30/kg, Onion'), findsOneWidget);
    expect(find.textContaining('http://192.168.1.5:5080/s/7kQ2mNp4xR'), findsOneWidget);
    expect(find.text('Share on WhatsApp'), findsOneWidget);

    await tester.tap(find.text('Copy message'));
    await tester.pumpAndSettle();
    expect(copied, contains('Green villa courtyard'));
    expect(copied, contains('/s/7kQ2mNp4xR'));
    expect(find.text('Message copied'), findsOneWidget);
  });

  testWidgets('no share button once the slot is over', (tester) async {
    await _pump(tester, _FakeHostBookingApi(), _booking(canMarkNoShow: true));
    expect(find.text('Share with neighbours'), findsNothing);
  });
}
