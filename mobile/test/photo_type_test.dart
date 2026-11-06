import 'package:aangan_mandi/core/api/app_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('jpeg, png and webp are recognised from their bytes, whatever the picker called them', () {
    expect(photoSubtype([0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10]), 'jpeg');
    expect(photoSubtype([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0x0D]), 'png');
    expect(photoSubtype([...'RIFF'.codeUnits, 0x24, 0, 0, 0, ...'WEBP'.codeUnits]), 'webp');
  });

  test('other formats and short files get no image type', () {
    expect(photoSubtype([0, 0, 0, 0x1C, ...'ftypavif'.codeUnits]), isNull);
    expect(photoSubtype([0, 0, 0, 0x18, ...'ftypheic'.codeUnits]), isNull);
    expect(photoSubtype('GIF89a'.codeUnits), isNull);
    expect(photoSubtype([]), isNull);
    expect(photoSubtype([0xFF, 0xD8]), isNull);
    expect(photoSubtype('RIFF'.codeUnits), isNull);
  });
}
