import 'package:geolocator/geolocator.dart';

/// Current GPS position, asking for permission if needed.
/// Returns null if location is off, refused, or cannot be read (the caller asks the user to allow it).
Future<Position?> currentPosition() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 30)),
    );
  } on Exception {
    // Browsers report a blocked or unavailable location as an error rather than a permission state.
    return null;
  }
}
