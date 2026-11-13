/// Trips and space bookings (v1 API). Enum values travel as their C# names.
library;

/// "2026-11-07" (an API DateOnly) as a local calendar date.
DateTime _date(Object? v) => DateTime.parse(v as String);

/// "16:00:00" (an API TimeOnly) as "16:00".
String _time(Object? v) => (v as String).substring(0, 5);

/// One crop a farmer brings on a trip; quantity (kg) and price (₹/kg) are optional estimates.
class ProduceItem {
  const ProduceItem(this.cropCode, {this.quantityKg, this.pricePerKg});
  ProduceItem.fromJson(Map<String, dynamic> j)
      : cropCode = j['cropCode'] as String,
        quantityKg = (j['quantityKg'] as num?)?.toDouble(),
        pricePerKg = (j['pricePerKg'] as num?)?.toDouble();

  final String cropCode;
  final double? quantityKg, pricePerKg;

  Map<String, dynamic> toJson() => {'cropCode': cropCode, 'quantityKg': quantityKg, 'pricePerKg': pricePerKg};
}

/// A live space as a farmer sees it before booking: no exact address (FR-1.9).
class SpaceCard {
  SpaceCard.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        title = j['title'] as String,
        type = j['type'] as String,
        locality = j['locality'] as String,
        areaSqFt = j['areaSqFt'] as int,
        maxStallSize = j['maxStallSize'] as String,
        maxVehicle = j['maxVehicle'] as String,
        amenities = (j['amenities'] as List).cast<String>(),
        isFree = j['isFree'] as bool,
        fee = (j['fee'] as num).toDouble(),
        openFrom = _time(j['openFrom']),
        openTo = _time(j['openTo']),
        rules = j['rules'] as String?,
        photoUrls = (j['photoUrls'] as List).cast<String>();

  final String id, title, type, locality, maxStallSize, maxVehicle, openFrom, openTo;
  final String? rules;
  final int areaSqFt;
  final bool isFree;
  final double fee;
  final List<String> amenities, photoUrls;
}

/// The host's details, sent only once the booking is accepted.
class HostContact {
  HostContact.fromJson(Map<String, dynamic> j)
      : name = j['name'] as String?,
        phone = j['phone'] as String,
        address = j['address'] as String,
        latitude = (j['latitude'] as num).toDouble(),
        longitude = (j['longitude'] as num).toDouble();

  final String? name;
  final String phone, address;
  final double latitude, longitude;
}

/// status: Requested, Accepted, Declined or Cancelled. cancelledBy: Farmer or Host.
class Booking {
  Booking.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        status = j['status'] as String,
        date = _date(j['date']),
        from = _time(j['from']),
        to = _time(j['to']),
        fee = (j['fee'] as num).toDouble(),
        message = j['message'] as String?,
        reason = j['reason'] as String?,
        slotTaken = j['slotTaken'] as bool,
        cancelledBy = j['cancelledBy'] as String?,
        space = SpaceCard.fromJson(j['space'] as Map<String, dynamic>),
        host = j['host'] == null ? null : HostContact.fromJson(j['host'] as Map<String, dynamic>),
        arrivedAt = _instant(j['arrivedAt']),
        noShow = j['noShow'] as bool? ?? false;

  final String id, status, from, to;
  final DateTime date;
  final double fee;
  final String? message, reason, cancelledBy;
  final bool slotTaken, noShow;
  final SpaceCard space;
  final HostContact? host;

  /// When the farmer checked in at the space (local time), or null.
  final DateTime? arrivedAt;

  bool get isActive => status == 'Requested' || status == 'Accepted';

  /// A confirmed booking for today that has not been checked in yet (the server checks the time and distance).
  bool canCheckIn(DateTime now) =>
      status == 'Accepted' &&
      arrivedAt == null &&
      !noShow &&
      date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

/// A UTC timestamp from the API, in the phone's local time.
DateTime? _instant(Object? v) => v == null ? null : DateTime.parse(v as String).toLocal();

/// status: Planned, Cancelled or Completed (planned, date passed). [booking] is the latest one.
class Trip {
  Trip.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        date = _date(j['date']),
        vehicle = j['vehicle'] as String,
        preferredArea = j['preferredArea'] as String?,
        notes = j['notes'] as String?,
        status = j['status'] as String,
        produce = [for (final p in j['produce'] as List) ProduceItem.fromJson(p as Map<String, dynamic>)],
        booking = j['booking'] == null ? null : Booking.fromJson(j['booking'] as Map<String, dynamic>);

