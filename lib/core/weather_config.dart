import 'weather_secrets.dart';

class WeatherConfig {
  static String? _runtimeApiKey;
  static String? _runtimePlacesApiKey;
  static String? _runtimeAirQualityApiKey;

  static void setRuntimeKeys({
    String? weatherApiKey,
    String? placesApiKey,
    String? airQualityApiKey,
  }) {
    _runtimeApiKey = _cleanKey(weatherApiKey);
    _runtimePlacesApiKey = _cleanKey(placesApiKey);
    _runtimeAirQualityApiKey = _cleanKey(airQualityApiKey);
  }

  static String get apiKey {
    final env = const String.fromEnvironment(
      'GOOGLE_WEATHER_API_KEY',
      defaultValue: WeatherSecrets.googleApiKey,
    );
    return _runtimeApiKey?.isNotEmpty == true ? _runtimeApiKey! : env;
  }

  static String get baseUrl => const String.fromEnvironment(
        'GOOGLE_WEATHER_BASE_URL',
        defaultValue: 'https://weather.googleapis.com/v1',
      );

  static String get placesApiKey {
    final env = const String.fromEnvironment(
      'GOOGLE_PLACES_API_KEY',
      defaultValue: '',
    );
    if (_runtimePlacesApiKey?.isNotEmpty == true) return _runtimePlacesApiKey!;
    if (env.isNotEmpty) return env;
    return apiKey;
  }

  static String get placesBaseUrl => const String.fromEnvironment(
        'GOOGLE_PLACES_BASE_URL',
        defaultValue: 'https://maps.googleapis.com/maps/api/place',
      );

  static String get airQualityApiKey {
    final env = const String.fromEnvironment(
      'GOOGLE_AIR_QUALITY_API_KEY',
      defaultValue: '',
    );
    if (_runtimeAirQualityApiKey?.isNotEmpty == true) {
      return _runtimeAirQualityApiKey!;
    }
    if (env.isNotEmpty) return env;
    return apiKey;
  }

  static String get airQualityBaseUrl => const String.fromEnvironment(
        'GOOGLE_AIR_QUALITY_BASE_URL',
        defaultValue: 'https://airquality.googleapis.com',
      );

  static int get forecastHours =>
      const int.fromEnvironment('GOOGLE_WEATHER_FORECAST_HOURS', defaultValue: 24);

  static int get forecastDays =>
      const int.fromEnvironment('GOOGLE_WEATHER_FORECAST_DAYS', defaultValue: 7);

  static int get historyHours => const int.fromEnvironment(
        'GOOGLE_WEATHER_HISTORY_HOURS',
        defaultValue: 24,
      );

  static String? _cleanKey(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
