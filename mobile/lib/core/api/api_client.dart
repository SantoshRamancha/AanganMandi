import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../router/app_router.dart';
import '../storage/prefs.dart';

/// Backend base URL. In a browser the API is on localhost; on the Android emulator
/// the host machine is 10.0.2.2. Override with: flutter run --dart-define=API_BASE_URL=https://...
const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
const apiBaseUrl = _apiBaseUrlOverride != ''
    ? _apiBaseUrlOverride
    : kIsWeb
        ? 'http://localhost:5080/api/v1'
        : 'http://10.0.2.2:5080/api/v1';

/// Scheme + host + port of the API, for absolute photo URLs the API returns as "/api/v1/files/...".
final apiOrigin = Uri.parse(apiBaseUrl).replace(path: '').toString().replaceAll(RegExp(r'/$'), '');

const _secure = FlutterSecureStorage();

class Session {
  static Future<void> save(Map<String, dynamic> tokens) async {
    await _secure.write(key: 'access_token', value: tokens['accessToken'] as String);
    await _secure.write(key: 'refresh_token', value: tokens['refreshToken'] as String);
  }

  static Future<void> clear() async {
    await _secure.delete(key: 'access_token');
    await _secure.delete(key: 'refresh_token');
    await Prefs.clearRole();
  }
}

/// Logs out locally and returns to the login screen.
Future<void> logout(Ref ref) async {
  await Session.clear();
  ref.read(routerProvider).go('/login');
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
  ));
  dio.interceptors.add(QueuedInterceptorsWrapper(
    onRequest: (options, handler) async {
      // Localised server messages, alerts and SMS follow the user's language (FR-5.1).
      options.headers['Accept-Language'] = ref.read(localeProvider);
      final token = await _secure.read(key: 'access_token');
      if (token != null && !options.path.startsWith('/auth/')) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      final isAuthCall = error.requestOptions.path.startsWith('/auth/');
      if (error.response?.statusCode != 401 || isAuthCall || error.requestOptions.extra['retried'] == true) {
        return handler.next(error);
      }
      // Access tokens last 15 minutes: rotate with the refresh token, then retry once.
      final refresh = await _secure.read(key: 'refresh_token');
      if (refresh != null) {
        try {
          final res = await Dio(BaseOptions(baseUrl: apiBaseUrl))
              .post('/auth/refresh', data: {'refreshToken': refresh});
          await Session.save(res.data as Map<String, dynamic>);
          final retry = error.requestOptions
            ..headers['Authorization'] = 'Bearer ${res.data['accessToken']}'
            ..extra['retried'] = true;
          return handler.resolve(await dio.fetch(retry));
        } on DioException {
          // Refresh token expired or revoked: fall through to logout.
        }
      }
      await logout(ref);
      handler.next(error);
    },
  ));
  return dio;
});

/// A short message for a failed call: the API's problem-details title, else the generic text.
String apiErrorMessage(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['title'] is String) return data['title'] as String;
  }
  return fallback;
}

class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  /// Returns the OTP itself only while testing without SMS (server setting Otp:ShowDevCode); otherwise null.
  Future<String?> requestOtp(String phone) async {
    final res = await _dio.post('/auth/otp/request', data: {'phone': phone});
    return res.data is Map ? res.data['devCode'] as String? : null;
  }

  /// Returns the roles the account already has (empty for a new user).
  Future<List<String>> verifyOtp(String phone, String code) async {
    final res = await _dio.post('/auth/otp/verify', data: {'phone': phone, 'code': code});
    await Session.save(res.data as Map<String, dynamic>);
    return (res.data['roles'] as List).cast<String>();
  }

  /// Adds Farmer, Host or Buyer to the account; the new tokens carry the role.
  Future<void> chooseRole(String role) async {
    final res = await _dio.post('/users/me/role', data: {'role': role});
    await Session.save(res.data as Map<String, dynamic>);
  }

  Future<void> setLanguage(String code) => _dio.put('/users/me/language', data: {'language': code});

  /// Email for updates; null or empty removes it.
  Future<void> setEmail(String? email) => _dio.put('/users/me/email', data: {'email': email});
}

final authApiProvider = Provider((ref) => AuthApi(ref.watch(dioProvider)));
