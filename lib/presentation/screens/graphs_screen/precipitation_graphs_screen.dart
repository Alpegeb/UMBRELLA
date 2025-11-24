import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';

class PrecipitationGraphsScreen extends StatelessWidget {
  const PrecipitationGraphsScreen({
    super.key,
    required this.appTheme,
  });

  final AppTheme appTheme;

  @override
  Widget build(BuildContext context) {
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
                  title: 'Chance of Precipitation',
                  subtitle: "Tuesday's chance: 16%",
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This screen illustrates the chance of precipitation across '
                    'different hours of the day using a smooth line chart. The visual '
                    'representation enables users to quickly interpret rainfall '
                    'likelihood and timing.',
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

class _PrecipitationCard extends StatelessWidget {
  const _PrecipitationCard({
    required this.theme,
    required this.title,
    required this.subtitle,
  });

  final AppTheme theme;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final values = <double>[0.05, 0.10, 0.25, 0.70, 0.50, 0.30, 0.15];

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
                Icon(Icons.circle_outlined, size: 18, color: theme.sub),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(Icons.close, size: 18, color: theme.sub),
              ],
            ),
            const SizedBox(height: 12),

            // *** Graph area – fills remaining vertical space in card ***
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox.expand(
                  child: CustomPaint(
                    painter: _PrecipLinePainter(
                      values: values,
                      lineColor: theme.accent,
                      gridColor: theme.border.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
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

class _PrecipLinePainter extends CustomPainter {
  _PrecipLinePainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const padding = 8.0;
    // Use full width, only vertical padding so it fills the card horizontally.
    final rect = Rect.fromLTWH(
      0,
      padding,
      size.width,
      size.height - 2 * padding,
    );

    // Dynamic min/max so the curve fills vertically.
    double minVal = values.reduce(min);
    double maxVal = values.reduce(max);
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

    if (values.length < 2) return;

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

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _PrecipLinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}