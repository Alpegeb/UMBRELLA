import 'dart:math' as math;

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

// Umbrella Index: 0-10 outdoor readiness score using current conditions and
// near-term forecast signals.
double weatherQualityIndex(
  CurrentWeather current, {
  double? avgHighC,
  double? avgLowC,
  List<HourlyWeather>? hourly,
  List<DailyWeather>? daily,
  AirQuality? airQuality,
  DateTime? now,
}) {
  final sampleNow = now ?? DateTime.now();
  final hourlyWindow = _upcomingHours(hourly, sampleNow, maxHours: 12);
  final dailyWindow = daily == null
      ? const <DailyWeather>[]
      : upcomingDaily(daily, now: sampleNow, maxDays: 2);
  final computedAvgHigh =
      avgHighC ?? _averageDouble(dailyWindow.map((d) => d.maxTempC));
  final computedAvgLow =
      avgLowC ?? _averageDouble(dailyWindow.map((d) => d.minTempC));
  final idealC = _comfortIdealC(computedAvgHigh, computedAvgLow);
  final thermal = _thermalComfortScore(current.feelsLikeC, idealC);
  final humidity = _humidityScore(current.humidity, current.feelsLikeC);
  final stability = _tempStabilityScore(hourlyWindow, current.tempC);
  final exposure = _thermalExposureScore(current.feelsLikeC);
  final comfortBase =
      (thermal * 0.7) + (humidity * 0.2) + (stability * 0.1);
  final comfort = (comfortBase * exposure).clamp(0.0, 1.0);

  final precipScore = _precipScore(current, hourlyWindow);
  final windScore = _windScore(current, hourlyWindow);
  final uvScore = _uvScore(_peakUvIndex(current.uvIndex, hourlyWindow));
  final visibilityScore =
      _visibilityScore(_minVisibilityKm(current.visibilityKm, hourlyWindow));
  final hazardScore =
      _hazardScoreForecast(current.condition, hourlyWindow, dailyWindow);
  final airScore = _airQualityScore(airQuality);

  final baseScore = (comfort * 0.5) +
      (precipScore * 0.2) +
      (windScore * 0.1) +
      (airScore * 0.07) +
      (uvScore * 0.05) +
      (visibilityScore * 0.04) +
      (hazardScore * 0.04);
  final exposureMultiplier = 0.35 + (0.65 * exposure);
  final adjusted = (baseScore * exposureMultiplier).clamp(0.0, 1.0);
  final spread = math.pow(adjusted, 1.08).toDouble();
  return (spread * 10.0).clamp(0.0, 10.0);
}

double? _averageDouble(Iterable<double> values) {
  double sum = 0.0;
  int count = 0;
  for (final value in values) {
    sum += value;
    count += 1;
  }
  if (count == 0) return null;
  return sum / count;
}

List<HourlyWeather> _upcomingHours(
  List<HourlyWeather>? hourly,
  DateTime now, {
  int maxHours = 12,
}) {
  if (hourly == null || hourly.isEmpty) return const [];
  final upcoming = hourly.where((h) => !h.time.isBefore(now)).toList();
  upcoming.sort((a, b) => a.time.compareTo(b.time));
  return upcoming.take(maxHours).toList();
}

double _tempStabilityScore(List<HourlyWeather> hours, double currentTempC) {
  if (hours.isEmpty) return 0.9;
  double minTemp = currentTempC;
  double maxTemp = currentTempC;
  for (final hour in hours) {
    if (hour.tempC < minTemp) minTemp = hour.tempC;
    if (hour.tempC > maxTemp) maxTemp = hour.tempC;
  }
  final swing = (maxTemp - minTemp).abs();
  final normalized = ((swing - 6.0) / 18.0).clamp(0.0, 1.0);
  return (1.0 - normalized).clamp(0.35, 1.0);
}

double _thermalExposureScore(double feelsLikeC) {
  final cold = 1.0 / (1.0 + math.exp(-(feelsLikeC + 5.0) / 5.0));
  final heat = 1.0 / (1.0 + math.exp((feelsLikeC - 34.0) / 5.0));
  return (cold * heat).clamp(0.0, 1.0);
}

double _comfortIdealC(double? avgHighC, double? avgLowC) {
  if (avgHighC == null || avgLowC == null) return 22.0;
  final seasonalMean = (avgHighC + avgLowC) / 2.0;
  final seasonalIdeal = seasonalMean.clamp(10.0, 28.0);
  return (seasonalIdeal * 0.6) + (22.0 * 0.4);
}

double _thermalComfortScore(double feelsLikeC, double idealC) {
  final delta = (feelsLikeC - idealC).abs();
  const sigma = 9.0;
  final exponent = -(delta * delta) / (2 * sigma * sigma);
  return math.exp(exponent).clamp(0.0, 1.0);
}

