import 'dart:typed_data';

import 'package:aangan_mandi/core/photo_compress.dart';
import 'package:flutter_test/flutter_test.dart';

/// JPEG-looking bytes of a given size.
Uint8List _jpeg(int size) => Uint8List(size)..setAll(0, [0xFF, 0xD8, 0xFF]);

/// PNG-looking bytes of a given size.
Uint8List _png(int size) => Uint8List(size)..setAll(0, [0x89, 0x50, 0x4E, 0x47]);

void main() {
  test('a small JPEG is sent as it is', () async {
    var calls = 0;
    final small = _jpeg(100 * 1024);
    final out = await shrinkPhoto(
      small,
      encoder: (b, {required maxSide, required quality}) async {
        calls++;
        return _jpeg(10);
      },
    );
    expect(identical(out, small), isTrue);
    expect(calls, 0);
  });

  test('a big photo steps down until it fits the target', () async {
    final tried = <(int, int)>[];
    // Pretend each step makes the photo smaller: 900 KB, 600 KB, 350 KB, ...
    final sizes = [900, 600, 350, 200, 100];
    final out = await shrinkPhoto(
      _jpeg(3 * 1024 * 1024),
      encoder: (b, {required maxSide, required quality}) async {
        tried.add((maxSide, quality));
        return _jpeg(sizes[tried.length - 1] * 1024);
      },
    );
    expect(out.length, 350 * 1024);
    expect(tried, compressionSteps.take(3).toList()); // stopped at the first step under 400 KB
  });

  test('a small PNG is still turned into a JPEG', () async {
    final out = await shrinkPhoto(
      _png(50 * 1024),
      encoder: (b, {required maxSide, required quality}) async => _jpeg(30 * 1024),
    );
    expect(out.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
  });

  test('if every step is still too big, the smallest result is sent', () async {
    final out = await shrinkPhoto(
      _jpeg(5 * 1024 * 1024),
      encoder: (b, {required maxSide, required quality}) async => _jpeg((maxSide * 1024)),
    );
    expect(out.length, 800 * 1024); // the last, smallest step
  });

  test('a photo the encoder cannot read is sent unchanged', () async {
    final odd = Uint8List.fromList(List.filled(600 * 1024, 7));
    final out = await shrinkPhoto(
      odd,
      encoder: (b, {required maxSide, required quality}) async => throw Exception('bad'),
    );
    expect(identical(out, odd), isTrue);
  });
}
