import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/weather_config.dart';

class ApiKeyStore {
  ApiKeyStore._();

  static final ApiKeyStore instance = ApiKeyStore._();

  static const _prefsWeatherKey = 'googleWeatherApiKey';
  static const _prefsPlacesKey = 'googlePlacesApiKey';
  static const _prefsAirKey = 'googleAirQualityApiKey';
  static const _prefsFallbackKey = 'googleApiKey';
  static const _configDocPath = 'app_config/api_keys';

  Future<void> load({bool allowRemote = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedWeather = prefs.getString(_prefsWeatherKey);
    final cachedPlaces = prefs.getString(_prefsPlacesKey);
    final cachedAir = prefs.getString(_prefsAirKey);
    final cachedFallback = prefs.getString(_prefsFallbackKey);

    _applyRuntimeKeys(
      weatherKey: cachedWeather ?? cachedFallback,
      placesKey: cachedPlaces ?? cachedFallback,
      airKey: cachedAir ?? cachedFallback,
    );

    if (!allowRemote) return;

    try {
      final doc = await FirebaseFirestore.instance.doc(_configDocPath).get();
      final data = doc.data();
      if (data == null || data.isEmpty) return;

      final fallback = _readKey(data, 'googleApiKey');
      final weatherKey = _readKey(data, 'weatherApiKey') ?? fallback;
      final placesKey = _readKey(data, 'placesApiKey') ?? fallback;
      final airKey = _readKey(data, 'airQualityApiKey') ?? fallback;

      if (weatherKey != null) {
        await prefs.setString(_prefsWeatherKey, weatherKey);
      }
      if (placesKey != null) {
        await prefs.setString(_prefsPlacesKey, placesKey);
      }
      if (airKey != null) {
        await prefs.setString(_prefsAirKey, airKey);
      }
      if (fallback != null) {
        await prefs.setString(_prefsFallbackKey, fallback);
      }

      _applyRuntimeKeys(
        weatherKey: weatherKey ?? cachedWeather ?? cachedFallback,
        placesKey: placesKey ?? cachedPlaces ?? cachedFallback,
        airKey: airKey ?? cachedAir ?? cachedFallback,
      );
    } catch (_) {
      // Keep cached keys if Firestore is unavailable.
    }
  }

  void _applyRuntimeKeys({
    String? weatherKey,
    String? placesKey,
    String? airKey,
  }) {
    WeatherConfig.setRuntimeKeys(
      weatherApiKey: weatherKey,
      placesApiKey: placesKey,
      airQualityApiKey: airKey,
    );
  }

  String? _readKey(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
