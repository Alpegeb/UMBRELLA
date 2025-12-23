import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../providers/settings_state.dart';
import '../../../providers/weather_state.dart';
import '../../../services/notification_service.dart';
import '../../../services/weather_models.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
    required this.appTheme,
  });

  final AppTheme appTheme;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  AppTheme get theme => widget.appTheme;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.requestPermissions();
  }

  String _locationLabel(WeatherLocation location) {
    final name = location.name.trim();
    if (name.isNotEmpty) return name;
    final subtitle = location.subtitle.trim();
    if (subtitle.isNotEmpty) return subtitle;
    return 'Your current location';
  }

  String _rainPreview(WeatherSnapshot snapshot, String locationLabel) {
    if (snapshot.isFallback || snapshot.hourly.isEmpty) {
      return 'Rain outlook is unavailable right now.';
    }
    const threshold = 0.4;
    final now = DateTime.now();
    HourlyWeather? next;
    for (final hour in snapshot.hourly) {
      if (hour.time.isBefore(now)) continue;
      if (hour.precipProbability >= threshold) {
        next = hour;
        break;
      }
    }
    if (next == null) {
      return 'No rain expected in the next 24 hours.';
    }
    final minutes = next.time.difference(now).inMinutes;
    final roundedHours = (minutes / 60).round().clamp(1, 48).toInt();
    final hoursLabel = roundedHours == 1 ? '1 hour' : '$roundedHours hours';
    return 'Rain may be possible in $locationLabel in $hoursLabel — take an umbrella.';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final weather = context.watch<WeatherState>();
    final locations = weather.locations;
    final locationKeys = locations.map((loc) => loc.cacheKey()).toList();
    var selectedKey = settings.notifyLocationKey;
    if (selectedKey == null || !locationKeys.contains(selectedKey)) {
      if (locationKeys.isNotEmpty) {
        final fallback = locationKeys.first;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<SettingsState>().setNotifyLocationKey(fallback);
        });
        selectedKey = fallback;
      }
    }
    WeatherLocation? selectedLocation;
    WeatherSnapshot? selectedSnapshot;
    if (selectedKey != null) {
      final index = locationKeys.indexOf(selectedKey);
      if (index != -1) {
        selectedLocation = locations[index];
        selectedSnapshot = weather.snapshotForIndex(index);
      }
    }
    final snapshot = selectedSnapshot ?? weather.snapshot;
    final locationLabel =
        _locationLabel(selectedLocation ?? snapshot.location);
    final rainPreview = settings.notifyRain
        ? _rainPreview(snapshot, locationLabel)
        : 'Rain alerts are off.';

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
                const SizedBox(height: 12),
                if (locations.isEmpty)
                  Text(
                    'No locations available yet.',
                    style: TextStyle(
                      color: theme.sub,
                      fontSize: 13,
                    ),
                  )
                else
                  Column(
                    children: [
                      for (int i = 0; i < locations.length; i++) ...[
                        if (i > 0)
                          Divider(color: theme.border, height: 16),
                        _LocationOption(
                          theme: theme,
                          title: _locationLabel(locations[i]),
                          subtitle: locations[i].subtitle,
                          selected: locationKeys[i] == selectedKey,
                          onTap: () => context
                              .read<SettingsState>()
                              .setNotifyLocationKey(locationKeys[i]),
                        ),
                      ],
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
                  'Next alert',
                  style: TextStyle(
                    color: theme.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  rainPreview,
                  style: TextStyle(
                    color: theme.sub,
                    fontSize: 14,
                    height: 1.4,
                  ),
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
                  value: settings.notifyRain,
                  onChanged: (v) => settings.setNotifyRain(v),
                ),
                _IndicatorRow(
                  theme: theme,
                  icon: Icons.wb_sunny_outlined,
                  label: 'Sunrise',
                  value: settings.notifySunrise,
                  onChanged: (v) => settings.setNotifySunrise(v),
                ),
                _IndicatorRow(
                  theme: theme,
                  icon: Icons.nightlight_round,
                  label: 'Sunset',
                  value: settings.notifySunset,
                  onChanged: (v) => settings.setNotifySunset(v),
                ),
                _IndicatorRow(
                  theme: theme,
                  icon: Icons.wb_incandescent_outlined,
                  label: 'UV index',
                  value: settings.notifyUv,
                  onChanged: (v) => settings.setNotifyUv(v),
                ),
                _IndicatorRow(
                  theme: theme,
                  icon: Icons.air,
                  label: 'Air quality',
                  value: settings.notifyAirQuality,
                  onChanged: (v) => settings.setNotifyAirQuality(v),
                ),
                _IndicatorRow(
                  theme: theme,
                  icon: Icons.visibility_outlined,
                  label: 'Visibility',
                  value: settings.notifyVisibility,
                  onChanged: (v) => settings.setNotifyVisibility(v),
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
              thumbColor: WidgetStatePropertyAll(theme.cardAlt),
              trackColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                    ? theme.accent.withValues(alpha: 0.5)
                    : theme.border,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LocationOption extends StatelessWidget {
  const _LocationOption({
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final AppTheme theme;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final trimmedSubtitle = subtitle.trim();
    final showSubtitle =
        trimmedSubtitle.isNotEmpty && trimmedSubtitle != title.trim();
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? theme.accent : theme.sub,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (showSubtitle)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        trimmedSubtitle,
                        style: TextStyle(
                          color: theme.sub,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
