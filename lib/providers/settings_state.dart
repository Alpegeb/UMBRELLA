import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class SettingsState extends ChangeNotifier {
  static const _showUmbrellaKey = 'showUmbrellaIndex';
  static const _useCelsiusKey = 'useCelsius';
  static const _windInKphKey = 'windInKph';
  static const _notifyRainKey = 'notifyRain';
  static const _notifySunriseKey = 'notifySunrise';
  static const _notifySunsetKey = 'notifySunset';
  static const _notifyUvKey = 'notifyUv';
  static const _notifyAirQualityKey = 'notifyAirQuality';
  static const _notifyVisibilityKey = 'notifyVisibility';
  static const _notifyLocationKey = 'notifyLocationKey';
  static const _notifyLocationKeysKey = 'notifyLocationKeys';

  bool _showUmbrellaIndex = true;
  bool _useCelsius = true;
  bool _windInKph = true;
  bool _notifyRain = true;
  bool _notifySunrise = true;
  bool _notifySunset = true;
  bool _notifyUv = true;
  bool _notifyAirQuality = true;
  bool _notifyVisibility = true;
  List<String>? _notifyLocationKeys;
  bool _locationsEditing = false;
  bool _loaded = false;
  SharedPreferences? _prefs;

  bool get showUmbrellaIndex => _showUmbrellaIndex;
  bool get useCelsius => _useCelsius;
  bool get windInKph => _windInKph;
  bool get notifyRain => _notifyRain;
  bool get notifySunrise => _notifySunrise;
  bool get notifySunset => _notifySunset;
  bool get notifyUv => _notifyUv;
  bool get notifyAirQuality => _notifyAirQuality;
  bool get notifyVisibility => _notifyVisibility;
  List<String> get notifyLocationKeys =>
      List.unmodifiable(_notifyLocationKeys ?? const []);
  bool get hasNotifyLocationSelection => _notifyLocationKeys != null;
  bool get locationsEditing => _locationsEditing;
  bool get loaded => _loaded;

  SettingsState() {
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    _showUmbrellaIndex = _prefs?.getBool(_showUmbrellaKey) ?? true;
    _useCelsius = _prefs?.getBool(_useCelsiusKey) ?? true;
    _windInKph = _prefs?.getBool(_windInKphKey) ?? true;
    _notifyRain = _prefs?.getBool(_notifyRainKey) ?? true;
    _notifySunrise = _prefs?.getBool(_notifySunriseKey) ?? true;
    _notifySunset = _prefs?.getBool(_notifySunsetKey) ?? true;
    _notifyUv = _prefs?.getBool(_notifyUvKey) ?? true;
    _notifyAirQuality = _prefs?.getBool(_notifyAirQualityKey) ?? true;
    _notifyVisibility = _prefs?.getBool(_notifyVisibilityKey) ?? true;
    final storedKeys = _prefs?.getStringList(_notifyLocationKeysKey);
    if (storedKeys != null) {
      _notifyLocationKeys = _dedupeKeys(storedKeys);
    } else {
      final legacyKey = _prefs?.getString(_notifyLocationKey);
      final trimmedLegacy = legacyKey?.trim();
      if (trimmedLegacy != null && trimmedLegacy.isNotEmpty) {
        _notifyLocationKeys = [trimmedLegacy];
        await _prefs?.setStringList(
          _notifyLocationKeysKey,
          _notifyLocationKeys!,
        );
        await _prefs?.remove(_notifyLocationKey);
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setShowUmbrellaIndex(bool value) async {
    _showUmbrellaIndex = value;
    notifyListeners();
    await _prefs?.setBool(_showUmbrellaKey, value);
  }

  Future<void> setUseCelsius(bool value) async {
    _useCelsius = value;
    notifyListeners();
    await _prefs?.setBool(_useCelsiusKey, value);
  }

  Future<void> setWindInKph(bool value) async {
    _windInKph = value;
    notifyListeners();
    await _prefs?.setBool(_windInKphKey, value);
  }

  Future<void> setNotifyRain(bool value) async {
    _notifyRain = value;
    notifyListeners();
    await _prefs?.setBool(_notifyRainKey, value);
    await NotificationService.instance.rescheduleFromCache();
  }

  Future<void> setNotifySunrise(bool value) async {
    _notifySunrise = value;
    notifyListeners();
    await _prefs?.setBool(_notifySunriseKey, value);
    await NotificationService.instance.rescheduleFromCache();
  }

  Future<void> setNotifySunset(bool value) async {
    _notifySunset = value;
    notifyListeners();
    await _prefs?.setBool(_notifySunsetKey, value);
    await NotificationService.instance.rescheduleFromCache();
  }

  Future<void> setNotifyUv(bool value) async {
    _notifyUv = value;
    notifyListeners();
    await _prefs?.setBool(_notifyUvKey, value);
    await NotificationService.instance.rescheduleFromCache();
  }

  Future<void> setNotifyAirQuality(bool value) async {
    _notifyAirQuality = value;
    notifyListeners();
    await _prefs?.setBool(_notifyAirQualityKey, value);
    await NotificationService.instance.rescheduleFromCache();
  }

  Future<void> setNotifyVisibility(bool value) async {
    _notifyVisibility = value;
    notifyListeners();
    await _prefs?.setBool(_notifyVisibilityKey, value);
    await NotificationService.instance.rescheduleFromCache();
  }

  Future<void> setNotifyLocationKeys(List<String> keys) async {
    _notifyLocationKeys = _dedupeKeys(keys);
    notifyListeners();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setStringList(_notifyLocationKeysKey, _notifyLocationKeys!);
    await _prefs?.remove(_notifyLocationKey);
    await NotificationService.instance.rescheduleFromCache();
  }

  Future<void> toggleNotifyLocationKey(String key, bool enabled) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return;
    final current = _notifyLocationKeys == null
        ? <String>{}
        : _notifyLocationKeys!.toSet();
    if (enabled) {
      current.add(trimmed);
    } else {
      current.remove(trimmed);
    }
    await setNotifyLocationKeys(current.toList());
  }

  void setLocationsEditing(bool value) {
    if (_locationsEditing == value) return;
    _locationsEditing = value;
    notifyListeners();
  }

  List<String> _dedupeKeys(List<String> keys) {
    final seen = <String>{};
    final cleaned = <String>[];
    for (final key in keys) {
      final trimmed = key.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) continue;
      seen.add(trimmed);
      cleaned.add(trimmed);
    }
    return cleaned;
  }
}
