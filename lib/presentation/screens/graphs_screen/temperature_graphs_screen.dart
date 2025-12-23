import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../providers/settings_state.dart';
import '../../../providers/weather_state.dart';
import '../../../services/weather_models.dart';
import '../../../services/weather_utils.dart';
import '../../../services/weather_units.dart';

class TemperatureGraphsScreen extends StatefulWidget {
  const TemperatureGraphsScreen({
    super.key,
    required this.appTheme,
    this.initialMode = TempMode.actualVsFeels,
  });

  final AppTheme appTheme;
  final TempMode initialMode;

  @override
  State<TemperatureGraphsScreen> createState() =>
      _TemperatureGraphsScreenState();
}

class _TemperatureGraphsScreenState extends State<TemperatureGraphsScreen> {
  late TempMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.appTheme;
    final weather = context.watch<WeatherState>();
    final settings = context.watch<SettingsState>();
    final useCelsius = settings.useCelsius;
    final snapshot = weather.snapshot;
    final showPlaceholder = snapshot.isFallback;
    final dayTimes = dayHours(DateTime.now());
    final slots = showPlaceholder
        ? <HourlyWeather?>[]
        : hourlySeriesForDay(
            history: snapshot.historyHourly,
            forecast: snapshot.hourly,
            current: snapshot.current,
            date: DateTime.now(),
          );
    final actual = slots
        .map((h) => h == null ? null : tempValue(h.tempC, useCelsius))
        .toList();
    final feels = slots
        .map((h) => h == null ? null : tempValue(h.feelsLikeC, useCelsius))
        .toList();
    final times = dayTimes;
    final currentTemp = showPlaceholder
        ? null
        : tempValue(snapshot.current.tempC, useCelsius);
    final range = showPlaceholder
        ? null
        : highLowForDate(
            snapshot.daily,
            snapshot.hourly,
            DateTime.now(),
          );
    final high =
        range != null ? tempValue(range.highC, useCelsius) : null;
    final low = range != null ? tempValue(range.lowC, useCelsius) : null;
    final timeLabels = _buildTimeLabels(dayTimes);
    final unitLabel = useCelsius ? "°C" : "°F";

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.bg,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.text),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Temperature Graphs',
          style: TextStyle(
            color: theme.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: _TemperatureCard(
                  theme: theme,
                  mode: _mode,
                  onModeChanged: (m) => setState(() => _mode = m),
                  actual: actual,
                  feels: feels,
                  times: times,
                  unitLabel: unitLabel,
                  currentTemp: currentTemp,
                  high: high,
                  low: low,
                  condition: showPlaceholder
                      ? "--"
                      : displayCondition(snapshot.current.condition),
                  conditionIcon: showPlaceholder
                      ? Icons.cloud_queue
                      : _iconForCondition(snapshot.current.condition),
                  timeLabels: timeLabels,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This screen presents the temperature forecast with options '
                    'to view both “Actual” and “Feels like” values. The graph '
                    'shows daily fluctuations and highlights the warmest period.',
                style: TextStyle(
                  color: theme.sub,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum TempMode { actualOnly, actualVsFeels }

class _TemperatureCard extends StatefulWidget {
  const _TemperatureCard({
    required this.theme,
    required this.mode,
    required this.onModeChanged,
    required this.actual,
    required this.feels,
    required this.times,
    required this.unitLabel,
    required this.currentTemp,
    required this.high,
    required this.low,
    required this.condition,
    required this.conditionIcon,
    required this.timeLabels,
  });

  final AppTheme theme;
  final TempMode mode;
  final ValueChanged<TempMode> onModeChanged;
  final List<double?> actual;
  final List<double?> feels;
  final List<DateTime> times;
  final String unitLabel;
  final double? currentTemp;
  final double? high;
  final double? low;
  final String condition;
  final IconData conditionIcon;
  final List<String> timeLabels;

  @override
  State<_TemperatureCard> createState() => _TemperatureCardState();
}

class _TemperatureCardState extends State<_TemperatureCard> {
  int? _activeIndex;

  void _setActive(Offset local, double width, int count) {
    if (count < 2) return;
    final clamped = local.dx.clamp(0.0, width);
    final idx = ((clamped / width) * (count - 1)).round();
    setState(() => _activeIndex = idx.clamp(0, count - 1).toInt());
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final minCount = math.min(widget.actual.length, widget.times.length);
    final actualValues =
        minCount >= 2 ? widget.actual.take(minCount).toList() : <double?>[];
    final feelsValues = widget.feels.length >= minCount
        ? widget.feels.take(minCount).toList()
        : <double?>[];
    final showFeels = widget.mode == TempMode.actualVsFeels;
    final currentText =
        widget.currentTemp == null ? "--" : '${widget.currentTemp!.round()}°';
    final hiLoText = widget.high != null && widget.low != null
        ? 'H: ${widget.high!.round()}°  L: ${widget.low!.round()}°'
        : 'H: --  L: --';
    final unitLabel = widget.unitLabel;
    final hasData =
        actualValues.where((v) => v != null).length >= 2;

    return Container(
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Theme(
        data: theme.materialTheme,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.conditionIcon, size: 18, color: theme.sunny),
                const SizedBox(width: 8),
                Text(
                  widget.condition,
                  style: TextStyle(
                    color: theme.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  "Temp ($unitLabel)",
                  style: TextStyle(color: theme.sub, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currentText,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    hiLoText,
                    style: TextStyle(
                      color: theme.sub,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (!hasData) {
                      return Center(
                        child: Text(
                          "Forecast data unavailable",
                          style: TextStyle(color: theme.sub, fontSize: 12),
                        ),
                      );
                    }
                    final count = actualValues.length;
                    final times = widget.times.take(count).toList();
                    final scale = _ChartScale.fromSeries(
                      values: actualValues,
                      compare: showFeels ? feelsValues : null,
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    );
                    final pastIndex =
                        _lastPastIndex(times, DateTime.now());
                    final currentIndex =
                        _currentIndex(times, DateTime.now());
                    final activeIndex = (_activeIndex ?? currentIndex) == null
                        ? null
                        : (_activeIndex ?? currentIndex)!
                            .clamp(0, count - 1)
                            .toInt();

                    return GestureDetector(
                      onTapDown: (details) => _setActive(
                        details.localPosition,
                        constraints.maxWidth,
                        count,
                      ),
                      onPanDown: (details) => _setActive(
                        details.localPosition,
                        constraints.maxWidth,
                        count,
                      ),
                      onPanUpdate: (details) => _setActive(
                        details.localPosition,
                        constraints.maxWidth,
                        count,
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _TempChartPainter(
                                actual: actualValues,
                                feelsLike:
                                    showFeels ? feelsValues : null,
                                actualColor: theme.sunny,
                                actualPastColor:
                                    theme.sunny.withValues(alpha: 0.45),
                                feelsColor: theme.sub,
                                feelsPastColor:
                                    theme.sub.withValues(alpha: 0.35),
                                gridColor:
                                    theme.border.withValues(alpha: 0.25),
                                scale: scale,
                                pastIndex: pastIndex,
                                activeIndex: activeIndex,
                              ),
                            ),
                          ),
                          if (activeIndex != null)
                            _TempTooltip(
                              theme: theme,
                              scale: scale,
                              index: activeIndex,
                              time: times[activeIndex],
                              actual: actualValues[activeIndex],
                              feels: showFeels && feelsValues.length > activeIndex
                                  ? feelsValues[activeIndex]
                                  : null,
                              unitLabel: unitLabel,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final label in widget.timeLabels)
                  Text(label, style: TextStyle(color: theme.sub, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: theme.cardAlt,
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onModeChanged(TempMode.actualOnly),
                      child: _SegmentPill(
                        label: 'Actual',
                        active: widget.mode == TempMode.actualOnly,
                        theme: theme,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          widget.onModeChanged(TempMode.actualVsFeels),
                      child: _SegmentPill(
                        label: 'Feels Like',
                        active: widget.mode == TempMode.actualVsFeels,
                        theme: theme,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.mode == TempMode.actualVsFeels
                  ? 'Perceived temperature vs actual values.'
                  : 'The actual temperature over the day.',
              style: TextStyle(
                color: theme.sub,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  const _SegmentPill({
    required this.label,
    required this.active,
    required this.theme,
  });

  final String label;
  final bool active;
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: active ? theme.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : theme.sub,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChartScale {
  _ChartScale({
    required this.minValue,
    required this.maxValue,
    required this.midValue,
    required this.rect,
    required this.size,
    required this.count,
  }) : stepX = count > 1 ? rect.width / (count - 1) : 0;

  final double minValue;
  final double maxValue;
  final double midValue;
  final Rect rect;
  final Size size;
  final int count;
  final double stepX;

  factory _ChartScale.fromSeries({
    required List<double?> values,
    List<double?>? compare,
    required Size size,
  }) {
    final all = [
      ...values.whereType<double>(),
      if (compare != null) ...compare.whereType<double>(),
    ];
    if (all.isEmpty) {
      return _ChartScale(
        minValue: 0,
        maxValue: 1,
        midValue: 0.5,
        rect: Rect.fromLTWH(0, 0, size.width, size.height),
        size: size,
        count: values.length,
      );
    }
    double minVal = all.reduce(math.min);
    double maxVal = all.reduce(math.max);
    final span = (maxVal - minVal).abs();
    if (span < 1e-3) {
      minVal -= 1.0;
      maxVal += 1.0;
    } else {
      final pad = math.max(1.0, span * 0.12);
      minVal -= pad;
      maxVal += pad;
    }
    final midValue = (minVal + maxVal) / 2;
    const horizontalPadding = 6.0;
    const verticalPadding = 10.0;
    final width = math.max(0.0, size.width - horizontalPadding * 2);
    final height = math.max(0.0, size.height - verticalPadding * 2);
    final rect = Rect.fromLTWH(
      horizontalPadding,
      verticalPadding,
      width,
      height,
    );
    return _ChartScale(
      minValue: minVal,
      maxValue: maxVal,
      midValue: midValue,
      rect: rect,
      size: size,
      count: values.length,
    );
  }

  double xForIndex(int index) => rect.left + stepX * index;

  double yForValue(double value) {
    final span = (maxValue - minValue).abs();
    final t = span < 1e-6 ? 0.5 : ((value - minValue) / span);
    return rect.bottom - t * rect.height;
  }
}

class _TempTooltip extends StatelessWidget {
  const _TempTooltip({
    required this.theme,
    required this.scale,
    required this.index,
    required this.time,
    required this.actual,
    required this.feels,
    required this.unitLabel,
  });

  final AppTheme theme;
  final _ChartScale scale;
  final int index;
  final DateTime time;
  final double? actual;
  final double? feels;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final timeLabel = _formatTime(time);
    final actualText = actual == null ? '--' : '${actual!.round()}$unitLabel';
    final feelsText = feels == null ? null : '${feels!.round()}$unitLabel';
    final tooltipWidth = feelsText == null ? 110.0 : 130.0;
    final tooltipHeight = feelsText == null ? 54.0 : 70.0;

    final anchorValue = actual ?? feels ?? scale.midValue;
    final point = Offset(
      scale.xForIndex(index),
      scale.yForValue(anchorValue),
    );
    final left = (point.dx - tooltipWidth / 2)
        .clamp(6.0, scale.size.width - tooltipWidth - 6.0)
        .toDouble();
    final top = (point.dy - tooltipHeight - 10)
        .clamp(6.0, scale.size.height - tooltipHeight - 6.0)
        .toDouble();

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: tooltipWidth,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardAlt.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timeLabel,
              style: TextStyle(
                color: theme.sub,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.sunny,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Actual $actualText',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (feelsText != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.sub,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Feels $feelsText',
                    style: TextStyle(
                      color: theme.sub,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TempChartPainter extends CustomPainter {
  _TempChartPainter({
    required this.actual,
    required this.actualColor,
    required this.actualPastColor,
    required this.gridColor,
    required this.scale,
    required this.pastIndex,
    required this.activeIndex,
    this.feelsLike,
    this.feelsColor,
    this.feelsPastColor,
  });

  final List<double?> actual;
  final List<double?>? feelsLike;
  final Color actualColor;
  final Color actualPastColor;
  final Color gridColor;
  final _ChartScale scale;
  final int pastIndex;
  final int? activeIndex;
  final Color? feelsColor;
  final Color? feelsPastColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (actual.isEmpty || actual.whereType<double>().length < 2) return;

    final rect = scale.rect;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final dy = rect.top + rect.height * i / 4;
      canvas.drawLine(
        Offset(rect.left, dy),
        Offset(rect.right, dy),
        gridPaint,
      );
    }

    if (pastIndex >= 0) {
      _drawPastHatch(
        canvas,
        rect,
        scale.xForIndex(pastIndex),
        gridColor.withValues(alpha: 0.12),
      );
    }

    final endIndex = actual.length - 1;
    final past = pastIndex.clamp(-1, endIndex);
    final futureStart = math.max(0, past);

    final pastPaths = _buildPaths(actual, 0, past);
    final futurePaths =  _buildPaths(actual, futureStart, endIndex);

    final paintPast = Paint()
      ..color = actualPastColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final paintFuture = Paint()
      ..color = actualColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final path in pastPaths) {
      canvas.drawPath(path, paintPast);
    }
    for (final path in futurePaths) {
      canvas.drawPath(path, paintFuture);
    }

    if (feelsLike != null &&
        feelsColor != null &&
        feelsLike!.length == actual.length) {
      final feelsPastPaths = _buildPaths(feelsLike!, 0, past);
      final feelsFuturePaths = _buildPaths(feelsLike!, futureStart, endIndex);
      final paintFeelsPast = Paint()
        ..color = feelsPastColor ?? feelsColor!.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final paintFeelsFuture = Paint()
        ..color = feelsColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (final path in feelsPastPaths) {
        _drawDashedPath(canvas, path, paintFeelsPast);
      }
      for (final path in feelsFuturePaths) {
        _drawDashedPath(canvas, path, paintFeelsFuture);
      }
    }

    if (activeIndex != null &&
        activeIndex! >= 0 &&
        activeIndex! < actual.length &&
        actual[activeIndex!] != null) {
      final x = scale.xForIndex(activeIndex!);
      final activeLine = Paint()
        ..color = gridColor.withValues(alpha: 0.6)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(x, rect.top),
        Offset(x, rect.bottom),
        activeLine,
      );

      final actualPoint =
          Offset(x, scale.yForValue(actual[activeIndex!]!));
      final dotFill = Paint()..color = actualColor;
      final dotGlow = Paint()
        ..color = actualColor.withValues(alpha: 0.25);
      canvas.drawCircle(actualPoint, 8, dotGlow);
      canvas.drawCircle(actualPoint, 4, dotFill);

      if (feelsLike != null &&
          feelsColor != null &&
          activeIndex! < feelsLike!.length &&
          feelsLike![activeIndex!] != null) {
        final feelsPoint =
            Offset(x, scale.yForValue(feelsLike![activeIndex!]!));
        final feelsPaint = Paint()
          ..color = feelsColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(feelsPoint, 4, feelsPaint);
      }
    }
  }

  List<Path> _buildPaths(List<double?> values, int start, int end) {
    if (values.length < 2) return const [];
    if (start < 0 || end <= start) return const [];
    final paths = <Path>[];
    List<Offset> points = [];

    void flush() {
      if (points.length >= 2) {
        paths.add(_smoothPath(points));
      }
      points = [];
    }

    for (int i = start; i <= end; i++) {
      final value = values[i];
      if (value == null) {
        flush();
        continue;
      }
      points.add(Offset(scale.xForIndex(i), scale.yForValue(value)));
    }
    flush();
    return paths;
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }
    return path;
  }

  void _drawPastHatch(Canvas canvas, Rect rect, double endX, Color color) {
    if (endX <= rect.left) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final clipRect = Rect.fromLTRB(rect.left, rect.top, endX, rect.bottom);
    canvas.save();
    canvas.clipRect(clipRect);
    const spacing = 10.0;
    for (double x = rect.left - rect.height;
        x < endX + rect.height;
        x += spacing) {
      canvas.drawLine(
        Offset(x, rect.bottom),
        Offset(x + rect.height, rect.top),
        paint,
      );
    }
    canvas.restore();
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashLength = 6.0;
    const gapLength = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = math.min(dashLength, metric.length - distance);
        final segment = metric.extractPath(distance, distance + len);
        canvas.drawPath(segment, paint);
        distance += len + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TempChartPainter oldDelegate) {
    return oldDelegate.actual != actual ||
        oldDelegate.feelsLike != feelsLike ||
        oldDelegate.actualColor != actualColor ||
        oldDelegate.actualPastColor != actualPastColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.feelsColor != feelsColor ||
        oldDelegate.feelsPastColor != feelsPastColor ||
        oldDelegate.scale != scale ||
        oldDelegate.pastIndex != pastIndex ||
        oldDelegate.activeIndex != activeIndex;
  }
}

IconData _iconForCondition(String condition) {
  final c = condition.toLowerCase();
  if (c.contains('thunder') || c.contains('storm')) {
    return Icons.flash_on;
  }
  if (c.contains('rain') || c.contains('drizzle')) {
    return Icons.beach_access;
  }
  if (c.contains('snow') || c.contains('sleet')) {
    return Icons.ac_unit;
  }
  if (c.contains('fog') || c.contains('mist') || c.contains('haze')) {
    return Icons.blur_on;
  }
  if (c.contains('sun') || c.contains('clear')) {
    return Icons.wb_sunny_outlined;
  }
  if (c.contains('cloud')) return Icons.cloud;
  return Icons.cloud_queue;
}

List<String> _buildTimeLabels(List<DateTime> hours) {
  if (hours.isEmpty) {
    return ['00', '06', '12', '18', '24'];
  }
  final start = hours.first;
  return List.generate(5, (i) {
    final t = start.add(Duration(hours: i * 6));
    return _formatHour(t);
  });
}

String _formatHour(DateTime time) {
  return time.hour.toString().padLeft(2, '0');
}

String _formatTime(DateTime time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

int _lastPastIndex(List<DateTime> times, DateTime now) {
  var idx = -1;
  for (var i = 0; i < times.length; i++) {
    if (!times[i].isAfter(now)) idx = i;
  }
  return idx;
}

int? _currentIndex(List<DateTime> times, DateTime now) {
  for (var i = 0; i < times.length; i++) {
    final t = times[i];
    if (t.year == now.year &&
        t.month == now.month &&
        t.day == now.day &&
        t.hour == now.hour) {
      return i;
    }
  }
  return null;
}
