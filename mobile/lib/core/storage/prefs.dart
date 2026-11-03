import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Small key-value settings box (language, theme, role, onboarding flags).
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

  /// ThemeMode name: system, light or dark.
  static String? get themeMode => _box.get('theme') as String?;
  static Future<void> setThemeMode(String mode) => _box.put('theme', mode);
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

/// Light, dark, or follow the device (the default). Saved on this device only.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.values.asNameMap()[Prefs.themeMode] ?? ThemeMode.system;

  Future<void> set(ThemeMode mode) async {
    await Prefs.setThemeMode(mode.name);
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
