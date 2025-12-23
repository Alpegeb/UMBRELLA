class WeatherLocation {
  final String name;
  final String subtitle;
  final double latitude;
  final double longitude;
  final String? placeId;
  final bool isDevice;

  const WeatherLocation({
    required this.name,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.isDevice = false,
  });

  WeatherLocation copyWith({
    String? name,
    String? subtitle,
    double? latitude,
    double? longitude,
    String? placeId,
    bool? isDevice,
  }) {
    return WeatherLocation(
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
      isDevice: isDevice ?? this.isDevice,
    );
  }

  String cacheKey() {
    final id = placeId;
    if (id != null && id.isNotEmpty) {
      return 'place:$id';
    }
    final lat = latitude.toStringAsFixed(2);
    final lon = longitude.toStringAsFixed(2);
    return 'lat:$lat,lon:$lon';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'subtitle': subtitle,
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
    };
  }

  factory WeatherLocation.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final subtitle = json['subtitle'];
    final lat = json['latitude'];
    final lon = json['longitude'];
    if (name is! String || lat is! num || lon is! num) {
      throw ArgumentError('Invalid WeatherLocation JSON.');
    }
    return WeatherLocation(
      name: name,
      subtitle: subtitle is String ? subtitle : '',
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
      placeId: json['placeId'] is String ? json['placeId'] as String : null,
    );
  }
}

class AirQuality {
  final int aqi;
  final String category;
  final String? dominantPollutant;

  const AirQuality({
    required this.aqi,
    required this.category,
    this.dominantPollutant,
  });

  Map<String, dynamic> toJson() => {
        'aqi': aqi,
        'category': category,
        'dominantPollutant': dominantPollutant,
      };

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    final aqiValue = json['aqi'];
    if (aqiValue is! num) {
      throw ArgumentError('Invalid AirQuality JSON.');
    }
    return AirQuality(
      aqi: aqiValue.round(),
      category: json['category'] is String ? json['category'] as String : 'Unknown',
      dominantPollutant: json['dominantPollutant'] is String
          ? json['dominantPollutant'] as String
          : null,
    );
  }
}

class CurrentWeather {
  final double tempC;
  final double feelsLikeC;
  final String condition;
  final double precipProbability;
  final double windSpeedKph;
  final double windGustKph;
  final int windDirectionDegrees;
  final double? humidity;
  final double? precipMm;
  final int? uvIndex;
  final double? visibilityKm;

  const CurrentWeather({
    required this.tempC,
    required this.feelsLikeC,
    required this.condition,
    required this.precipProbability,
    required this.windSpeedKph,
    required this.windGustKph,
    required this.windDirectionDegrees,
    this.humidity,
    this.precipMm,
    this.uvIndex,
    this.visibilityKm,
  });

  Map<String, dynamic> toJson() => {
        'tempC': tempC,
        'feelsLikeC': feelsLikeC,
        'condition': condition,
        'precipProbability': precipProbability,
        'windSpeedKph': windSpeedKph,
        'windGustKph': windGustKph,
        'windDirectionDegrees': windDirectionDegrees,
        'humidity': humidity,
        'precipMm': precipMm,
        'uvIndex': uvIndex,
        'visibilityKm': visibilityKm,
      };

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    final temp = json['tempC'];
    final feels = json['feelsLikeC'];
    final wind = json['windSpeedKph'];
    final gust = json['windGustKph'];
    final windDir = json['windDirectionDegrees'];
    if (temp is! num ||
        feels is! num ||
        wind is! num ||
        gust is! num ||
        windDir is! num) {
      throw ArgumentError('Invalid CurrentWeather JSON.');
    }
    return CurrentWeather(
      tempC: temp.toDouble(),
      feelsLikeC: feels.toDouble(),
      condition: json['condition'] is String ? json['condition'] as String : 'Clear',
      precipProbability: (json['precipProbability'] is num)
          ? (json['precipProbability'] as num).toDouble()
          : 0.0,
      windSpeedKph: wind.toDouble(),
      windGustKph: gust.toDouble(),
      windDirectionDegrees: windDir.round(),
      humidity:
          json['humidity'] is num ? (json['humidity'] as num).toDouble() : null,
      precipMm:
          json['precipMm'] is num ? (json['precipMm'] as num).toDouble() : null,
      uvIndex: json['uvIndex'] is num ? (json['uvIndex'] as num).round() : null,
      visibilityKm: json['visibilityKm'] is num
          ? (json['visibilityKm'] as num).toDouble()
          : null,
    );
  }
}

