import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../providers/weather_state.dart';
import '../../../services/weather_models.dart';
import '../../../services/weather_utils.dart';

class PrecipitationGraphsScreen extends StatelessWidget {
  const PrecipitationGraphsScreen({
    super.key,
    required this.appTheme,
  });

  final AppTheme appTheme;

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherState>();
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
    final values = slots.map((h) => h?.precipMm).toList();
    final times = dayTimes;
    final todayDaily = showPlaceholder
        ? null
        : dailyForDate(snapshot.daily, DateTime.now());
    double? totalMm;
    if (!showPlaceholder) {
      totalMm = todayDaily?.precipMm;
      if (totalMm == null && slots.isNotEmpty) {
        double sum = 0.0;
        int count = 0;
        for (final slot in slots) {
          final mm = slot?.precipMm;
          if (mm != null) {
            sum += mm;
            count += 1;
          }
        }
        if (count > 0) {
          totalMm = sum;
        }
      }
    }
    final subtitle = totalMm == null
        ? "Today's total: -- mm"
        : "Today's total: ${_formatMm(totalMm)} mm";
    final timeLabels = _buildTimeLabels(dayTimes);

    return Scaffold(
      backgroundColor: appTheme.bg,
      appBar: AppBar(
        backgroundColor: appTheme.bg,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appTheme.text),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Precipitation Graphs',
          style: TextStyle(
            color: appTheme.text,
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
                child: _PrecipitationCard(
                  theme: appTheme,
                  title: 'Precipitation (mm)',
                  subtitle: subtitle,
                  values: values,
                  times: times,
                  timeLabels: timeLabels,
                  unitLabel: 'mm',
                  showPlaceholder: showPlaceholder,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hourly precipitation totals with interactive detail. Past hours '
                    'fade back while the upcoming timeline stays vivid for quick '
                    'scanning.',
                style: TextStyle(
                  color: appTheme.sub,
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

class _PrecipitationCard extends StatefulWidget {
  const _PrecipitationCard({
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.values,
    required this.times,
    required this.timeLabels,
    required this.unitLabel,
    required this.showPlaceholder,
  });

  final AppTheme theme;
  final String title;
  final String subtitle;
  final List<double?> values;
  final List<DateTime> times;
  final List<String> timeLabels;
  final String unitLabel;
  final bool showPlaceholder;

  @override
  State<_PrecipitationCard> createState() => _PrecipitationCardState();
}

class _PrecipitationCardState extends State<_PrecipitationCard> {
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
    final minCount = math.min(widget.values.length, widget.times.length);
    final values =
        minCount >= 2 ? widget.values.take(minCount).toList() : <double?>[];
    final times = widget.times.take(minCount).toList();
    final hasData = !widget.showPlaceholder &&
        values.where((v) => v != null).length >= 2;

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
                Icon(Icons.circle_outlined, size: 18, color: theme.sub),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  widget.unitLabel,
                  style: TextStyle(color: theme.sub, fontSize: 11),
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
                          'Forecast data unavailable',
                          style: TextStyle(color: theme.sub, fontSize: 12),
                        ),
                      );
                    }
                    final count = values.length;
                    final scale = _PrecipChartScale.fromSeries(
                      values: values,
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    );
                    final pastIndex = _lastPastIndex(times, DateTime.now());
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
                              painter: _PrecipChartPainter(
                                values: values,
                                lineColor: theme.accent,
                                pastLineColor:
                                    theme.accent.withValues(alpha: 0.35),
                                gridColor:
                                    theme.border.withValues(alpha: 0.25),
                                scale: scale,
                                pastIndex: pastIndex,
                                activeIndex: activeIndex,
                              ),
                            ),
                          ),
                          if (activeIndex != null)
                            _PrecipTooltip(
                              theme: theme,
                              scale: scale,
                              index: activeIndex,
                              time: times[activeIndex],
                              value: values[activeIndex],
                              unitLabel: widget.unitLabel,
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
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: TextStyle(
                color: theme.sub,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrecipChartScale {
  _PrecipChartScale({
    required this.maxValue,
    required this.rect,
    required this.size,
    required this.count,
  })  : stepX = count > 1 ? rect.width / (count - 1) : 0,
        barWidth = count > 1
            ? math.min(18.0, rect.width / count * 0.65)
            : 0;

  final double maxValue;
  final Rect rect;
  final Size size;
  final int count;
  final double stepX;
  final double barWidth;

  factory _PrecipChartScale.fromSeries({
    required List<double?> values,
    required Size size,
  }) {
    final nonNull = values.whereType<double>();
    double maxVal = nonNull.isEmpty
        ? 1.0
        : nonNull.fold<double>(0.0, (m, v) => math.max(m, v));
    if (maxVal < 1) maxVal = 1.0;
    maxVal += math.max(1.0, maxVal * 0.15);
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
    return _PrecipChartScale(
      maxValue: maxVal,
      rect: rect,
      size: size,
      count: values.length,
    );
  }

  double xForIndex(int index) => rect.left + stepX * index;

  double yForValue(double value) {
    final v = value.clamp(0.0, maxValue);
    final t = maxValue <= 0 ? 0.0 : (v / maxValue);
    return rect.bottom - t * rect.height;
  }
}

class _PrecipTooltip extends StatelessWidget {
  const _PrecipTooltip({
    required this.theme,
    required this.scale,
    required this.index,
    required this.time,
    required this.value,
    required this.unitLabel,
  });

  final AppTheme theme;
  final _PrecipChartScale scale;
  final int index;
  final DateTime time;
  final double? value;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final timeLabel = _formatTime(time);
    final valueLabel =
        value == null ? '-- $unitLabel' : '${_formatMm(value!)} $unitLabel';
    const tooltipWidth = 120.0;
    const tooltipHeight = 52.0;

    final anchorValue = value ?? 0.0;
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
            Text(
              valueLabel,
              style: TextStyle(
                color: theme.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrecipChartPainter extends CustomPainter {
  _PrecipChartPainter({
    required this.values,
    required this.lineColor,
    required this.pastLineColor,
    required this.gridColor,
    required this.scale,
    required this.pastIndex,
    required this.activeIndex,
  });

  final List<double?> values;
  final Color lineColor;
  final Color pastLineColor;
  final Color gridColor;
  final _PrecipChartScale scale;
  final int pastIndex;
  final int? activeIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || values.whereType<double>().length < 2) return;
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

    final endIndex = values.length - 1;
    final past = pastIndex.clamp(-1, endIndex);
    final futureStart = math.max(0, past);

    final futurePaths = _buildPaths(values, futureStart, endIndex);
    for (final futurePath in futurePaths) {
      final bounds = futurePath.getBounds();
      final startX = bounds.left;
      final endX = bounds.right;
      final fillPath = Path.from(futurePath)
        ..lineTo(endX, rect.bottom)
        ..lineTo(startX, rect.bottom)
        ..close();
      final gradient = LinearGradient(
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = gradient
          ..style = PaintingStyle.fill,
      );
    }

    for (int i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) continue;
      final x = scale.xForIndex(i);
      final y = scale.yForValue(value);
      final barHeight = rect.bottom - y;
      final barRect = Rect.fromLTWH(
        x - scale.barWidth / 2,
        y,
        scale.barWidth,
        barHeight,
      );
      final barColor = i <= past
          ? lineColor.withValues(alpha: 0.25)
          : lineColor.withValues(alpha: 0.55);
      final rrect = RRect.fromRectAndRadius(barRect, const Radius.circular(6));
      canvas.drawRRect(rrect, Paint()..color = barColor);
    }

    final pastPaths = _buildPaths(values, 0, past);
    for (final pastPath in pastPaths) {
      canvas.drawPath(
        pastPath,
        Paint()
          ..color = pastLineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (final futurePath in futurePaths) {
      canvas.drawPath(
        futurePath,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (activeIndex != null &&
        activeIndex! >= 0 &&
        activeIndex! < values.length &&
        values[activeIndex!] != null) {
      final x = scale.xForIndex(activeIndex!);
      final activeLine = Paint()
        ..color = gridColor.withValues(alpha: 0.6)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(x, rect.top),
        Offset(x, rect.bottom),
        activeLine,
      );

      final point = Offset(x, scale.yForValue(values[activeIndex!]!));
      final dotGlow = Paint()..color = lineColor.withValues(alpha: 0.2);
      canvas.drawCircle(point, 8, dotGlow);
      canvas.drawCircle(point, 4, Paint()..color = lineColor);
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

  @override
  bool shouldRepaint(covariant _PrecipChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.pastLineColor != pastLineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.scale != scale ||
        oldDelegate.pastIndex != pastIndex ||
        oldDelegate.activeIndex != activeIndex;
  }
}

String _formatMm(double value) {
  if (value >= 10) return value.round().toString();
  return value.toStringAsFixed(1);
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
