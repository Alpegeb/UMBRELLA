import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key, required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.bg,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(theme: theme),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  _Insight(theme: theme, icon: Icons.masks_rounded, title: "BREATHE EASY", text: "Today's air quality is ‘Good’ (AQI 42). Perfect for fresh air or outdoor activities."),
                  const SizedBox(height: 10),
                  _Insight(theme: theme, icon: Icons.thermostat_rounded, title: "THE SWEET SPOT", text: "15°C — perfect for a walk or light jog."),
                  const SizedBox(height: 10),
                  _Insight(theme: theme, icon: Icons.auto_awesome_rounded, title: "COZY & FOCUSED", text: "Cloudy skies reduce glare, improving focus for indoor tasks."),
                  const SizedBox(height: 10),
                  _Insight(theme: theme, icon: Icons.umbrella_rounded, title: "PLAN AHEAD", text: "Umbrella Index is 7.3/10. A compact umbrella might help later."),
                ],
              ),
            ),
          ],
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
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_new, color: theme.text),
        ),
        const SizedBox(width: 12),
        Text("Today's Insights", style: TextStyle(color: theme.text, fontSize: 28, fontWeight: FontWeight.w800)),
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
              Text(title, style: TextStyle(color: theme.sub, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: theme.text, fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }
}