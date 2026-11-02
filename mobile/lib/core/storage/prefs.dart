import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Small key-value settings box (language, role, onboarding flags).
/// Offline drafts get their own boxes later (FR-5.7).
class Prefs {
  static const _boxName = 'prefs';
  static late Box<dynamic> _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  static String? get languageCode => _box.get('lang') as String?;
  static Future<void> setLanguageCode(String code) => _box.put('lang', code);

  static String? get role => _box.get('role') as String?;
  static Future<void> setRole(String role) => _box.put('role', role);
  static Future<void> clearRole() => _box.delete('role');
}

/// Current UI language. English is the default (FR-5.1); changes apply without restart.
class LocaleNotifier extends Notifier<String> {
  @override
  String build() => Prefs.languageCode ?? 'en';

  Future<void> set(String code) async {
    await Prefs.setLanguageCode(code);
    state = code;
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, String>(LocaleNotifier.new);
