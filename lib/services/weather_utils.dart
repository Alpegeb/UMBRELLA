import 'weather_models.dart';
import 'weather_units.dart';

double normalizeProbability(double value) {
  if (value.isNaN) return 0.0;
  if (value > 1.0) return (value / 100.0).clamp(0.0, 1.0);
  return value.clamp(0.0, 1.0);
}

String displayCondition(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 'Unknown';

  final upper = trimmed.toUpperCase();
  if (upper == 'UNKNOWN' ||
      upper == 'UNSPECIFIED' ||
      upper == 'WEATHER_CONDITION_TYPE_UNSPECIFIED') {
    return 'Unknown';
  }

  var cleaned = trimmed
      .replaceAll('WEATHER_CONDITION_', '')
      .replaceAll('CONDITION_', '');

  final needsFormatting = cleaned.contains('_') ||
      cleaned.contains('-') ||
      cleaned.toUpperCase() == cleaned;

  if (!needsFormatting) return cleaned;

  cleaned = cleaned
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .toLowerCase();
  final words = cleaned.split(' ').where((w) => w.isNotEmpty);
  final titled = words
      .map((w) => w.length <= 1 ? w.toUpperCase() : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
  return titled.isEmpty ? 'Unknown' : titled;
}

double umbrellaIndex(CurrentWeather current) {
  final precip = normalizeProbability(current.precipProbability);
  final wind = (current.windSpeedKph / 50.0).clamp(0.0, 1.0);
  final gust = (current.windGustKph / 70.0).clamp(0.0, 1.0);
  final score = (precip * 7.0) + (wind * 2.0) + (gust * 1.0);
  return score.clamp(0.0, 10.0);
}

String summaryText(CurrentWeather current, {required bool windInKph}) {
  final precipPct =
      (normalizeProbability(current.precipProbability) * 100).round();
  final gust = windValue(current.windGustKph, windInKph).round();
  final unit = windInKph ? 'km/h' : 'mph';

  String precipPhrase;
  if (precipPct >= 70) {
    precipPhrase = 'Rain likely';
  } else if (precipPct >= 40) {
    precipPhrase = 'Showers possible';
  } else if (precipPct >= 20) {
    precipPhrase = 'Brief sprinkles possible';
  } else {
    precipPhrase = 'Dry spells expected';
  }

  final condition = displayCondition(current.condition);
  return '$condition. $precipPhrase. Gusts up to $gust $unit.';
}

String windDirectionLabel(int degrees) {
  const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  final idx = ((degrees % 360) / 45).round() % dirs.length;
  return dirs[idx];
}

String temperatureComfortText(
  double tempC, {
  DateTime? now,
  DateTime? sunrise,
  DateTime? sunset,
}) {
  final isNight = _isNightTime(
    now ?? DateTime.now(),
    sunrise: sunrise,
    sunset: sunset,
  );
  if (tempC <= 0) return 'Freezing conditions. Dress in layers.';
  if (tempC < 8) return 'Cold air outside. A warm jacket will feel better.';
  if (tempC < 16) return 'Cool and steady. A light jacket is a good match.';
  if (tempC < 24) {
    return isNight
        ? 'Mild night air — a light layer should be enough.'
        : 'Mild and pleasant. Nice weather for a walk.';
  }
  if (tempC < 30) {
    return isNight
        ? 'Warm night ahead. Keep water nearby.'
        : 'Warm and bright. Hydrate and take breaks.';
  }
  return isNight
      ? 'Hot night ahead. Keep cool indoors if possible.'
      : 'Hot conditions. Shade and water will help.';
}

String skyInsightText(
  String condition, {
  DateTime? now,
  DateTime? sunrise,
  DateTime? sunset,
}) {
  final c = condition.toLowerCase();
  final isNight = _isNightTime(
    now ?? DateTime.now(),
    sunrise: sunrise,
    sunset: sunset,
  );

  if (c.contains('rain') || c.contains('storm')) {
    return isNight
        ? 'Rain tonight could slow late plans. Give yourself extra time.'
        : 'Rain could slow outdoor plans. A quick backup helps.';
  }
  if (c.contains('cloud') || c.contains('overcast')) {
    return isNight
        ? 'Cloudy night skies keep things calm and dim.'
        : 'Cloudy skies reduce glare, which can feel easier on the eyes.';
  }
  if (c.contains('sun') || c.contains('clear')) {
    return isNight
        ? 'Clear skies tonight improve visibility for late plans.'
        : 'Bright skies boost mood and visibility outdoors.';
  }
  return isNight
      ? 'Changing skies tonight — keep plans flexible.'
      : 'Mixed skies today — a flexible plan works best.';
}

bool _isNightTime(
  DateTime now, {
  DateTime? sunrise,
  DateTime? sunset,
}) {
  if (sunrise != null && sunset != null) {
    return now.isBefore(sunrise) || now.isAfter(sunset);
  }
  return now.hour < 6 || now.hour >= 18;
}

String humidityInsightText(double? humidity) {
  if (humidity == null) return 'Humidity data is unavailable right now.';
  final pct = (humidity * 100).round();
  if (pct < 35) return 'Dry air ($pct%). Water and lip balm help.';
  if (pct < 60) return 'Comfortable humidity ($pct%). Easy breathing today.';
  if (pct < 80) return 'Humid air ($pct%). Light layers feel better.';
  return 'Very humid ($pct%). Go easy and stay hydrated.';
}

DailyWeather? dailyForDate(List<DailyWeather> daily, DateTime date) {
  if (daily.isEmpty) return null;
  final target = DateTime(date.year, date.month, date.day);
  for (final day in daily) {
    final d = DateTime(day.date.year, day.date.month, day.date.day);
    if (d == target) return day;
  }
  return null;
}

List<DailyWeather> upcomingDaily(
  List<DailyWeather> daily, {
  DateTime? now,
  int maxDays = 5,
}) {
  if (daily.isEmpty) return [];
  final sorted = [...daily]..sort((a, b) => a.date.compareTo(b.date));
  if (now == null) return sorted.take(maxDays).toList();

  final start = DateTime(now.year, now.month, now.day);
  final filtered = sorted
      .where((d) => !DateTime(d.date.year, d.date.month, d.date.day)
          .isBefore(start))
      .toList();
  if (filtered.length >= maxDays) {
    return filtered.take(maxDays).toList();
  }
  if (sorted.length >= maxDays) {
    return sorted.take(maxDays).toList();
  }
  return filtered.isNotEmpty ? filtered : sorted;
}

({double highC, double lowC})? highLowForDate(
  List<DailyWeather> daily,
  List<HourlyWeather> hourly,
  DateTime date,
) {
  final day = dailyForDate(daily, date);
  if (day != null) {
    return (highC: day.maxTempC, lowC: day.minTempC);
  }

  final target = DateTime(date.year, date.month, date.day);
  final hours = hourly
      .where((h) =>
          DateTime(h.time.year, h.time.month, h.time.day) == target)
      .toList();
  if (hours.isEmpty) return null;

  double minTemp = hours.first.tempC;
  double maxTemp = hours.first.tempC;
  for (final hour in hours) {
    if (hour.tempC < minTemp) minTemp = hour.tempC;
    if (hour.tempC > maxTemp) maxTemp = hour.tempC;
  }
  return (highC: maxTemp, lowC: minTemp);
}

List<DateTime> dayHours(DateTime date) {
  final start = DateTime(date.year, date.month, date.day);
  return List.generate(24, (i) => start.add(Duration(hours: i)));
}

List<HourlyWeather?> hourlySeriesForDay({
  required List<HourlyWeather> history,
  required List<HourlyWeather> forecast,
  required CurrentWeather current,
  required DateTime date,
}) {
  final start = DateTime(date.year, date.month, date.day);
  final now = DateTime.now();

  final Map<int, HourlyWeather> historyMap = {};
  for (final hour in history) {
    if (_sameDay(hour.time, start)) {
      historyMap[hour.time.hour] = hour;
    }
  }

  final Map<int, HourlyWeather> forecastMap = {};
  for (final hour in forecast) {
    if (_sameDay(hour.time, start)) {
      forecastMap[hour.time.hour] = hour;
    }
  }

  final List<HourlyWeather?> series = [];
  for (int i = 0; i < 24; i++) {
    final slotTime = start.add(Duration(hours: i));
    final isPast = !slotTime.isAfter(now);
    HourlyWeather? item = isPast
        ? historyMap[i] ?? forecastMap[i]
        : forecastMap[i] ?? historyMap[i];
    if (item == null && _sameDay(slotTime, now) && slotTime.hour == now.hour) {
      item = _fromCurrent(current, slotTime);
    }
    series.add(item);
  }
  return series;
}

HourlyWeather _fromCurrent(CurrentWeather current, DateTime time) {
  return HourlyWeather(
    time: time,
    tempC: current.tempC,
    feelsLikeC: current.feelsLikeC,
    precipProbability: current.precipProbability,
    condition: current.condition,
    windSpeedKph: current.windSpeedKph,
    windDirectionDegrees: current.windDirectionDegrees,
    precipMm: current.precipMm,
    uvIndex: current.uvIndex,
    visibilityKm: current.visibilityKm,
  );
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