class HourlyWeather {
  final DateTime time;
  final double tempC;
  final double feelsLikeC;
  final double precipProbability;
  final String condition;
  final double windSpeedKph;
  final int? windDirectionDegrees;
  final double? precipMm;
  final int? uvIndex;
  final double? visibilityKm;

  const HourlyWeather({
    required this.time,
    required this.tempC,
    required this.feelsLikeC,
    required this.precipProbability,
    required this.condition,
    required this.windSpeedKph,
    this.windDirectionDegrees,
    this.precipMm,
    this.uvIndex,
    this.visibilityKm,
  });

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'tempC': tempC,
        'feelsLikeC': feelsLikeC,
        'precipProbability': precipProbability,
        'condition': condition,
        'windSpeedKph': windSpeedKph,
        'windDirectionDegrees': windDirectionDegrees,
        'precipMm': precipMm,
        'uvIndex': uvIndex,
        'visibilityKm': visibilityKm,
      };

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    final timeValue = json['time'];
    if (timeValue is! String) {
      throw ArgumentError('Invalid HourlyWeather JSON.');
    }
    final parsed = DateTime.tryParse(timeValue);
    if (parsed == null) {
      throw ArgumentError('Invalid HourlyWeather time.');
    }
    final temp = json['tempC'];
    final feels = json['feelsLikeC'];
    final wind = json['windSpeedKph'];
    if (temp is! num || feels is! num || wind is! num) {
      throw ArgumentError('Invalid HourlyWeather JSON.');
    }
    return HourlyWeather(
      time: parsed,
      tempC: temp.toDouble(),
      feelsLikeC: feels.toDouble(),
      precipProbability: (json['precipProbability'] is num)
          ? (json['precipProbability'] as num).toDouble()
          : 0.0,
      condition: json['condition'] is String ? json['condition'] as String : 'Clear',
      windSpeedKph: wind.toDouble(),
      windDirectionDegrees: json['windDirectionDegrees'] is num
          ? (json['windDirectionDegrees'] as num).round()
          : null,
      precipMm:
          json['precipMm'] is num ? (json['precipMm'] as num).toDouble() : null,
      uvIndex: json['uvIndex'] is num ? (json['uvIndex'] as num).round() : null,
      visibilityKm: json['visibilityKm'] is num
          ? (json['visibilityKm'] as num).toDouble()
          : null,
    );
  }
}

class DailyWeather {
  final DateTime date;
  final double minTempC;
  final double maxTempC;
  final double precipProbability;
  final String condition;
  final double? precipMm;
  final DateTime? sunriseTime;
  final DateTime? sunsetTime;

  const DailyWeather({
    required this.date,
    required this.minTempC,
    required this.maxTempC,
    required this.precipProbability,
    required this.condition,
    this.precipMm,
    this.sunriseTime,
    this.sunsetTime,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'minTempC': minTempC,
        'maxTempC': maxTempC,
        'precipProbability': precipProbability,
        'condition': condition,
        'precipMm': precipMm,
        'sunriseTime': sunriseTime?.toIso8601String(),
        'sunsetTime': sunsetTime?.toIso8601String(),
      };

  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    final dateValue = json['date'];
    if (dateValue is! String) {
      throw ArgumentError('Invalid DailyWeather JSON.');
    }
    final parsed = DateTime.tryParse(dateValue);
    if (parsed == null) {
      throw ArgumentError('Invalid DailyWeather date.');
    }
    final min = json['minTempC'];
    final max = json['maxTempC'];
    if (min is! num || max is! num) {
      throw ArgumentError('Invalid DailyWeather JSON.');
    }
    return DailyWeather(
      date: parsed,
      minTempC: min.toDouble(),
      maxTempC: max.toDouble(),
      precipProbability: (json['precipProbability'] is num)
          ? (json['precipProbability'] as num).toDouble()
          : 0.0,
      condition: json['condition'] is String ? json['condition'] as String : 'Clear',
      precipMm:
          json['precipMm'] is num ? (json['precipMm'] as num).toDouble() : null,
      sunriseTime: json['sunriseTime'] is String
          ? DateTime.tryParse(json['sunriseTime'] as String)
          : null,
      sunsetTime: json['sunsetTime'] is String
          ? DateTime.tryParse(json['sunsetTime'] as String)
          : null,
    );
  }
}

class WeatherSnapshot {
  final WeatherLocation location;
  final CurrentWeather current;
  final List<HourlyWeather> hourly;
  final List<HourlyWeather> historyHourly;
  final List<DailyWeather> daily;
  final AirQuality? airQuality;
  final DateTime updatedAt;
  final bool isFallback;

