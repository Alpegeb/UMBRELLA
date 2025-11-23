import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool rain = true;
  bool sunrise = true;
  bool sunset = true;
  bool uv = true;
  bool airQuality = true;
  bool visibility = true;

  bool isLight = true;

  @override
  Widget build(BuildContext context) {
    final theme = isLight ? AppTheme.light : AppTheme.dark;

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
        actions: [
          IconButton(
            icon: Icon(
              isLight ? Icons.dark_mode : Icons.light_mode,
              color: theme.sub,
            ),
            onPressed: () => setState(() => isLight = !isLight),
          )
        ],
        title: Text(
          'Real-time notifications',
          style: TextStyle(
            color: theme.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _RoundedCard(
            theme: theme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location to warn',
                  style: TextStyle(
                    color: theme.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on, color: theme.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your current location',
                        style: TextStyle(
                          color: theme.sub,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: theme.sub),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _RoundedCard(
            theme: theme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select the weather indicators you want to be notified about',
                  style: TextStyle(
                    color: theme.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _IndicatorRow(
                  theme: theme,
                  icon: Icons.umbrella_outlined,
                  label: 'Rain probability',
                  value: rain,
                  onChanged: (v) => setState(() => rain = v),
                ),
                _IndicatorRow(
                  theme: theme,
                  icon: Icons.wb_sunny_outlined,
                  label: 'Sunrise',
                  value: sunrise,
                  onChanged: (v) => setState(() => sunrise = v),
                ),
                _IndicatorRow(
                  theme: theme,
                  icon: Icons.nightlight_round,
                  label: 'Sunset',
                  value: sunset,
                  onChanged: (v) => setState(() => sunset = v),
                ),
                _IndicatorRow(
                  theme: theme,
                  icon: Icons.wb_incandescent_outlined,
                  label: 'UV index',
                  value: uv,
                  onChanged: (v) => setState(() => uv = v),
                ),
                _IndicatorRow(
                  theme: theme,
                  icon: Icons.air,
                  label: 'Air quality',
                  value: airQuality,
                  onChanged: (v) => setState(() => airQuality = v),
                ),
                _IndicatorRow(
                  theme: theme,
                  icon: Icons.visibility_outlined,
                  label: 'Visibility',
                  value: visibility,
                  onChanged: (v) => setState(() => visibility = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundedCard extends StatelessWidget {
  final Widget child;
  final AppTheme theme;

  const _RoundedCard({required this.child, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border),
      ),
      child: child,
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppTheme theme;

  const _IndicatorRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(color: theme.border, height: 24),
        Row(
          children: [
            Icon(icon, color: theme.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 14,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              thumbColor: WidgetStateProperty.all(Colors.grey),
              trackColor: WidgetStateProperty.resolveWith(
                    (states) =>
                states.contains(WidgetState.selected)
                    ? Colors.grey.shade600
                    : Colors.grey.shade300,
              ),
            )
          ],
        ),
      ],
    );
  }
}
