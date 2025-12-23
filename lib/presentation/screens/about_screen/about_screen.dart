import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({
    super.key,
    required this.appTheme,
    required this.versionLabel,
  });

  final AppTheme appTheme;
  final String versionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = appTheme;
    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: theme.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'About Umbrella',
          style: TextStyle(
            color: theme.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(
            theme: theme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Umbrella Weather',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  versionLabel,
                  style: TextStyle(
                    color: theme.sub,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Umbrella combines forecasts, air quality, wind, and '
                  'precipitation insights to help you plan the day at a glance.',
                  style: TextStyle(
                    color: theme.text,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            theme: theme,
            title: 'What it does',
            items: const [
              'Real-time weather cards with hourly and 5‑day outlooks.',
              'Air quality, UV, visibility, and precipitation summaries.',
              'Multiple saved locations with quick switching.',
              'Insights and graphs for deeper trends.',
              'Notification alerts for changing conditions.',
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            theme: theme,
            title: 'Data & privacy',
            items: const [
              'Forecasts use the configured Google Weather APIs.',
              'Location data stays on device unless you save it.',
              'Notifications rely on cached forecasts when offline.',
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.theme,
    this.title,
    this.items,
    this.child,
  });

  final AppTheme theme;
  final String? title;
  final List<String>? items;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border),
      ),
      child: child ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (title != null) const SizedBox(height: 12),
              for (final item in items ?? const <String>[])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 16, color: theme.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: theme.text,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
    );
  }
}