  const WeatherSnapshot({
    required this.location,
    required this.current,
    required this.hourly,
    required this.historyHourly,
    required this.daily,
    this.airQuality,
    required this.updatedAt,
    this.isFallback = false,
  });

  Map<String, dynamic> toJson() => {
        'location': location.toJson(),
        'current': current.toJson(),
        'hourly': hourly.map((h) => h.toJson()).toList(),
        'historyHourly': historyHourly.map((h) => h.toJson()).toList(),
        'daily': daily.map((d) => d.toJson()).toList(),
        'airQuality': airQuality?.toJson(),
        'updatedAt': updatedAt.toIso8601String(),
        'isFallback': isFallback,
      };

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) {
    final locationJson = json['location'];
    final currentJson = json['current'];
    if (locationJson is! Map<String, dynamic> ||
        currentJson is! Map<String, dynamic>) {
      throw ArgumentError('Invalid WeatherSnapshot JSON.');
    }
    final updatedValue = json['updatedAt'];
    final updated =
        updatedValue is String ? DateTime.tryParse(updatedValue) : null;
    if (updated == null) {
      throw ArgumentError('Invalid WeatherSnapshot updatedAt.');
    }
    final hourlyList = json['hourly'] is List ? json['hourly'] as List : const [];
    final historyList =
        json['historyHourly'] is List ? json['historyHourly'] as List : const [];
    final dailyList = json['daily'] is List ? json['daily'] as List : const [];

    return WeatherSnapshot(
      location: WeatherLocation.fromJson(locationJson),
      current: CurrentWeather.fromJson(currentJson),
      hourly: hourlyList
          .whereType<Map<String, dynamic>>()
          .map(HourlyWeather.fromJson)
          .toList(),
      historyHourly: historyList
          .whereType<Map<String, dynamic>>()
          .map(HourlyWeather.fromJson)
          .toList(),
      daily: dailyList
          .whereType<Map<String, dynamic>>()
          .map(DailyWeather.fromJson)
          .toList(),
      airQuality: json['airQuality'] is Map<String, dynamic>
          ? AirQuality.fromJson(json['airQuality'] as Map<String, dynamic>)
          : null,
      updatedAt: updated,
      isFallback: json['isFallback'] is bool ? json['isFallback'] as bool : false,
    );
  }

  static WeatherSnapshot fallback() {
    return fallbackFor(const WeatherLocation(
      name: 'Istanbul',
      subtitle: 'My Location',
      latitude: 41.0082,
      longitude: 28.9784,
    ));
  }

  static WeatherSnapshot fallbackFor(WeatherLocation location) {
    final now = DateTime.now();

    const rainPattern = [10, 25, 55, 70];
    final hourly = List.generate(12, (i) {
      final hour = now.add(Duration(hours: i));
      final temp = 15 + (i % 4);
      final rain = rainPattern[i % rainPattern.length] / 100.0;
      return HourlyWeather(
        time: hour,
        tempC: temp.toDouble(),
        feelsLikeC: (temp - 1).toDouble(),
        precipProbability: rain,
        condition: rain >= 0.4 ? 'Light rain' : 'Cloudy',
        windSpeedKph: 13,
        windDirectionDegrees: 53,
        uvIndex: null,
        visibilityKm: null,
      );
    });

    const highs = [19, 18, 16, 14, 15];
    const lows = [12, 11, 10, 9, 8];
    final daily = List.generate(5, (i) {
      final date = DateTime(now.year, now.month, now.day).add(
        Duration(days: i),
      );
      final rain = i == 2 ? 0.55 : 0.25;
      return DailyWeather(
        date: date,
        minTempC: lows[i].toDouble(),
        maxTempC: highs[i].toDouble(),
        precipProbability: rain,
        condition: rain >= 0.4 ? 'Light rain' : 'Cloudy',
        precipMm: rain >= 0.4 ? 3.0 : 0.0,
        sunriseTime: null,
        sunsetTime: null,
      );
    });

    return WeatherSnapshot(
      location: location,
      current: const CurrentWeather(
        tempC: 15,
        feelsLikeC: 13,
        condition: 'Light rain',
        precipProbability: 0.35,
        windSpeedKph: 13,
        windGustKph: 30,
        windDirectionDegrees: 53,
        humidity: 0.7,
        precipMm: 0.0,
        uvIndex: null,
        visibilityKm: null,
      ),
      hourly: hourly,
      historyHourly: const [],
      daily: daily,
      airQuality: null,
      updatedAt: now,
      isFallback: true,
    );
  }
}
