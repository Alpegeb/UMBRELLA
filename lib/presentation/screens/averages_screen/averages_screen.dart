import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';

class _AveragesPalette {
  final Color background;
  final Color card;
  final Color altCard;
  final Color text;
  final Color subtext;
  final Color border;
  final Color accentYellow;
  final Color accentBlue;
  final List<Color> tempRangeGradient;
  final List<Color> precipRangeGradient;

  const _AveragesPalette({
    required this.background,
    required this.card,
    required this.altCard,
    required this.text,
    required this.subtext,
    required this.border,
    required this.accentYellow,
    required this.accentBlue,
    required this.tempRangeGradient,
    required this.precipRangeGradient,
  });

  factory _AveragesPalette.fromAppTheme(AppTheme t) {
    return _AveragesPalette(
      background: t.bg,
      card: t.card,
      altCard: t.cardAlt,
      text: t.text,
      subtext: t.sub,
      border: t.border,
      accentYellow: t.sunny,
      accentBlue: t.accent,
      tempRangeGradient: [
        t.sunny.withValues(alpha: 0.4),
        t.sunny.withValues(alpha: 0.0),
      ],
      precipRangeGradient: [
        t.rainy.withValues(alpha: 0.4),
        t.rainy.withValues(alpha: 0.0),
      ],
    );
  }
}

class AppTextStyles {
  static const TextStyle body =
  TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
  static const TextStyle bodySubtle =
  TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
  static const TextStyle label =
  TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
  static const TextStyle title =
  TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
  static const TextStyle largeNumber = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
  );
  static const TextStyle headline =
  TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  static const TextStyle subHeadline =
  TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
  static const TextStyle smallSubtext =
  TextStyle(fontSize: 11, fontWeight: FontWeight.w400);
}

enum AveragesMode { temperature, precipitation }

class AveragesScreen extends StatefulWidget {
  const AveragesScreen({super.key, required this.appTheme});

  final AppTheme appTheme;

  @override
  State<AveragesScreen> createState() => _AveragesScreenState();
}

class _AveragesScreenState extends State<AveragesScreen> {
  AveragesMode _currentMode = AveragesMode.temperature;

  @override
  Widget build(BuildContext context) {
    final colors = _AveragesPalette.fromAppTheme(widget.appTheme);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildHeader(colors),
                const SizedBox(height: 16),
                _CustomSegmentedControl(
                  mode: _currentMode,
                  colors: colors,
                  onModeChanged: (mode) {
                    setState(() {
                      _currentMode = mode;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _DailyAverageCard(mode: _currentMode, colors: colors),
                const SizedBox(height: 12),
                _MonthlyAverageCard(mode: _currentMode, colors: colors),
                const SizedBox(height: 34),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(_AveragesPalette colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.show_chart_rounded, color: colors.text, size: 20),
            const SizedBox(width: 8),
            Text(
              'Averages',
              style: AppTextStyles.title.copyWith(color: colors.text),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.altCard,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border, width: 1),
            ),
            child: Icon(Icons.close, color: colors.subtext, size: 18),
          ),
        ),
      ],
    );
  }
}

class _CustomSegmentedControl extends StatelessWidget {
  final AveragesMode mode;
  final _AveragesPalette colors;
  final ValueChanged<AveragesMode> onModeChanged;

