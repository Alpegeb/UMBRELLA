import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

import '../core/weather_config.dart';
import 'weather_models.dart';
import 'weather_utils.dart';

class WeatherApiException implements Exception {
  final String message;
  WeatherApiException(this.message);

  @override
  String toString() => 'WeatherApiException: $message';
}

class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<WeatherSnapshot> fetchWeather(WeatherLocation location) async {
    if (WeatherConfig.apiKey.isEmpty) {
      throw WeatherApiException('Missing GOOGLE_WEATHER_API_KEY.');
    }

    Map<String, dynamic>? hourlyData;
    Map<String, dynamic>? historyData;
    Map<String, dynamic>? dailyData;
    Map<String, dynamic>? currentData;
    Map<String, dynamic>? airQualityData;

    final dayCount = math.max(WeatherConfig.forecastDays, 5);

    try {
      hourlyData = await _fetchEndpoint(
        '/forecast/hours:lookup',
        location.latitude,
        location.longitude,
        queryParams: {
          'hours': WeatherConfig.forecastHours.toString(),
          'pageSize': WeatherConfig.forecastHours.toString(),
          'unitsSystem': 'METRIC',
        },
      );
    } catch (_) {
      hourlyData = null;
    }

    try {
      historyData = await _fetchEndpoint(
        '/history/hours:lookup',
        location.latitude,
        location.longitude,
        queryParams: {
          'hours': WeatherConfig.historyHours.toString(),
          'pageSize': WeatherConfig.historyHours.toString(),
          'unitsSystem': 'METRIC',
        },
      );
    } catch (_) {
      historyData = null;
    }

    try {
      dailyData = await _fetchEndpoint(
        '/forecast/days:lookup',
        location.latitude,
        location.longitude,
        queryParams: {
          'days': dayCount.toString(),
          'pageSize': dayCount.toString(),
          'unitsSystem': 'METRIC',
        },
      );
    } catch (_) {
      dailyData = null;
    }

    try {
      currentData = await _fetchEndpoint(
        '/currentConditions:lookup',
        location.latitude,
        location.longitude,
        queryParams: const {
          'unitsSystem': 'METRIC',
        },
      );
    } catch (_) {
      currentData = null;
    }

    try {
      airQualityData = await _fetchAirQuality(
        location.latitude,
        location.longitude,
      );
    } catch (_) {
      airQualityData = null;
    }

    final parsedHourly = _parseHourly(hourlyData);
    final parsedHistory = _parseHourly(historyData);
    var parsedCurrent = _parseCurrent(currentData);
    if (parsedCurrent == null && parsedHourly.isNotEmpty) {
      parsedCurrent = _currentFromHourly(parsedHourly);
    }
    if (parsedCurrent == null) {
      throw WeatherApiException('Unable to parse current conditions.');
    }

    final hourly = _ensureHourly(parsedHourly);
    final historyHourly = _ensureHistory(parsedHistory);
    final parsedDaily = _parseDaily(dailyData);
    final daily = _ensureDaily(parsedDaily, hourly);
    final airQuality = _parseAirQuality(airQualityData);

