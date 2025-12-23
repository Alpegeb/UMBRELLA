import 'weather_secrets.dart';

class WeatherConfig {
  static const String apiKey = String.fromEnvironment(
    'GOOGLE_WEATHER_API_KEY',
    defaultValue: WeatherSecrets.googleApiKey,
  );
  static const String baseUrl = String.fromEnvironment(
    'GOOGLE_WEATHER_BASE_URL',
    defaultValue: 'https://weather.googleapis.com/v1',
  );
  static const String placesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: apiKey,
  );
  static const String placesBaseUrl = String.fromEnvironment(
    'GOOGLE_PLACES_BASE_URL',
    defaultValue: 'https://maps.googleapis.com/maps/api/place',
  );
  static const String airQualityApiKey = String.fromEnvironment(
    'GOOGLE_AIR_QUALITY_API_KEY',
    defaultValue: apiKey,
  );
  static const String airQualityBaseUrl = String.fromEnvironment(
    'GOOGLE_AIR_QUALITY_BASE_URL',
    defaultValue: 'https://airquality.googleapis.com',
  );
  static const int forecastHours =
      int.fromEnvironment('GOOGLE_WEATHER_FORECAST_HOURS', defaultValue: 24);
  static const int forecastDays =
      int.fromEnvironment('GOOGLE_WEATHER_FORECAST_DAYS', defaultValue: 7);
  static const int historyHours =
      int.fromEnvironment('GOOGLE_WEATHER_HISTORY_HOURS', defaultValue: 24);
}