double _humidityScore(double? humidity, double feelsLikeC) {
  if (humidity == null) return 0.9;
  final pct = (humidity * 100).clamp(0.0, 100.0);
  final distance = (pct - 50).abs();
  final base = (1.0 - (distance / 60.0)).clamp(0.5, 1.0);
  if (pct > 70 && feelsLikeC >= 24) {
    final extra = (pct - 70) / 30.0;
    return (base - (extra * 0.2)).clamp(0.4, 1.0);
  }
  if (pct < 25 && feelsLikeC <= 10) {
    return (base - 0.08).clamp(0.4, 1.0);
  }
  return base;
}

double _precipScore(CurrentWeather current, List<HourlyWeather> hours) {
  final currentRisk =
      _precipRisk(current.precipProbability, current.precipMm);
  final forecastRisk = _forecastPrecipRisk(hours);
  final risk = forecastRisk == null
      ? currentRisk
      : ((currentRisk * 0.35) + (forecastRisk * 0.65));
  final softened = math.pow(risk, 1.1).toDouble();
  return (1.0 - softened).clamp(0.0, 1.0);
}

double _precipRisk(double probability, double? precipMm) {
  final pop = normalizeProbability(probability);
  final amountImpact = _precipAmountImpact(precipMm);
  return ((pop * 0.65) + (amountImpact * 0.35)).clamp(0.0, 1.0);
}

double? _forecastPrecipRisk(List<HourlyWeather> hours) {
  if (hours.isEmpty) return null;
  double weighted = 0.0;
  double weights = 0.0;
  double peak = 0.0;
  for (int i = 0; i < hours.length; i++) {
    final risk = _precipRisk(
      hours[i].precipProbability,
      hours[i].precipMm,
    );
    final weight = math.exp(-i / 4.0);
    weighted += risk * weight;
    weights += weight;
    if (risk > peak) peak = risk;
  }
  final avg = weights == 0 ? 0.0 : weighted / weights;
  return ((avg * 0.65) + (peak * 0.35)).clamp(0.0, 1.0);
}

double _precipAmountImpact(double? precipMm) {
  if (precipMm == null) return 0.0;
  if (precipMm <= 0.2) return 0.0;
  if (precipMm <= 1.0) return 0.2;
  if (precipMm <= 4.0) return 0.5;
  if (precipMm <= 10.0) return 0.8;
  return 1.0;
}

double _windScore(CurrentWeather current, List<HourlyWeather> hours) {
  final currentEffective =
      _effectiveWind(current.windSpeedKph, current.windGustKph);
  double maxForecast = currentEffective;
  double sum = current.windSpeedKph;
  int count = 1;
  for (final hour in hours) {
    if (hour.windSpeedKph > maxForecast) {
      maxForecast = hour.windSpeedKph;
    }
    sum += hour.windSpeedKph;
    count += 1;
  }
  final avg = sum / count;
  final effective = (avg * 0.6) + (maxForecast * 0.4);
  final blended = math.max((currentEffective * 0.4) + (effective * 0.6),
      currentEffective);
  final x = (blended - 24.0) / 6.0;
  return (1.0 / (1.0 + math.exp(x))).clamp(0.0, 1.0);
}

double _effectiveWind(double windSpeedKph, double windGustKph) {
  if (windGustKph <= windSpeedKph) return windSpeedKph;
  return (windSpeedKph * 0.7) + (windGustKph * 0.3);
}

int? _peakUvIndex(int? currentUv, List<HourlyWeather> hours) {
  int? peak = currentUv;
  for (final hour in hours) {
    final uv = hour.uvIndex;
    if (uv == null) continue;
    if (peak == null || uv > peak) peak = uv;
  }
  return peak;
}

double _uvScore(int? uvIndex) {
  if (uvIndex == null) return 0.9;
  if (uvIndex <= 2) return 1.0;
  if (uvIndex <= 5) return 0.9;
  if (uvIndex <= 7) return 0.78;
  if (uvIndex <= 10) return 0.6;
  return 0.45;
}

double? _minVisibilityKm(double? currentVisibility, List<HourlyWeather> hours) {
  double? minVisibility = currentVisibility;
  for (final hour in hours) {
    final vis = hour.visibilityKm;
    if (vis == null) continue;
    if (minVisibility == null || vis < minVisibility) {
      minVisibility = vis;
    }
  }
  return minVisibility;
}

double _visibilityScore(double? visibilityKm) {
  if (visibilityKm == null) return 0.9;
  if (visibilityKm >= 10) return 1.0;
  if (visibilityKm >= 6) return 0.85;
  if (visibilityKm >= 3) return 0.7;
  if (visibilityKm >= 1) return 0.5;
  return 0.3;
}

double _hazardScoreForecast(
  String currentCondition,
  List<HourlyWeather> hours,
  List<DailyWeather> daily,
) {
  double worst = _hazardScore(currentCondition);
  for (final hour in hours) {
    final score = _hazardScore(hour.condition);
    if (score < worst) worst = score;
  }
  for (final day in daily) {
    final score = _hazardScore(day.condition);
    if (score < worst) worst = score;
  }
  return worst;
}

