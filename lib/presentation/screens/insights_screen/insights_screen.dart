import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../providers/weather_state.dart';
import '../../../services/weather_utils.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key, required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    final snapshot = context.watch<WeatherState>().snapshot;
    final current = snapshot.current;
    final index = umbrellaIndex(current);
    final now = DateTime.now();
    final today = dailyForDate(snapshot.daily, now);
    final sunrise = today?.sunriseTime;
    final sunset = today?.sunsetTime;
    final isNight = sunrise != null && sunset != null
        ? now.isBefore(sunrise) || now.isAfter(sunset)
        : now.hour < 6 || now.hour >= 18;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(theme: theme),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    _Insight(
                      theme: theme,
                      icon: Icons.masks_rounded,
                      title: "BREATHE EASY",
                      text: humidityInsightText(current.humidity),
                    ),
                    const SizedBox(height: 10),
                    _Insight(
                      theme: theme,
                      icon: Icons.thermostat_rounded,
                      title: "THE SWEET SPOT",
                      text: temperatureComfortText(
                        current.tempC,
                        now: now,
                        sunrise: sunrise,
                        sunset: sunset,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Insight(
                      theme: theme,
                      icon: Icons.auto_awesome_rounded,
                      title: "COZY & FOCUSED",
                      text: skyInsightText(
                        current.condition,
                        now: now,
                        sunrise: sunrise,
                        sunset: sunset,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Insight(
                      theme: theme,
                      icon: Icons.umbrella_rounded,
                      title: "PLAN AHEAD",
                      text:
                          "Umbrella Index is ${index.toStringAsFixed(1)}/10. ${index >= 6 ? "A compact umbrella could be a good backup." : isNight ? "Rain looks unlikely tonight." : "Rain looks unlikely today."}",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.text),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 4),
        Text(
          "Today's Insights",
          style: TextStyle(
            color: theme.text,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Insight extends StatelessWidget {
  const _Insight({
    required this.theme,
    required this.icon,
    required this.title,
    required this.text,
  });

  final AppTheme theme;
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.sub),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: theme.sub,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: theme.text,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
