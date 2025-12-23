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

  String _leadLabel(DateTime target, DateTime now) {
    final minutes = target.difference(now).inMinutes;
    if (minutes < 60) {
      final safe = minutes.clamp(1, 59);
      return safe == 1 ? '1 minute' : '$safe minutes';
    }
    final hours = (minutes / 60).round().clamp(1, 48);
    return hours == 1 ? '1 hour' : '$hours hours';
  }

  _AlertPreview? _rainPreview(WeatherSnapshot snapshot, DateTime now) {
    if (snapshot.isFallback || snapshot.hourly.isEmpty) return null;
    const threshold = 0.4;
    final next = snapshot.hourly
        .where((h) => !h.time.isBefore(now))
        .where((h) => h.precipProbability >= threshold)
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    if (next.isEmpty) return null;
    final location = _locationLabel(snapshot.location);
    final label = _leadLabel(next.first.time, now);
    return _AlertPreview(
      time: next.first.time,
      title: 'Rain probability',
      message: 'Rain may be possible in $location in $label — take an umbrella.',
    );
  }

  _AlertPreview? _uvPreview(WeatherSnapshot snapshot, DateTime now) {
    if (snapshot.isFallback || snapshot.hourly.isEmpty) return null;
    const threshold = 6;
    final next = snapshot.hourly
        .where((h) => !h.time.isBefore(now))
        .where((h) => (h.uvIndex ?? 0) >= threshold)
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    if (next.isEmpty) return null;
    final location = _locationLabel(snapshot.location);
    final label = _leadLabel(next.first.time, now);
    return _AlertPreview(
      time: next.first.time,
      title: 'UV alert',
      message: 'High UV may be possible in $location in $label. Wear sunscreen.',
    );
  }

  _AlertPreview? _visibilityPreview(WeatherSnapshot snapshot, DateTime now) {
    if (snapshot.isFallback || snapshot.hourly.isEmpty) return null;
    const thresholdKm = 5.0;
    final next = snapshot.hourly
        .where((h) => !h.time.isBefore(now))
        .where((h) => h.visibilityKm != null && h.visibilityKm! <= thresholdKm)
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    if (next.isEmpty) return null;
    final location = _locationLabel(snapshot.location);
    final label = _leadLabel(next.first.time, now);
    return _AlertPreview(
      time: next.first.time,
      title: 'Visibility alert',
      message: 'Low visibility possible in $location in $label. Drive carefully.',
    );
  }

  _AlertPreview? _sunrisePreview(WeatherSnapshot snapshot, DateTime now) {
    final times = snapshot.daily
        .map((d) => d.sunriseTime)
        .whereType<DateTime>()
        .where((t) => !t.isBefore(now))
        .toList()
      ..sort();
    if (times.isEmpty) return null;
    final location = _locationLabel(snapshot.location);
    return _AlertPreview(
      time: times.first,
      title: 'Sunrise',
      message: 'Sunrise in $location.',
    );
  }

  _AlertPreview? _sunsetPreview(WeatherSnapshot snapshot, DateTime now) {
    final times = snapshot.daily
        .map((d) => d.sunsetTime)
        .whereType<DateTime>()
        .where((t) => !t.isBefore(now))
        .toList()
      ..sort();
    if (times.isEmpty) return null;
    final location = _locationLabel(snapshot.location);
    return _AlertPreview(
      time: times.first,
      title: 'Sunset',
      message: 'Sunset in $location.',
    );
  }

  _AlertPreview? _airQualityPreview(WeatherSnapshot snapshot, DateTime now) {
    final aqi = snapshot.airQuality?.aqi;
    if (aqi == null || aqi < 100) return null;
    final location = _locationLabel(snapshot.location);
    final category = snapshot.airQuality?.category ?? 'Poor air quality';
    return _AlertPreview(
      time: now.add(const Duration(minutes: 5)),
      title: 'Air quality alert',
      message: '$category in $location. Limit outdoor activity.',
    );
  }

  _AlertPreview? _nextAlertPreview(
    List<WeatherSnapshot> snapshots,
    SettingsState settings,
  ) {
    final now = DateTime.now();
    final events = <_AlertPreview>[];
    for (final snapshot in snapshots) {
      if (snapshot.isFallback) continue;
      if (settings.notifyRain) {
        final event = _rainPreview(snapshot, now);
        if (event != null) events.add(event);
      }
      if (settings.notifySunrise) {
        final event = _sunrisePreview(snapshot, now);
        if (event != null) events.add(event);
      }
      if (settings.notifySunset) {
        final event = _sunsetPreview(snapshot, now);
        if (event != null) events.add(event);
      }
      if (settings.notifyUv) {
        final event = _uvPreview(snapshot, now);
        if (event != null) events.add(event);
      }
      if (settings.notifyVisibility) {
        final event = _visibilityPreview(snapshot, now);
        if (event != null) events.add(event);
      }
      if (settings.notifyAirQuality) {
        final event = _airQualityPreview(snapshot, now);
        if (event != null) events.add(event);
      }
    }
    if (events.isEmpty) return null;
    events.sort((a, b) => a.time.compareTo(b.time));
    return events.first;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final weather = context.watch<WeatherState>();
    final locations = weather.locations;
    final locationKeys = locations.map((loc) => loc.cacheKey()).toList();
    final hasSelection = settings.hasNotifyLocationSelection;
    final selectedKeys = hasSelection
        ? settings.notifyLocationKeys.toSet()
        : locationKeys.toSet();
    final selectedSnapshots = <WeatherSnapshot>[];
    for (int i = 0; i < locationKeys.length; i++) {
      if (selectedKeys.contains(locationKeys[i])) {
        selectedSnapshots.add(weather.snapshotForIndex(i));
      }
    }
    final hasAlertsEnabled = settings.notifyRain ||
        settings.notifySunrise ||
        settings.notifySunset ||
        settings.notifyUv ||
        settings.notifyAirQuality ||
        settings.notifyVisibility;
    final nextAlert = _nextAlertPreview(selectedSnapshots, settings);
    final alertPreview = !hasAlertsEnabled
        ? 'All alerts are turned off.'
        : locations.isEmpty
            ? 'Add a location to start receiving alerts.'
            : selectedKeys.isEmpty
                ? 'Select at least one location to receive alerts.'
                : nextAlert?.message ??
                    'No alerts expected for the selected locations.';

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
                  'Locations to warn',
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
                        _LocationToggle(
                          theme: theme,
                          title: _locationLabel(locations[i]),
                          subtitle: locations[i].subtitle,
                          selected: selectedKeys.contains(locationKeys[i]),
                          onChanged: (value) {
                            final keys = Set<String>.from(selectedKeys);
                            if (value) {
                              keys.add(locationKeys[i]);
                            } else {
                              keys.remove(locationKeys[i]);
                            }
                            context
                                .read<SettingsState>()
                                .setNotifyLocationKeys(keys.toList());
                          },
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
                  alertPreview,
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

class _AlertPreview {
  const _AlertPreview({
    required this.time,
    required this.title,
    required this.message,
  });

  final DateTime time;
  final String title;
  final String message;
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

class _LocationToggle extends StatelessWidget {
  const _LocationToggle({
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onChanged,
  });

  final AppTheme theme;
  final String title;
  final String subtitle;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final trimmedSubtitle = subtitle.trim();
    final showSubtitle =
        trimmedSubtitle.isNotEmpty && trimmedSubtitle != title.trim();
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!selected),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
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
            Switch(
              value: selected,
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
      ),
    );
  }
}
