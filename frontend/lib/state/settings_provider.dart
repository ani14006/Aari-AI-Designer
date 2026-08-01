import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

const _kDarkModeKey = 'settings.dark_mode';
const _kLanguageKey = 'settings.language';
const _kNotificationsKey = 'settings.notifications_enabled';

class SettingsState {
  final ThemeMode themeMode;
  final String language;
  final bool notificationsEnabled;

  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.language = 'en',
    this.notificationsEnabled = true,
  });

  SettingsState copyWith(
      {ThemeMode? themeMode, String? language, bool? notificationsEnabled}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

/// Persists Settings-screen preferences locally (instant UI) and syncs to the backend profile.
class SettingsController extends StateNotifier<SettingsState> {
  SettingsController() : super(const SettingsState()) {
    _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_kDarkModeKey) ?? false;
    final language = prefs.getString(_kLanguageKey) ?? 'en';
    final notifications = prefs.getBool(_kNotificationsKey) ?? true;
    state = SettingsState(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      language: language,
      notificationsEnabled: notifications,
    );
  }

  Future<void> setDarkMode(bool isDark) async {
    state =
        state.copyWith(themeMode: isDark ? ThemeMode.dark : ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModeKey, isDark);
    unawaited(ApiService.instance.updateSettings(darkMode: isDark));
  }

  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, language);
    unawaited(ApiService.instance.updateSettings(language: language));
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsKey, enabled);
    unawaited(
        ApiService.instance.updateSettings(notificationsEnabled: enabled));
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController();
});

void unawaited(Future<void> future) {
  future.catchError((_) {});
}
