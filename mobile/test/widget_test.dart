import 'package:aangan_mandi/features/onboarding/language_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offers English, Telugu and Hindi with English first', () {
    expect(LanguageScreen.languages.keys, ['en', 'te', 'hi']);
  });
}