    return WeatherSnapshot(
      location: location,
      current: parsedCurrent,
      hourly: hourly,
      historyHourly: historyHourly,
      daily: daily,
      airQuality: airQuality,
      updatedAt: DateTime.now(),
    );
  }

  Future<Map<String, dynamic>> _fetchEndpoint(
    String path,
    double lat,
    double lon, {
    Map<String, String> queryParams = const {},
  }) async {
    final baseQuery = {
      'location.latitude': '$lat',
      'location.longitude': '$lon',
      ...queryParams,
    };
    final primaryUri = _buildUri(path, baseQuery);
    final primaryResponse = await _client.get(primaryUri);
    if (primaryResponse.statusCode == 200) {
      return _decodeJson(primaryResponse.body);
    }

    final altUri = _buildUri(path, {
      'location': '$lat,$lon',
      ...queryParams,
    });
    final altResponse = await _client.get(altUri);
    if (altResponse.statusCode == 200) {
      return _decodeJson(altResponse.body);
    }

    throw WeatherApiException(
      'Request failed: ${primaryResponse.statusCode} / ${altResponse.statusCode}.',
    );
  }

  Future<Map<String, dynamic>> _fetchAirQuality(double lat, double lon) async {
    if (WeatherConfig.airQualityApiKey.isEmpty) {
      throw WeatherApiException('Missing GOOGLE_AIR_QUALITY_API_KEY.');
    }
    final base = Uri.parse(WeatherConfig.airQualityBaseUrl);
    final basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final uri = base.replace(
      path: '$basePath/v1/currentConditions:lookup',
      queryParameters: {
        'key': WeatherConfig.airQualityApiKey,
      },
    );
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'location': {
          'latitude': lat,
          'longitude': lon,
        },
        'universalAqi': true,
        'extraComputations': ['LOCAL_AQI'],
      }),
    );
    if (response.statusCode == 200) {
      return _decodeJson(response.body);
    }
    throw WeatherApiException(
      'Air quality request failed: ${response.statusCode}.',
    );
  }

  Uri _buildUri(String path, Map<String, String> query) {
    final base = Uri.parse(WeatherConfig.baseUrl);
    final basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final fullPath = '$basePath$path';
    final qp = {
      ...query,
      'key': WeatherConfig.apiKey,
    };
    return base.replace(path: fullPath, queryParameters: qp);
  }

  Map<String, dynamic> _decodeJson(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw WeatherApiException('Unexpected response format.');
  }

  CurrentWeather? _parseCurrent(Map<String, dynamic>? data) {
    if (data == null) return null;
    final root = _extractRoot(data, ['currentConditions', 'current']);

    final tempC = _readTemperatureC(
      root,
      valuePaths: [
        ['temperature', 'degrees'],
        ['temperature', 'value'],
        ['temp_c'],
        ['temp'],
      ],
      unitPaths: [
        ['temperature', 'unit'],
        ['temp_unit'],
      ],
    );
    if (tempC == null) return null;

    final feelsC = _readTemperatureC(
          root,
          valuePaths: [
            ['feelsLikeTemperature', 'degrees'],
            ['feelsLikeTemperature', 'value'],
            ['feelslike_c'],
            ['feels_like'],
          ],
          unitPaths: [
            ['feelsLikeTemperature', 'unit'],
          ],
        ) ??
        tempC;

    final condition = _readString(root, [
          ['weatherCondition', 'description'],
          ['weatherCondition', 'description', 'text'],
          ['weatherCondition', 'type'],
          ['condition', 'text'],
          ['weather', 0, 'description'],
          ['summary'],
        ]) ??
        'Clear';

    final precipProb = normalizeProbability(
      _readDouble(root, [
            ['precipitationProbability'],
            ['precipitation', 'probability'],
            ['precipitation', 'probability', 'value'],
            ['precipitation', 'probability', 'percent'],
            ['precipProbability'],
            ['pop'],
            ['daily_chance_of_rain'],
          ]) ??
          0.0,
    );

    final windSpeedKph = _readSpeedKph(
          root,
          valuePaths: [
            ['wind', 'speed', 'value'],
            ['wind', 'speed'],
            ['wind_kph'],
            ['wind_speed'],
          ],
          unitPaths: [
            ['wind', 'speed', 'unit'],
          ],
          assumeMetersPerSecond: true,
        ) ??
        0.0;

    final windGustKph = _readSpeedKph(
          root,
          valuePaths: [
            ['windGust', 'speed', 'value'],
            ['wind', 'gust', 'value'],
            ['gust_kph'],
            ['wind_gust'],
          ],
          unitPaths: [
            ['windGust', 'speed', 'unit'],
            ['wind', 'gust', 'unit'],
          ],
          assumeMetersPerSecond: true,
        ) ??
        windSpeedKph;

    final windDir = _readInt(root, [
          ['wind', 'direction', 'degrees'],
          ['wind_degree'],
          ['wind_deg'],
        ]) ??
        0;

    final humidity = _readDouble(root, [
      ['humidity'],
      ['humidity', 'value'],
      ['relativeHumidity'],
    ]);

    final normalizedHumidity =
        humidity == null ? null : normalizeProbability(humidity);

    final precipMm = _readDouble(root, [
      ['precipitation', 'value'],
      ['precipitation', 'qpf', 'value'],
      ['precipitation', 'qpf', 'quantity'],
      ['precipitation', 'qpf', 'amount'],
      ['precip_mm'],
      ['rain', '1h'],
      ['rain', '3h'],
    ]);
    final uvIndex = _readInt(root, [
      ['uvIndex'],
      ['uv_index'],
      ['uv'],
    ]);
    final visibilityKm = _readDistanceKm(
      root,
      valuePaths: [
        ['visibility', 'distance'],
        ['visibility', 'value'],
        ['visibility'],
        ['vis_km'],
        ['visibility_km'],
      ],
      unitPaths: [
        ['visibility', 'unit'],
        ['visibility', 'units'],
      ],
    );

    return CurrentWeather(
      tempC: tempC,
      feelsLikeC: feelsC,
      condition: condition,
      precipProbability: precipProb,
      windSpeedKph: windSpeedKph,
      windGustKph: windGustKph,
      windDirectionDegrees: windDir,
      humidity: normalizedHumidity,
      precipMm: precipMm,
      uvIndex: uvIndex,
      visibilityKm: visibilityKm,
    );
  }

  List<HourlyWeather> _parseHourly(Map<String, dynamic>? data) {
    if (data == null) return [];
    final hours = data['forecastHours'] ??
        data['historyHours'] ??
        data['hourlyForecasts'];
    if (hours is List) {
      return hours
          .whereType<Map<String, dynamic>>()
          .map(_parseGoogleHourly)
          .whereType<HourlyWeather>()
          .toList();
    }

    final forecast = data['forecast'];
    if (forecast is Map<String, dynamic>) {
      final nestedHours =
          forecast['forecastHours'] ?? forecast['hourlyForecasts'];
      if (nestedHours is List) {
        return nestedHours
            .whereType<Map<String, dynamic>>()
            .map(_parseGoogleHourly)
            .whereType<HourlyWeather>()
            .toList();
      }
    }

    final hourly = data['hourly'];
    if (hourly is List) {
      return hourly
          .whereType<Map<String, dynamic>>()
          .map(_parseOpenWeatherHourly)
          .whereType<HourlyWeather>()
          .toList();
    }

    if (forecast is Map<String, dynamic> &&
        forecast['forecastday'] is List) {
      final days = forecast['forecastday'] as List;
      final entries = <HourlyWeather>[];
      for (final day in days.whereType<Map<String, dynamic>>()) {
        final hourList = day['hour'];
        if (hourList is List) {
          entries.addAll(
            hourList
                .whereType<Map<String, dynamic>>()
                .map(_parseWeatherApiHourly)
                .whereType<HourlyWeather>(),
          );
        }
      }
      return entries;
    }

    return [];
  }

  List<DailyWeather> _parseDaily(Map<String, dynamic>? data) {
    if (data == null) return [];
    final days = data['forecastDays'] ?? data['dailyForecasts'];
    if (days is List) {
      return days
          .whereType<Map<String, dynamic>>()
          .map(_parseGoogleDaily)
          .whereType<DailyWeather>()
          .toList();
    }

    final forecast = data['forecast'];
    if (forecast is Map<String, dynamic>) {
      final nestedDays =
          forecast['forecastDays'] ?? forecast['dailyForecasts'];
      if (nestedDays is List) {
        return nestedDays
            .whereType<Map<String, dynamic>>()
            .map(_parseGoogleDaily)
            .whereType<DailyWeather>()
            .toList();
      }
    }

    final daily = data['daily'];
    if (daily is List) {
      return daily
          .whereType<Map<String, dynamic>>()
          .map(_parseOpenWeatherDaily)
          .whereType<DailyWeather>()
          .toList();
    }

    if (forecast is Map<String, dynamic> &&
        forecast['forecastday'] is List) {
      return (forecast['forecastday'] as List)
          .whereType<Map<String, dynamic>>()
          .map(_parseWeatherApiDaily)
          .whereType<DailyWeather>()
          .toList();
    }

    return [];
  }

  List<HourlyWeather> _ensureHourly(List<HourlyWeather> hourly) {
    if (hourly.isNotEmpty) {
      hourly.sort((a, b) => a.time.compareTo(b.time));
      return hourly.take(WeatherConfig.forecastHours).toList();
    }
    return [];
  }

  List<HourlyWeather> _ensureHistory(List<HourlyWeather> history) {
    if (history.isNotEmpty) {
      history.sort((a, b) => a.time.compareTo(b.time));
      return history.take(WeatherConfig.historyHours).toList();
    }
    return [];
  }

  List<DailyWeather> _ensureDaily(
    List<DailyWeather> daily,
    List<HourlyWeather> hourly,
  ) {
    final dayCount = math.max(WeatherConfig.forecastDays, 5);
    if (daily.isNotEmpty) {
      daily.sort((a, b) => a.date.compareTo(b.date));
      return daily.take(dayCount).toList();
    }

    if (hourly.isNotEmpty) {
      return _buildDailyFromHourly(hourly)
          .take(dayCount)
          .toList();
    }
    return [];
  }

  CurrentWeather _currentFromHourly(List<HourlyWeather> hourly) {
    final first = hourly.first;
    return CurrentWeather(
      tempC: first.tempC,
      feelsLikeC: first.feelsLikeC,
      condition: first.condition,
      precipProbability: first.precipProbability,
      windSpeedKph: first.windSpeedKph,
      windGustKph: first.windSpeedKph,
      windDirectionDegrees: first.windDirectionDegrees ?? 0,
      precipMm: first.precipMm,
      humidity: null,
      uvIndex: first.uvIndex,
      visibilityKm: first.visibilityKm,
    );
  }

  List<DailyWeather> _buildDailyFromHourly(List<HourlyWeather> hourly) {
    final Map<DateTime, List<HourlyWeather>> grouped = {};
    for (final hour in hourly) {
      final date = DateTime(hour.time.year, hour.time.month, hour.time.day);
      grouped.putIfAbsent(date, () => []).add(hour);
    }

    final List<DailyWeather> daily = [];
    for (final entry in grouped.entries) {
      final date = entry.key;
      final hours = entry.value;
      double minTemp = hours.first.tempC;
      double maxTemp = hours.first.tempC;
      double maxPrecip = hours.first.precipProbability;
      double totalPrecip = 0.0;
      int precipCount = 0;
      final condition = hours.first.condition;

      for (final hour in hours) {
        minTemp = math.min(minTemp, hour.tempC);
        maxTemp = math.max(maxTemp, hour.tempC);
        maxPrecip = math.max(maxPrecip, hour.precipProbability);
        if (hour.precipMm != null) {
          totalPrecip += hour.precipMm!;
          precipCount++;
        }
      }

      daily.add(
        DailyWeather(
          date: date,
          minTempC: minTemp,
          maxTempC: maxTemp,
          precipProbability: maxPrecip,
          condition: condition,
          precipMm: precipCount > 0 ? totalPrecip : null,
        ),
      );
    }

    daily.sort((a, b) => a.date.compareTo(b.date));
    return daily;
  }

  HourlyWeather? _parseGoogleHourly(Map<String, dynamic> data) {
    final interval = data['interval'];
    final intervalStart =
        interval is Map<String, dynamic> ? interval['startTime'] : null;
    final timeString = data['forecastTime'] ??
        data['time'] ??
        data['dateTime'] ??
        data['displayDateTime'] ??
        intervalStart ??
        data['startTime'];
    final time = _parseTime(timeString);
    if (time == null) return null;

    final tempC = _readTemperatureC(
      data,
      valuePaths: [
        ['temperature', 'degrees'],
        ['temperature', 'value'],
      ],
      unitPaths: [
        ['temperature', 'unit'],
      ],
    );
    if (tempC == null) return null;

    final feelsC = _readTemperatureC(
          data,
          valuePaths: [
            ['feelsLikeTemperature', 'degrees'],
            ['feelsLikeTemperature', 'value'],
          ],
          unitPaths: [
            ['feelsLikeTemperature', 'unit'],
          ],
        ) ??
        tempC;

    final condition = _readString(data, [
          ['weatherCondition', 'description'],
          ['weatherCondition', 'description', 'text'],
          ['weatherCondition', 'type'],
          ['condition', 'text'],
        ]) ??
        'Clear';

    final precipProb = normalizeProbability(
      _readDouble(data, [
            ['precipitationProbability'],
            ['precipitation', 'probability'],
            ['precipitation', 'probability', 'value'],
            ['precipitation', 'probability', 'percent'],
            ['precipProbability'],
          ]) ??
          0.0,
    );

    final windSpeedKph = _readSpeedKph(
          data,
          valuePaths: [
            ['wind', 'speed', 'value'],
          ],
          unitPaths: [
            ['wind', 'speed', 'unit'],
          ],
        ) ??
        0.0;

    final windDir = _readInt(data, [
      ['wind', 'direction', 'degrees'],
    ]);
    final uvIndex = _readInt(data, [
      ['uvIndex'],
      ['uv_index'],
      ['uv'],
    ]);
    final visibilityKm = _readDistanceKm(
      data,
      valuePaths: [
        ['visibility', 'distance'],
        ['visibility', 'value'],
        ['visibility'],
        ['vis_km'],
        ['visibility_km'],
      ],
      unitPaths: [
        ['visibility', 'unit'],
        ['visibility', 'units'],
      ],
    );

    return HourlyWeather(
      time: time,
      tempC: tempC,
      feelsLikeC: feelsC,
      precipProbability: precipProb,
      condition: condition,
      windSpeedKph: windSpeedKph,
      windDirectionDegrees: windDir,
      precipMm: _readDouble(data, [
        ['precipitation', 'qpf', 'value'],
        ['precipitation', 'qpf', 'quantity'],
        ['precipitation', 'value'],
      ]),
      uvIndex: uvIndex,
      visibilityKm: visibilityKm,
    );
  }

  HourlyWeather? _parseOpenWeatherHourly(Map<String, dynamic> data) {
    final time = _parseUnixTime(data['dt']);
    if (time == null) return null;

    final tempC = _toCelsius(
      _readDouble(data, [
            ['temp'],
          ]) ??
          0.0,
    );
    final feelsC = _toCelsius(
      _readDouble(data, [
            ['feels_like'],
          ]) ??
          tempC,
    );

    final condition = _readString(data, [
          ['weather', 0, 'description'],
        ]) ??
        'Clear';

    final precipProb = normalizeProbability(
      _readDouble(data, [
            ['pop'],
          ]) ??
          0.0,
    );

    final windSpeedKph = _readSpeedKph(
          data,
          valuePaths: [
            ['wind_speed'],
          ],
          unitPaths: const [],
          assumeMetersPerSecond: true,
        ) ??
        0.0;

    final windDir = _readInt(data, [
      ['wind_deg'],
    ]);
    final uvIndex = _readInt(data, [
      ['uvi'],
      ['uv'],
      ['uv_index'],
    ]);
    final visibilityKm = _readDistanceKm(
      data,
      valuePaths: [
        ['visibility'],
        ['vis_km'],
        ['visibility_km'],
      ],
      unitPaths: const [],
    );

    return HourlyWeather(
      time: time,
      tempC: tempC,
      feelsLikeC: feelsC,
      precipProbability: precipProb,
      condition: condition,
      windSpeedKph: windSpeedKph,
      windDirectionDegrees: windDir,
      precipMm: _readDouble(data, [
        ['rain', '1h'],
        ['snow', '1h'],
      ]),
      uvIndex: uvIndex,
      visibilityKm: visibilityKm,
    );
  }

  HourlyWeather? _parseWeatherApiHourly(Map<String, dynamic> data) {
    final time = _parseTime(data['time']);
    if (time == null) return null;

    final tempC = _readDouble(data, [
          ['temp_c'],
        ]) ??
        0.0;
    final feelsC = _readDouble(data, [
          ['feelslike_c'],
        ]) ??
        tempC;

    final condition = _readString(data, [
          ['condition', 'text'],
        ]) ??
        'Clear';

    final precipProb = normalizeProbability(
      _readDouble(data, [
            ['chance_of_rain'],
          ]) ??
          0.0,
    );

    final windSpeedKph = _readDouble(data, [
          ['wind_kph'],
        ]) ??
        0.0;

    final windDir = _readInt(data, [
      ['wind_degree'],
    ]);
    final uvIndex = _readInt(data, [
      ['uv'],
      ['uv_index'],
    ]);
    final visibilityKm = _readDistanceKm(
      data,
      valuePaths: [
        ['vis_km'],
        ['visibility'],
      ],
      unitPaths: const [],
    );

    return HourlyWeather(
      time: time,
      tempC: tempC,
      feelsLikeC: feelsC,
      precipProbability: precipProb,
      condition: condition,
      windSpeedKph: windSpeedKph,
      windDirectionDegrees: windDir,
      precipMm: _readDouble(data, [
        ['precip_mm'],
      ]),
      uvIndex: uvIndex,
      visibilityKm: visibilityKm,
    );
  }

  DailyWeather? _parseGoogleDaily(Map<String, dynamic> data) {
    final interval = data['interval'];
    final intervalStart =
        interval is Map<String, dynamic> ? interval['startTime'] : null;
    final timeString = intervalStart ??
        data['displayDate'] ??
        data['forecastTime'] ??
        data['forecastDate'] ??
        data['date'] ??
        data['time'] ??
        data['startTime'];
    final date = _parseTime(timeString);
    if (date == null) return null;

    final maxTemp = _readTemperatureC(
      data,
      valuePaths: [
        ['maxTemperature', 'degrees'],
        ['maxTemperature', 'value'],
        ['temperatureMax', 'degrees'],
        ['temperatureMax', 'value'],
        ['temperature', 'max', 'degrees'],
        ['temperature', 'max', 'value'],
        ['temp', 'max'],
        ['temp_max'],
      ],
      unitPaths: [
        ['maxTemperature', 'unit'],
        ['temperatureMax', 'unit'],
        ['temperature', 'max', 'unit'],
      ],
    );
    final minTemp = _readTemperatureC(
      data,
      valuePaths: [
        ['minTemperature', 'degrees'],
        ['minTemperature', 'value'],
        ['temperatureMin', 'degrees'],
        ['temperatureMin', 'value'],
        ['temperature', 'min', 'degrees'],
        ['temperature', 'min', 'value'],
        ['temp', 'min'],
        ['temp_min'],
      ],
      unitPaths: [
        ['minTemperature', 'unit'],
        ['temperatureMin', 'unit'],
        ['temperature', 'min', 'unit'],
      ],
    );

    if (maxTemp == null || minTemp == null) return null;

    final condition = _readString(data, [
          ['weatherCondition', 'description'],
          ['weatherCondition', 'description', 'text'],
          ['weatherCondition', 'type'],
          ['condition', 'text'],
        ]) ??
        'Clear';

    final precipProb = normalizeProbability(
      _readDouble(data, [
            ['precipitationProbability'],
            ['precipitation', 'probability'],
            ['precipitation', 'probability', 'value'],
            ['precipitation', 'probability', 'percent'],
            ['precipProbability'],
          ]) ??
          0.0,
    );

    final daytime = data['daytimeForecast'];
    final dayRoot =
        daytime is Map<String, dynamic> ? daytime : data;
    final dayCondition = _readString(dayRoot, [
          ['weatherCondition', 'description'],
          ['weatherCondition', 'description', 'text'],
          ['weatherCondition', 'type'],
          ['condition', 'text'],
        ]) ??
        condition;
    final dayPrecipProb = normalizeProbability(
      _readDouble(dayRoot, [
            ['precipitation', 'probability'],
            ['precipitation', 'probability', 'percent'],
            ['precipitationProbability'],
            ['precipProbability'],
          ]) ??
          precipProb,
    );
    final dayPrecipMm = _readDouble(dayRoot, [
      ['precipitation', 'qpf', 'value'],
      ['precipitation', 'qpf', 'quantity'],
      ['precipitation', 'value'],
    ]);
    final sunEvents = data['sunEvents'];
    final sunRoot = sunEvents is Map<String, dynamic> ? sunEvents : null;
    final sunriseTime = _parseTime(
      sunRoot?['sunriseTime'] ?? data['sunriseTime'] ?? data['sunrise'],
    );
    final sunsetTime = _parseTime(
      sunRoot?['sunsetTime'] ?? data['sunsetTime'] ?? data['sunset'],
    );

    return DailyWeather(
      date: DateTime(date.year, date.month, date.day),
      minTempC: minTemp,
      maxTempC: maxTemp,
      precipProbability: dayPrecipProb,
      condition: dayCondition,
      precipMm: dayPrecipMm,
      sunriseTime: sunriseTime,
      sunsetTime: sunsetTime,
    );
  }

  DailyWeather? _parseOpenWeatherDaily(Map<String, dynamic> data) {
    final date = _parseUnixTime(data['dt']);
    if (date == null) return null;

    final temp = data['temp'];
    if (temp is! Map<String, dynamic>) return null;

    final maxTemp = _toCelsius(
      _readDouble(temp, [
            ['max'],
          ]) ??
          0.0,
    );
    final minTemp = _toCelsius(
      _readDouble(temp, [
            ['min'],
          ]) ??
          0.0,
    );

    final condition = _readString(data, [
          ['weather', 0, 'description'],
        ]) ??
        'Clear';

    final precipProb = normalizeProbability(
      _readDouble(data, [
            ['pop'],
          ]) ??
          0.0,
    );
    final sunriseTime = _parseUnixTime(data['sunrise']);
    final sunsetTime = _parseUnixTime(data['sunset']);

    return DailyWeather(
      date: DateTime(date.year, date.month, date.day),
      minTempC: minTemp,
      maxTempC: maxTemp,
      precipProbability: precipProb,
      condition: condition,
      precipMm: _readDouble(data, [
        ['rain'],
      ]),
      sunriseTime: sunriseTime,
      sunsetTime: sunsetTime,
    );
  }

  DailyWeather? _parseWeatherApiDaily(Map<String, dynamic> data) {
    final date = _parseTime(data['date']);
    if (date == null) return null;

    final day = data['day'];
    if (day is! Map<String, dynamic>) return null;

    final maxTemp = _readDouble(day, [
          ['maxtemp_c'],
        ]) ??
        0.0;
    final minTemp = _readDouble(day, [
          ['mintemp_c'],
        ]) ??
        0.0;

    final condition = _readString(day, [
          ['condition', 'text'],
        ]) ??
        'Clear';

    final precipProb = normalizeProbability(
      _readDouble(day, [
            ['daily_chance_of_rain'],
          ]) ??
          0.0,
    );
    final astro = data['astro'];
    final astroRoot = astro is Map<String, dynamic> ? astro : null;
    final sunriseTime = _parseTime(astroRoot?['sunrise']);
    final sunsetTime = _parseTime(astroRoot?['sunset']);

    return DailyWeather(
      date: DateTime(date.year, date.month, date.day),
      minTempC: minTemp,
      maxTempC: maxTemp,
      precipProbability: precipProb,
      condition: condition,
      precipMm: _readDouble(day, [
        ['totalprecip_mm'],
      ]),
      sunriseTime: sunriseTime,
      sunsetTime: sunsetTime,
    );
  }

  AirQuality? _parseAirQuality(Map<String, dynamic>? data) {
    if (data == null) return null;
    final indexes = data['indexes'];
    if (indexes is! List) return null;

    Map<String, dynamic>? selected;
    for (final entry in indexes) {
      if (entry is Map<String, dynamic>) {
        final code = entry['code'];
        if (code is String && code.toLowerCase() != 'uaqi') {
          selected = entry;
          break;
        }
      }
    }
    selected ??= indexes
        .whereType<Map<String, dynamic>>()
        .firstWhere(
          (entry) =>
              (entry['code'] is String) &&
              (entry['code'] as String).toLowerCase() == 'uaqi',
          orElse: () => {},
        );
    if (selected != null && selected!.isEmpty) {
      selected = null;
    }
    if (selected == null) {
      for (final entry in indexes) {
        if (entry is Map<String, dynamic>) {
          selected = entry;
          break;
        }
      }
    }
    if (selected == null) return null;

    final aqi = _readInt(selected, [
      ['aqi'],
      ['aqiDisplay'],
    ]);
    final category = _readString(selected, [
      ['category'],
    ]);
    final pollutant = _readString(selected, [
      ['dominantPollutant'],
    ]);
    if (aqi == null) return null;

    return AirQuality(
      aqi: aqi,
      category: category ?? 'Unknown',
      dominantPollutant: pollutant,
    );
  }

  Map<String, dynamic> _extractRoot(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];
      if (value is Map<String, dynamic>) return value;
    }
    return data;
  }

  DateTime? _parseTime(dynamic value) {
    if (value is String) {
      try {
        final parsed = DateTime.parse(value);
        return parsed.isUtc ? parsed.toLocal() : parsed;
      } catch (_) {
        return null;
      }
    }
    if (value is Map) {
      final year = _readInt(value, [
        ['year'],
      ]);
      final month = _readInt(value, [
        ['month'],
      ]);
      final day = _readInt(value, [
        ['day'],
      ]);
      if (year == null || month == null || day == null) return null;
      final hour = _readInt(value, [
            ['hour'],
            ['hours'],
          ]) ??
          0;
      final minute = _readInt(value, [
            ['minute'],
            ['minutes'],
          ]) ??
          0;
      final second = _readInt(value, [
            ['second'],
            ['seconds'],
          ]) ??
          0;
      return DateTime(year, month, day, hour, minute, second);
    }
    if (value is int || value is double) {
      return _parseUnixTime(value);
    }
    return null;
  }

  DateTime? _parseUnixTime(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true)
          .toLocal();
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value * 1000).round(),
        isUtc: true,
      ).toLocal();
    }
    return null;
  }

  double? _readTemperatureC(
    dynamic root, {
    required List<List<Object>> valuePaths,
    required List<List<Object>> unitPaths,
  }) {
    final value = _readDouble(root, valuePaths);
    if (value == null) return null;
    final unit = _readString(root, unitPaths);
    return _toCelsius(value, unit: unit);
  }

  double _toCelsius(double value, {String? unit}) {
    final u = (unit ?? '').toLowerCase();
    if (u.contains('f')) return (value - 32) * 5 / 9;
    if (u.contains('k')) return value - 273.15;
    if (value > 150) return value - 273.15;
    return value;
  }

  double? _readSpeedKph(
    dynamic root, {
    required List<List<Object>> valuePaths,
    required List<List<Object>> unitPaths,
    bool assumeMetersPerSecond = false,
  }) {
    final value = _readDouble(root, valuePaths);
    if (value == null) return null;
    final unit = _readString(root, unitPaths)?.toLowerCase() ?? '';
    if (unit.contains('mile') || unit.contains('mph')) {
      return value * 1.60934;
    }
    if (unit.contains('kilometer') || unit.contains('km/h') || unit.contains('kph')) {
      return value;
    }
    if (unit.contains('meter') || unit.contains('m/s')) {
      return value * 3.6;
    }
    if (assumeMetersPerSecond && unit.isEmpty) {
      return value * 3.6;
    }
    return value;
  }

  double? _readDistanceKm(
    dynamic root, {
    required List<List<Object>> valuePaths,
    required List<List<Object>> unitPaths,
  }) {
    final value = _readDouble(root, valuePaths);
    if (value == null) return null;
    final unit = _readString(root, unitPaths)?.toLowerCase() ?? '';
    if (unit.contains('meter') || unit.contains('metre') || unit == 'm') {
      return value / 1000.0;
    }
    if (unit.contains('kilometer') ||
        unit.contains('kilometre') ||
        unit.contains('km')) {
      return value;
    }
    if (unit.isEmpty && value > 1000) {
      return value / 1000.0;
    }
    return value;
  }

  double? _readDouble(dynamic root, List<List<Object>> paths) {
    for (final path in paths) {
      final value = _walkPath(root, path);
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  int? _readInt(dynamic root, List<List<Object>> paths) {
    final value = _readDouble(root, paths);
    if (value == null) return null;
    return value.round();
  }

  String? _readString(dynamic root, List<List<Object>> paths) {
    for (final path in paths) {
      final value = _walkPath(root, path);
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  dynamic _walkPath(dynamic root, List<Object> path) {
    dynamic current = root;
    for (final part in path) {
      if (current is Map && part is String) {
        current = current[part];
      } else if (current is List && part is int) {
        if (part < 0 || part >= current.length) return null;
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }
}
