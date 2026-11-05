import 'api/models.dart';

/// A crop the farmer added that is not in the master list travels as `custom:<name>` (name as typed, any language).
const customCropPrefix = 'custom:';

bool isCustomCrop(String code) => code.startsWith(customCropPrefix);

String customCropCode(String name) => '$customCropPrefix${name.trim().replaceAll(RegExp(r'\s+'), ' ')}';

/// 2–30 letters (any script), spaces, dots, apostrophes, hyphens — the same rule as the API.
final customCropNamePattern = RegExp(r"^[\p{L}\p{M}][\p{L}\p{M} .'\-]{1,29}$", unicode: true);

/// The crop's name in [lang]; a farmer-added crop shows as typed; an unknown code shows as is.
String cropName(String code, List<Crop> crops, String lang) {
  if (isCustomCrop(code)) return code.substring(customCropPrefix.length);
  return crops.where((c) => c.code == code).firstOrNull?.name(lang) ?? code;
}
