import 'package:flutter/foundation.dart';

import '../models/settings_models.dart';
import 'api.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore._();
  static final SettingsStore instance = SettingsStore._();

  AppSettings _value = const AppSettings();
  AppSettings get value => _value;

  /// Call once after sign-in. Keeps the defaults if the backend isn't connected yet.
  Future<void> load() async {
    try {
      _value = await Api.loadSettings();
      notifyListeners();
    } on BackendNotConnected {
      // keep defaults
    }
  }

  /// Applies immediately, saves, and rolls back if the save fails.
  Future<void> update(AppSettings next) async {
    final previous = _value;
    _value = next;
    notifyListeners();
    try {
      await Api.saveSettings(next);
    } catch (_) {
      _value = previous;
      notifyListeners();
      rethrow;
    }
  }
}