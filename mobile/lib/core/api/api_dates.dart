/// A moment from the API (always UTC, e.g. "2026-11-12T06:47:00Z") in the phone's local time, or null.
/// A value without a time zone is read as UTC too, so an older server that omits the "Z" still shows the right time.
DateTime? apiInstant(Object? v) {
  if (v is! String || v.isEmpty) return null;
  final hasZone = v.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(v);
  return DateTime.parse(hasZone ? v : '${v}Z').toLocal();
}
