double tempValue(double celsius, bool useCelsius) {
  if (useCelsius) return celsius;
  return (celsius * 9 / 5) + 32;
}

String tempLabel(double celsius, bool useCelsius) {
  return '${tempValue(celsius, useCelsius).round()}°';
}

double windValue(double kph, bool useKph) {
  if (useKph) return kph;
  return kph / 1.60934;
}

String windLabel(double kph, bool useKph) {
  final unit = useKph ? 'km/h' : 'mph';
  return '${windValue(kph, useKph).round()} $unit';
}
