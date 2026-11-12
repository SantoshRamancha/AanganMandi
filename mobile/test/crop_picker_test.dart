import 'package:aangan_mandi/core/api/app_api.dart';
import 'package:aangan_mandi/core/api/models.dart';
import 'package:aangan_mandi/core/crops.dart';
import 'package:aangan_mandi/core/districts.dart';
import 'package:aangan_mandi/core/storage/prefs.dart';
import 'package:aangan_mandi/core/widgets/crop_picker.dart';
import 'package:aangan_mandi/core/widgets/initials_avatar.dart';
import 'package:aangan_mandi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The real notifier reads the saved language from device storage, which tests do not open.
class _English extends LocaleNotifier {
  @override
  String build() => 'en';
}

Crop _crop(String code, String en, String te, String cat) =>
    Crop.fromJson({'code': code, 'nameEn': en, 'nameTe': te, 'nameHi': en, 'category': cat});

final _crops = [
  _crop('TOMATO', 'Tomato', 'టమాట', 'Vegetable'),
  _crop('MANGO', 'Mango', 'మామిడి', 'Fruit'),
  _crop('METHI', 'Fenugreek leaves', 'మెంతికూర', 'Leafy'),
];

/// Holds the selection like a form would.
class _Harness extends StatefulWidget {
  const _Harness(this.selected);
  final Set<String> selected;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: CropPicker(
          selected: widget.selected,
          onChanged: (code, on) => setState(() => on ? widget.selected.add(code) : widget.selected.remove(code)),
        ),
      );
}

Future<Set<String>> _pump(WidgetTester tester) async {
  final selected = <String>{};
  await tester.binding.setSurfaceSize(const Size(500, 1000));
  await tester.pumpWidget(ProviderScope(
    overrides: [
      localeProvider.overrideWith(_English.new),
      cropsProvider.overrideWith((ref) async => _crops),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: _Harness(selected)),
    ),
  ));
  await tester.pumpAndSettle();
  return selected;
}

void main() {
  testWidgets('crops are grouped by type and can be picked', (tester) async {
    final selected = await _pump(tester);
    expect(find.text('Vegetables'), findsOneWidget);
    expect(find.text('Fruits'), findsOneWidget);
    await tester.tap(find.text('Mango'));
    await tester.pump();
    expect(selected, {'MANGO'});
  });

  testWidgets('search works in Telugu too', (tester) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField), 'మామి');
    await tester.pump();
    expect(find.widgetWithText(FilterChip, 'Mango'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Tomato'), findsNothing);
  });

  testWidgets('a crop not in the list can be added from the search', (tester) async {
    final selected = await _pump(tester);
    await tester.enterText(find.byType(TextField), 'Kakarakaya');
    await tester.pump();
    await tester.tap(find.text('Add “Kakarakaya”'));
    await tester.pumpAndSettle();
    expect(selected, {'custom:Kakarakaya'});
    expect(find.widgetWithText(FilterChip, 'Kakarakaya'), findsOneWidget);
  });

  testWidgets('a typed-in crop has an ✕ that removes it; list crops do not', (tester) async {
    final selected = await _pump(tester);
    await tester.tap(find.text('Mango'));
    await tester.enterText(find.byType(TextField), 'Kakarakaya');
    await tester.pump();
    await tester.tap(find.text('Add “Kakarakaya”'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Delete'), findsOneWidget); // only on the custom crop

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(selected, {'MANGO'});
    expect(find.widgetWithText(FilterChip, 'Kakarakaya'), findsNothing);
  });

  testWidgets('"Add another crop" asks for a valid name and closes cleanly', (tester) async {
    final selected = await _pump(tester);
    await tester.tap(find.text('Add another crop'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Crop name'), '1');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pump();
    expect(find.text('Use 2 to 30 letters'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Crop name'), 'Sweet  tamarind');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(selected, {'custom:Sweet tamarind'});
    expect(find.text('Added by you'), findsOneWidget);
  });

  test('custom crop names show as typed, master crops in the app language', () {
    expect(cropName('custom:Sweet tamarind', _crops, 'te'), 'Sweet tamarind');
    expect(cropName('TOMATO', _crops, 'te'), 'టమాట');
    expect(cropName('UNKNOWN', _crops, 'en'), 'UNKNOWN');
  });

  test('initials are the first letters of the first and last name', () {
    expect(initialsOf('Ramesh Kumar Reddy'), 'RR');
    expect(initialsOf('lakshmi'), 'L');
    expect(initialsOf('  '), isNull);
    expect(initialsOf(null), isNull);
  });

  test('all 33 Telangana districts, shown in each language', () {
    expect(telanganaDistricts, hasLength(33));
    expect(telanganaDistricts.map((d) => d.$1).toSet(), hasLength(33));
    expect(districtName('Hyderabad', 'te'), 'హైదరాబాద్');
    expect(districtName('Hyderabad', 'hi'), 'हैदराबाद');
    expect(districtName('Somewhere else', 'te'), 'Somewhere else');
  });
}