double _hazardScore(String condition) {
  final c = condition.toLowerCase();
  if (c.contains('thunder') || c.contains('storm')) return 0.4;
  if (c.contains('hail') || c.contains('sleet')) return 0.55;
  if (c.contains('snow')) return 0.6;
  if (c.contains('fog') || c.contains('mist') || c.contains('haze')) {
    return 0.7;
  }
  return 1.0;
}

double _airQualityScore(AirQuality? airQuality) {
  final aqi = airQuality?.aqi;
  if (aqi == null) return 0.9;
  if (aqi <= 50) return 1.0;
  if (aqi <= 100) return 0.85;
  if (aqi <= 150) return 0.7;
  if (aqi <= 200) return 0.55;
  if (aqi <= 300) return 0.4;
  return 0.3;
}

String weatherQualityCaption(double idx, {double? feelsLikeC}) {
  final cold = feelsLikeC != null && feelsLikeC <= 10;
  final cool = feelsLikeC != null && feelsLikeC > 10 && feelsLikeC <= 16;
  final warm = feelsLikeC != null && feelsLikeC >= 26;
  final hot = feelsLikeC != null && feelsLikeC >= 30;

  if (idx >= 9.0) {
    if (cold) return "Crisp and clear — bundle up and enjoy it.";
    if (hot) return "Glorious but hot — shade and water help.";
    return "A day you want to bottle — clear, calm, and easy.";
  }
  if (idx >= 7.5) {
    if (cold) return "Bright but chilly — a warm layer helps.";
    if (warm) return "Warm and steady — hydrate if you're out.";
    return "Comfortable and bright — great for being outside.";
  }
  if (idx >= 6.0) {
    if (cold) return "Cool but calm — a warm layer is the move.";
    if (cool) return "Cool and decent — a light jacket works.";
    if (warm) return "Warm with a bit of edge — take water along.";
    return "Pretty decent — a light layer might be enough.";
  }
  if (idx >= 4.5) {
    if (cold) return "Chilly or mixed — dress for quick stops.";
    return "Mixed bag — fine for errands, less for long hangs.";
  }
  if (idx >= 3.0) {
    if (cold) return "Cold and blustery — bundle up if you head out.";
    return "Blustery or damp — take it slow out there.";
  }
  return cold
      ? "Cold and rough — cozy plans feel right."
      : "Rough weather today — cozy plans feel right.";
}

String weatherQualityInsight(
  double idx, {
  required bool isNight,
  double? feelsLikeC,
}) {
  final cold = feelsLikeC != null && feelsLikeC <= 10;
  final cool = feelsLikeC != null && feelsLikeC > 10 && feelsLikeC <= 16;
  final warm = feelsLikeC != null && feelsLikeC >= 26;
  final hot = feelsLikeC != null && feelsLikeC >= 30;

  if (idx >= 9.0) {
    if (cold) {
      return isNight
          ? "Clear, crisp night — dress warm if you head out."
          : "Clear and crisp — bundle up if you're stepping out.";
    }
    if (hot) {
      return isNight
          ? "Warm, calm night — take it easy and stay hydrated."
          : "Bright and hot — shade and water make it nicer.";
    }
    return isNight
        ? "Clear night and calm air — a great time for a walk."
        : "Clear, calm, and comfortable — if you can, get outside.";
  }
  if (idx >= 7.5) {
    if (cold) {
      return isNight
          ? "Chilly night but calm — a warm layer goes a long way."
          : "Bright but chilly — a warm layer makes it easy.";
    }
    if (warm) {
      return isNight
          ? "Warm night air and calm winds — easy evening plans."
          : "Warm and steady — hydrate if you're out for long.";
    }
    return isNight
        ? "Mild night air with little fuss — easy evening plans."
        : "Comfortable air and steady skies — a solid day to be out.";
  }
  if (idx >= 6.0) {
    if (cold) {
      return isNight
          ? "Mostly fine tonight — still chilly, so layer up."
          : "Mostly fine today — still chilly, so layer up.";
    }
    if (cool) {
      return isNight
          ? "Mostly fine tonight — a light jacket should do."
          : "Mostly fine today — a light jacket should do.";
    }
    return isNight
        ? "Mostly fine tonight — a light layer should do."
        : "Mostly fine today — a light layer should do.";
  }
  if (idx >= 4.5) {
    return isNight
        ? "A bit unsettled tonight — keep plans flexible."
        : "A bit unsettled — quick plans are the sweet spot.";
  }
  if (idx >= 3.0) {
    return isNight
        ? "Wind or damp air — wrap up if you head out."
        : "Wind or damp air — not the coziest day outside.";
  }
  return isNight
      ? "Tough night weather — a cozy indoor plan sounds good."
      : "Tough weather — indoor plans might feel better.";
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
