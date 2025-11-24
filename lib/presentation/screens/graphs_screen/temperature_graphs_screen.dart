import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';

class TemperatureGraphsScreen extends StatefulWidget {
  const TemperatureGraphsScreen({
    super.key,
    required this.appTheme,
  });

  final AppTheme appTheme;

  @override
  State<TemperatureGraphsScreen> createState() =>
      _TemperatureGraphsScreenState();
}

class _TemperatureGraphsScreenState extends State<TemperatureGraphsScreen> {
  TempMode _mode = TempMode.actualVsFeels;

  @override
  Widget build(BuildContext context) {
    final theme = widget.appTheme;

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

class _TemperatureCard extends StatelessWidget {
  const _TemperatureCard({
    required this.theme,
    required this.mode,
    required this.onModeChanged,
  });

  final AppTheme theme;
  final TempMode mode;
  final ValueChanged<TempMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    // Normalized-ish demo data (we’ll stretch them to full height in the painter).
    final actual = <double>[0.20, 0.35, 0.50, 0.80, 0.65, 0.45, 0.30];
    final feels = <double>[0.18, 0.32, 0.48, 0.72, 0.60, 0.40, 0.28];
    final showFeels = mode == TempMode.actualVsFeels;

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
            // Header
            Row(
              children: [
                Icon(Icons.wb_sunny_outlined, size: 18, color: theme.sunny),
                const SizedBox(width: 8),
                const Text(
                  'Conditions',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const Spacer(),
                Icon(Icons.close, size: 18, color: theme.sub),
              ],
            ),
            const SizedBox(height: 8),

            // Main temp line
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '20°',
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
                    'H: 21°  L: 13°',
                    style: TextStyle(
                      color: theme.sub,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // *** Graph area – fills all remaining vertical space in the card ***
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SizedBox.expand(
                  child: CustomPaint(
                    painter: _TempChartPainter(
                      actual: actual,
                      feelsLike: showFeels ? feels : null,
                      actualColor: theme.sunny,
                      feelsColor: showFeels ? theme.sub : null,
                      gridColor: theme.border.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Time labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('00', style: TextStyle(color: theme.sub, fontSize: 10)),
                Text('06', style: TextStyle(color: theme.sub, fontSize: 10)),
                Text('12', style: TextStyle(color: theme.sub, fontSize: 10)),
                Text('18', style: TextStyle(color: theme.sub, fontSize: 10)),
                Text('24', style: TextStyle(color: theme.sub, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 10),

            // Mode segmented control
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
                      onTap: () => onModeChanged(TempMode.actualOnly),
                      child: _SegmentPill(
                        label: 'Actual',
                        active: mode == TempMode.actualOnly,
                        theme: theme,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onModeChanged(TempMode.actualVsFeels),
                      child: _SegmentPill(
                        label: 'Feels Like',
                        active: mode == TempMode.actualVsFeels,
                        theme: theme,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              mode == TempMode.actualVsFeels
                  ? 'Perceived temperature with comparison to actual values.'
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

class _TempChartPainter extends CustomPainter {
  _TempChartPainter({
    required this.actual,
    required this.actualColor,
    required this.gridColor,
    this.feelsLike,
    this.feelsColor,
  });

  final List<double> actual;
  final List<double>? feelsLike;
  final Color actualColor;
  final Color gridColor;
  final Color? feelsColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (actual.isEmpty) return;

    const verticalPadding = 8.0;
    final rect = Rect.fromLTWH(
      0,
      verticalPadding,
      size.width,
      size.height - 2 * verticalPadding,
    );

    // --- Compute dynamic min/max across all series so the graph
    //     stretches vertically and doesn’t look “flat/weird”. ---
    double minVal = actual.reduce(min);
    double maxVal = actual.reduce(max);

    if (feelsLike != null && feelsLike!.isNotEmpty) {
      for (final v in feelsLike!) {
        minVal = min(minVal, v);
        maxVal = max(maxVal, v);
      }
    }

    final span = (maxVal - minVal).abs() < 1e-6 ? 1.0 : (maxVal - minVal);
    double norm(double v) => (v - minVal) / span;

    // Grid lines
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

    Path buildPath(List<double> values) {
      final path = Path();
      final stepX = rect.width / (values.length - 1);

      Offset p(int i) {
        final x = rect.left + i * stepX;
        final t = norm(values[i]); // 0..1
        final y = rect.bottom - t * rect.height;
        return Offset(x, y);
      }

      path.moveTo(p(0).dx, p(0).dy);
      for (int i = 1; i < values.length; i++) {
        final pt = p(i);
        path.lineTo(pt.dx, pt.dy);
      }
      return path;
    }

    // Feels-like line (if enabled)
    if (feelsLike != null &&
        feelsColor != null &&
        feelsLike!.length == actual.length) {
      final pathFeels = buildPath(feelsLike!);
      final paintFeels = Paint()
        ..color = feelsColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(pathFeels, paintFeels);
    }

    // Actual temperature line
    final pathActual = buildPath(actual);
    final paintActual = Paint()
      ..color = actualColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(pathActual, paintActual);
  }

  @override
  bool shouldRepaint(covariant _TempChartPainter oldDelegate) {
    return oldDelegate.actual != actual ||
        oldDelegate.feelsLike != feelsLike ||
        oldDelegate.actualColor != actualColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.feelsColor != feelsColor;
  }
}