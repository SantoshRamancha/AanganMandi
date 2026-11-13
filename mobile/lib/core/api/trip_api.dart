import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'api_client.dart';
import 'trip_models.dart';

/// A verified farmer's trips, the space search for a trip, and booking requests.
class TripApi {
  TripApi(this._dio);
  final Dio _dio;
  static const _base = '/farmers/me/trips';

  Future<List<Trip>> list() async =>
      [for (final j in (await _dio.get(_base)).data as List) Trip.fromJson(j as Map<String, dynamic>)];

  Future<Trip> get(String id) async => Trip.fromJson((await _dio.get('$_base/$id')).data as Map<String, dynamic>);

  /// Creates a trip, or updates it when [id] is given. vehicle: TwoWheeler, Auto, MiniTruck or Tractor.
  Future<Trip> save({
    String? id,
    required DateTime date,
    required String vehicle,
    required List<ProduceItem> produce,
    String? preferredArea,
    String? notes,
  }) async {
    final body = {
      'date': DateFormat('yyyy-MM-dd', 'en').format(date),
      'vehicle': vehicle,
      'preferredArea': preferredArea,
      'notes': notes,
      'produce': [for (final p in produce) p.toJson()],
    };
    final res = id == null ? await _dio.post(_base, data: body) : await _dio.put('$_base/$id', data: body);
    return Trip.fromJson(res.data as Map<String, dynamic>);
  }

  /// Cancels the trip and its requested or accepted booking.
  Future<void> cancel(String id) => _dio.post('$_base/$id/cancel', data: {'reason': null});

  /// Live spaces with a free slot for the trip; [area] matches the locality or name.
  Future<List<SpaceCard>> spaces(String id, String? area) async => [
        for (final j in (await _dio.get('$_base/$id/spaces', queryParameters: {'area': ?area})).data as List)
          SpaceCard.fromJson(j as Map<String, dynamic>),
      ];

  Future<void> book(String id, String spaceId, String? message) =>
      _dio.post('$_base/$id/bookings', data: {'spaceId': spaceId, 'message': message});

  Future<void> cancelBooking(String tripId, String bookingId) =>
      _dio.post('$_base/$tripId/bookings/$bookingId/cancel', data: {'reason': null});

  /// "I've arrived" from the phone's position at the space; the server checks the day, the time and the distance.
  Future<void> arrive(String tripId, String bookingId, double latitude, double longitude) =>
      _dio.post('$_base/$tripId/bookings/$bookingId/arrive', data: {'latitude': latitude, 'longitude': longitude});
}

/// A buyer's saved area and the farmers selling inside it.
class BuyerApi {
  BuyerApi(this._dio);
  final Dio _dio;

  Future<BuyerSettings> me() async => BuyerSettings.fromJson((await _dio.get('/buyers/me')).data as Map<String, dynamic>);

  Future<BuyerSettings> saveArea(BuyerArea area) async =>
      BuyerSettings.fromJson((await _dio.put('/buyers/me/area', data: area.toJson())).data as Map<String, dynamic>);

  Future<void> deleteArea() => _dio.delete('/buyers/me/area');

  Future<List<NearbyStall>> nearby() async =>
      [for (final j in (await _dio.get('/buyers/me/nearby')).data as List) NearbyStall.fromJson(j as Map<String, dynamic>)];
}

/// Booking requests for the host's spaces.
class HostBookingApi {
  HostBookingApi(this._dio);
  final Dio _dio;

  /// view: requests, upcoming or past.
  Future<List<HostBooking>> list(String view) async => [
        for (final j in (await _dio.get('/hosts/me/bookings', queryParameters: {'view': view})).data as List)
          HostBooking.fromJson(j as Map<String, dynamic>),
      ];

  Future<void> accept(String id) => _dio.post('/hosts/me/bookings/$id/accept');
  Future<void> decline(String id, String reason) => _dio.post('/hosts/me/bookings/$id/decline', data: {'reason': reason});
  Future<void> cancel(String id, String reason) => _dio.post('/hosts/me/bookings/$id/cancel', data: {'reason': reason});

  /// The farmer did not come; allowed once the slot is over without a check-in.
  Future<void> markNoShow(String id) => _dio.post('/hosts/me/bookings/$id/no-show');

  /// The public stall page to share with neighbours (same link every time for a booking).
  Future<String> shareLink(String id) async =>
      ((await _dio.post('/hosts/me/bookings/$id/share')).data as Map)['url'] as String;
}

final tripApiProvider = Provider((ref) => TripApi(ref.watch(dioProvider)));
final hostBookingApiProvider = Provider((ref) => HostBookingApi(ref.watch(dioProvider)));
final buyerApiProvider = Provider((ref) => BuyerApi(ref.watch(dioProvider)));

final buyerSettingsProvider = FutureProvider.autoDispose<BuyerSettings>((ref) => ref.watch(buyerApiProvider).me());
final nearbyStallsProvider = FutureProvider.autoDispose<List<NearbyStall>>((ref) => ref.watch(buyerApiProvider).nearby());

final tripsProvider = FutureProvider.autoDispose<List<Trip>>((ref) => ref.watch(tripApiProvider).list());
final tripProvider = FutureProvider.autoDispose.family<Trip, String>((ref, id) => ref.watch(tripApiProvider).get(id));

/// Spaces for (trip id, area filter).
final tripSpacesProvider = FutureProvider.autoDispose.family<List<SpaceCard>, (String, String?)>(
    (ref, key) => ref.watch(tripApiProvider).spaces(key.$1, key.$2));

/// Keyed by view: requests, upcoming or past.
final hostBookingsProvider = FutureProvider.autoDispose
    .family<List<HostBooking>, String>((ref, view) => ref.watch(hostBookingApiProvider).list(view));