  final String id, vehicle, status;
  final DateTime date;
  final String? preferredArea, notes;
  final List<ProduceItem> produce;
  final Booking? booking;

  bool get isPlanned => status == 'Planned';

  /// A planned trip without a requested or accepted booking can look for a space.
  bool get canBook => isPlanned && !(booking?.isActive ?? false);
}

/// A booking request as the host sees it; the farmer's phone only once accepted.
class HostBooking {
  HostBooking.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        status = j['status'] as String,
        date = _date(j['date']),
        from = _time(j['from']),
        to = _time(j['to']),
        fee = (j['fee'] as num).toDouble(),
        message = j['message'] as String?,
        reason = j['reason'] as String?,
        slotTaken = j['slotTaken'] as bool,
        cancelledBy = j['cancelledBy'] as String?,
        spaceTitle = j['spaceTitle'] as String,
        vehicle = j['vehicle'] as String,
        produce = [for (final p in j['produce'] as List) ProduceItem.fromJson(p as Map<String, dynamic>)],
        farmerName = (j['farmer'] as Map)['name'] as String?,
        farmerVillage = (j['farmer'] as Map)['village'] as String?,
        farmerDistrict = (j['farmer'] as Map)['district'] as String?,
        farmerPhone = (j['farmer'] as Map)['phone'] as String?,
        arrivedAt = _instant(j['arrivedAt']),
        noShow = j['noShow'] as bool? ?? false,
        canMarkNoShow = j['canMarkNoShow'] as bool? ?? false;

  final String id, status, from, to, spaceTitle, vehicle;
  final DateTime date;
  final double fee;
  final String? message, reason, cancelledBy, farmerName, farmerVillage, farmerDistrict, farmerPhone;
  final bool slotTaken, noShow, canMarkNoShow;
  final List<ProduceItem> produce;

  /// When the farmer checked in at the space (local time), or null.
  final DateTime? arrivedAt;
}

/// A farmer selling inside the buyer's saved area. [address] and the position only while [sellingNow].
class NearbyStall {
  NearbyStall.fromJson(Map<String, dynamic> j)
      : bookingId = j['bookingId'] as String,
        date = _date(j['date']),
        from = _time(j['from']),
        to = _time(j['to']),
        sellingNow = j['sellingNow'] as bool,
        farmerName = j['farmerName'] as String?,
        village = j['village'] as String?,
        produce = [for (final p in j['produce'] as List) ProduceItem.fromJson(p as Map<String, dynamic>)],
        spaceTitle = j['spaceTitle'] as String,
        locality = j['locality'] as String,
        address = j['address'] as String?,
        latitude = (j['latitude'] as num?)?.toDouble(),
        longitude = (j['longitude'] as num?)?.toDouble(),
        distanceKm = (j['distanceKm'] as num).toDouble();

  final String bookingId, from, to, spaceTitle, locality;
  final DateTime date;
  final bool sellingNow;
  final String? farmerName, village, address;
  final List<ProduceItem> produce;
  final double? latitude, longitude;
  final double distanceKm;
}

/// The buyer's saved area; null until they set one. [hasEmail]: email alerts need an address in the profile.
class BuyerSettings {
  BuyerSettings.fromJson(Map<String, dynamic> j)
      : area = j['area'] == null ? null : BuyerArea.fromJson(j['area'] as Map<String, dynamic>),
        hasEmail = j['hasEmail'] as bool;

  final BuyerArea? area;
  final bool hasEmail;
}

class BuyerArea {
  const BuyerArea({required this.latitude, required this.longitude, required this.radiusKm, required this.alertsOn});

  BuyerArea.fromJson(Map<String, dynamic> j)
      : latitude = (j['latitude'] as num).toDouble(),
        longitude = (j['longitude'] as num).toDouble(),
        radiusKm = j['radiusKm'] as int,
        alertsOn = j['alertsOn'] as bool;

  final double latitude, longitude;
  final int radiusKm;
  final bool alertsOn;

  Map<String, dynamic> toJson() =>
      {'latitude': latitude, 'longitude': longitude, 'radiusKm': radiusKm, 'alertsOn': alertsOn};
}
