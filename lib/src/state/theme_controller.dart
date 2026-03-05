import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class ThemeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode_pref_v1';

  @override
  ThemeMode build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key) ?? 'dark';
    return _fromStorage(raw);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_key, _toStorage(mode));
  }

  ThemeMode _fromStorage(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.dark;
      default:
        return ThemeMode.dark;
    }
  }

  String _toStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