  const _CustomSegmentedControl({
    required this.mode,
    required this.colors,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.altCard,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _buildSegment('Temperature', AveragesMode.temperature, colors.accentYellow),
          _buildSegment('Precipitation', AveragesMode.precipitation, colors.accentBlue),
        ],
      ),
    );
  }

  Widget _buildSegment(
      String text,
      AveragesMode segmentMode,
      Color activeColor,
      ) {
    final bool isActive = mode == segmentMode;

    return Expanded(
      child: GestureDetector(
        onTap: () => onModeChanged(segmentMode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? colors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isActive
                ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ]
                : [],
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: isActive
                  ? AppTextStyles.label.copyWith(color: activeColor)
                  : AppTextStyles.label.copyWith(color: colors.subtext),
              child: Text(text),
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyAverageCard extends StatelessWidget {
  final AveragesMode mode;
  final _AveragesPalette colors;

  const _DailyAverageCard({
    required this.mode,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTemp = mode == AveragesMode.temperature;

    final Color accentColor = isTemp ? colors.accentYellow : colors.accentBlue;
    final String headline = isTemp ? "+6° above average" : "20% above average";
    final String subtext = isTemp ? "Average high: 15°" : "Average: 2.5 mm";
    final String largeNumber = isTemp ? "21°" : "3.0 mm";

    final String summary = isTemp
        ? "For November 8, the normal temperature range is 7°–19°, and the average high is 15°. Today’s high temperature is 21°."
        : "For November 8, the normal precipitation is 2.5 mm. Today's total is 3.0 mm.";

    final String normalRange =
    isTemp ? "Normal Range (7°–19°)" : "Normal Range (1–3 mm)";
    final String todayLabel = "Today";

    final List<Color> gradientColors =
    isTemp ? colors.tempRangeGradient : colors.precipRangeGradient;

    final double todayPosition = isTemp ? 0.7 : 0.65;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: AppTextStyles.headline.copyWith(color: accentColor),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: AppTextStyles.subHeadline.copyWith(color: colors.subtext),
          ),
          const SizedBox(height: 16),
          Text(
            largeNumber,
            style: AppTextStyles.largeNumber.copyWith(color: colors.text),
          ),
          const SizedBox(height: 24),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: colors.altCard,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: todayPosition,
                          alignment: Alignment.centerLeft,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.card,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                todayLabel,
                style: AppTextStyles.bodySubtle.copyWith(color: colors.subtext),
              ),
              Text(
                normalRange,
                style: AppTextStyles.bodySubtle.copyWith(color: colors.subtext),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            summary,
            style: AppTextStyles.bodySubtle.copyWith(
              height: 1.4,
              color: colors.subtext,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MonthlyAverageCard extends StatelessWidget {
  final AveragesMode mode;
  final _AveragesPalette colors;

  const _MonthlyAverageCard({
    required this.mode,
    required this.colors,
  });

  LinearGradient _getSeasonalGradient(int month) {
    final double t = (1.0 - ((month - 7).abs() / 6.0)).clamp(0.0, 1.0);
    final Color startColor =
    Color.lerp(Colors.cyan.shade300, colors.accentYellow, t)!;
    final Color endColor =
    Color.lerp(Colors.cyan.shade600, const Color(0xFFD89B00), t)!;
    return LinearGradient(colors: [startColor, endColor]);
  }

  LinearGradient _getPrecipGradient() {
    return LinearGradient(
      colors: [
        colors.accentBlue,
        colors.accentBlue.withValues(alpha: 0.7),
      ],
    );
  }

  List<Map<String, dynamic>> _getTempData() => [
    {'month': 'Jan', 'range': '4°–8°', 'gradient': _getSeasonalGradient(1)},
    {'month': 'Feb', 'range': '5°–10°', 'gradient': _getSeasonalGradient(2)},
    {'month': 'Mar', 'range': '8°–15°', 'gradient': _getSeasonalGradient(3)},
    {'month': 'Apr', 'range': '12°–20°', 'gradient': _getSeasonalGradient(4)},
    {'month': 'May', 'range': '16°–24°', 'gradient': _getSeasonalGradient(5)},
    {'month': 'Jun', 'range': '20°–28°', 'gradient': _getSeasonalGradient(6)},
    {'month': 'Jul', 'range': '22°–30°', 'gradient': _getSeasonalGradient(7)},
    {'month': 'Aug', 'range': '21°–29°', 'gradient': _getSeasonalGradient(8)},
    {'month': 'Sep', 'range': '18°–26°', 'gradient': _getSeasonalGradient(9)},
    {'month': 'Oct', 'range': '13°–21°', 'gradient': _getSeasonalGradient(10)},
    {'month': 'Nov', 'range': '8°–15°', 'gradient': _getSeasonalGradient(11)},
    {'month': 'Dec', 'range': '5°–10°', 'gradient': _getSeasonalGradient(12)},
  ];

  List<Map<String, dynamic>> _getPrecipData() => [
    {'month': 'Jan', 'range': '40–60 mm', 'gradient': _getPrecipGradient()},
    {'month': 'Feb', 'range': '30–58 mm', 'gradient': _getPrecipGradient()},
    {'month': 'Mar', 'range': '30–50 mm', 'gradient': _getPrecipGradient()},
    {'month': 'Apr', 'range': '20–40 mm', 'gradient': _getPrecipGradient()},
    {'month': 'May', 'range': '10–30 mm', 'gradient': _getPrecipGradient()},
    {'month': 'Jun', 'range': '5–20 mm', 'gradient': _getPrecipGradient()},
    {'month': 'Jul', 'range': '5–15 mm', 'gradient': _getPrecipGradient()},
    {'month': 'Aug', 'range': '5–20 mm', 'gradient': _getPrecipGradient()},
    {'month': 'Sep', 'range': '10–30 mm', 'gradient': _getPrecipGradient()},
    {'month': 'Oct', 'range': '30–50 mm', 'gradient': _getPrecipGradient()},
    {'month': 'Nov', 'range': '40–60 mm', 'gradient': _getPrecipGradient()},
    {'month': 'Dec', 'range': '50–70 mm', 'gradient': _getPrecipGradient()},
  ];

  @override
  Widget build(BuildContext context) {
    final bool isTemp = mode == AveragesMode.temperature;
    final data = isTemp ? _getTempData() : _getPrecipData();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Monthly Averages",
            style: AppTextStyles.title.copyWith(color: colors.text),
          ),
          const SizedBox(height: 16),
          ...data.map(
                (item) => _buildMonthRow(
              item['month'] as String,
              item['range'] as String,
              item['gradient'] as Gradient,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Data from 10-year averages (2013–2023)',
              style: AppTextStyles.smallSubtext.copyWith(
                color: colors.subtext,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthRow(String month, String range, Gradient gradient) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              month,
              style: AppTextStyles.bodySubtle.copyWith(
                fontSize: 13,
                color: colors.subtext,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              range,
              textAlign: TextAlign.right,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: colors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}