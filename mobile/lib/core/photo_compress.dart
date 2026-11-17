import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Upload target: small enough for a slow rural connection and for the bucket, big enough to read a document.
const targetPhotoBytes = 400 * 1024;

/// Turns [bytes] into a JPEG of at most [maxSide] px on the longer side at [quality] (1–100), without EXIF data.
typedef JpegEncoder = Future<Uint8List> Function(Uint8List bytes, {required int maxSide, required int quality});

/// The steps tried in order until the photo fits: first a light squeeze, then smaller and softer.
const compressionSteps = [(1600, 75), (1600, 60), (1280, 60), (1024, 55), (800, 50)];

/// Makes a picked photo small enough to upload: re-encodes it as JPEG, stepping down size and quality until it is
/// under [targetBytes] (or the last step is reached). Also drops EXIF data, so a photo of a land record or a
/// space never carries the phone's GPS position. A photo already a small JPEG is left as it is; one the encoder
/// cannot read (say, an unusual format) is sent unchanged and the server decides.
///
/// In a browser the picker has already re-drawn and compressed the photo, so it is passed through.
Future<Uint8List> shrinkPhoto(Uint8List bytes, {JpegEncoder? encoder, int targetBytes = targetPhotoBytes}) async {
  final encode = encoder ?? (kIsWeb ? null : _flutterImageCompress);
  if (encode == null) return bytes;
  if (bytes.length <= targetBytes && _isJpeg(bytes)) return bytes;
  try {
    var best = bytes;
    for (final (side, quality) in compressionSteps) {
      final out = await encode(bytes, maxSide: side, quality: quality);
      if (out.isEmpty) continue;
      best = out;
      if (out.length <= targetBytes) break;
    }
    return best.length < bytes.length || !_isJpeg(bytes) ? best : bytes;
  } catch (_) {
    return bytes;
  }
}

bool _isJpeg(Uint8List b) => b.length > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;

Future<Uint8List> _flutterImageCompress(Uint8List bytes, {required int maxSide, required int quality}) =>
    FlutterImageCompress.compressWithList(
      bytes,
      minWidth: maxSide,
      minHeight: maxSide,
      quality: quality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
