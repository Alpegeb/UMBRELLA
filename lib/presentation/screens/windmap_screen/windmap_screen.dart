import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../providers/settings_state.dart';
import '../../../providers/weather_state.dart';
import '../../../services/weather_models.dart';
import '../../../services/weather_units.dart';
import '../../widgets/wind_map_view.dart';

class _WindMapPalette {
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconColor;
  final Color controlButtonColor;
  final Color accentBlue;

  const _WindMapPalette({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconColor,
    required this.controlButtonColor,
    required this.accentBlue,
  });

  factory _WindMapPalette.fromAppTheme(AppTheme t) {
    return _WindMapPalette(
      background: t.bg,
      surface: t.card,
      textPrimary: t.text,
      textSecondary: t.sub,
      iconColor: t.text,
      controlButtonColor: t.cardAlt,
      accentBlue: t.accent,
    );
  }
}

class WindMapScreen extends StatefulWidget {
  const WindMapScreen({super.key, required this.appTheme});
  final AppTheme appTheme;

  @override
  State<WindMapScreen> createState() => _WindMapScreenState();
}

class _WindMapScreenState extends State<WindMapScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isAnimating = true;
  WindMapLayer _layer = WindMapLayer.standard;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleAnimation() {
    setState(() {
      _isAnimating = !_isAnimating;
      if (_isAnimating) {
        _controller.value = 0.0;
      }
    });
  }

  void _toggleLayer() {
    setState(() {
      _layer = _layer == WindMapLayer.standard
          ? WindMapLayer.satellite
          : WindMapLayer.standard;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = _WindMapPalette.fromAppTheme(widget.appTheme);
    final weather = context.watch<WeatherState>();
    final settings = context.watch<SettingsState>();
    final isOffline = weather.isOffline;
    final snapshot = weather.snapshot;
    final current = snapshot.current;
    final hours = snapshot.hourly;
    final center = snapshot.location;
    final animationHours = hours.take(7).toList();
    final shouldAnimate = _isAnimating && animationHours.length >= 2;

    _syncAnimation(shouldAnimate, animationHours.length);

    return Scaffold(
      backgroundColor: colors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress =
              Curves.easeInOutSine.transform(_controller.value);
          final sample = shouldAnimate
              ? _interpolatedWind(animationHours, current, progress)
              : _WindSample.fromCurrent(current);
          final windLabelText =
              windLabel(sample.speedKph, settings.windInKph);
          final activeIndex = math.min(
            sample.activeIndex,
            math.max(animationHours.length - 1, 0),
          );
          final phase = shouldAnimate
              ? (math.sin(_controller.value * math.pi * 2 - math.pi / 2) + 1) /
                  2
              : 0.0;

          return Stack(
            children: [
              Positioned.fill(
                child: isOffline
                    ? _OfflineMapPlaceholder(colors: colors)
                    : WindMapView(
                        latitude: center.latitude,
                        longitude: center.longitude,
                        windDirectionDegrees: sample.directionDegrees,
                        windSpeedKph: sample.speedKph,
                        overlayColor: colors.accentBlue.withValues(alpha: 0.4),
                        windInKph: settings.windInKph,
                        markerColor: colors.accentBlue,
                        zoom: 9,
                        mapLayer: _layer,
                        animationPhase: phase,
                      ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CircularButton(
                              colors: colors,
                              icon: Icons.close,
                              onTap: () => Navigator.of(context).maybePop(),
                              enabled: true,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: 120,
                              child: _WindLegendCard(
                                colors: colors,
                                windInKph: settings.windInKph,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Column(
                          children: [
                            _CircularButton(
                              colors: colors,
                              icon: Icons.layers_outlined,
                              onTap: _toggleLayer,
                              enabled: !isOffline,
                            ),
                            const SizedBox(height: 12),
                            _CircularButton(
                              colors: colors,
                              icon: Icons.my_location,
                              onTap: () {},
                              enabled: !isOffline,
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _BottomTimelineCard(
                          colors: colors,
                          hours: animationHours,
                          windInKph: settings.windInKph,
                          isAnimating: shouldAnimate,
                          activeIndex: activeIndex,
                          displayWindSpeedKph: sample.speedKph,
                          onToggleAnimation: _toggleAnimation,
                          isEnabled: !isOffline,
                        ),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _MapHeader(
                            colors: colors,
                            title: snapshot.location.name,
                            subtitle: "Wind $windLabelText",
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _syncAnimation(bool shouldAnimate, int hourCount) {
    if (hourCount >= 2) {
      final span = hourCount - 1;
      final durationSeconds = (span * 2.2).clamp(10, 40).round();
      final duration = Duration(seconds: durationSeconds);
      if (_controller.duration != duration) {
        _controller.duration = duration;
      }
    }

    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
    }
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.colors,
    required this.title,
    required this.subtitle,
  });

  final _WindMapPalette colors;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.controlButtonColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}


class _CircularButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;
  final _WindMapPalette colors;

  const _CircularButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = enabled ? colors.iconColor : colors.textSecondary;
    final bgColor = enabled
        ? colors.controlButtonColor
        : colors.controlButtonColor.withValues(alpha: 0.6);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}

class _WindLegendCard extends StatelessWidget {
  final _WindMapPalette colors;
  final bool windInKph;

  const _WindLegendCard({
    required this.colors,
    required this.windInKph,
  });

  @override
  Widget build(BuildContext context) {
    final labelUnit = windInKph ? 'km/h' : 'mph';
    final speeds = [120.0, 80.0, 40.0, 0.0];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Wind ($labelUnit)",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _legendItem(Colors.redAccent, _speedLabel(speeds[0])),
          const SizedBox(height: 6),
          _legendItem(Colors.orange, _speedLabel(speeds[1])),
          const SizedBox(height: 6),
          _legendItem(Colors.green, _speedLabel(speeds[2])),
          const SizedBox(height: 6),
          _legendItem(Colors.blue, _speedLabel(speeds[3])),
        ],
      ),
    );
  }

  String _speedLabel(double kph) {
    final value = windValue(kph, windInKph).round();
    return value.toString();
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _OfflineMapPlaceholder extends StatelessWidget {
  const _OfflineMapPlaceholder({required this.colors});

  final _WindMapPalette colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: colors.textSecondary,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              'Connect to the internet to use the wind map.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _WindSample {
  final double speedKph;
  final double directionDegrees;
  final int activeIndex;

  const _WindSample({
    required this.speedKph,
    required this.directionDegrees,
    required this.activeIndex,
  });

  factory _WindSample.fromCurrent(CurrentWeather current) {
    return _WindSample(
      speedKph: current.windSpeedKph,
      directionDegrees: current.windDirectionDegrees.toDouble(),
      activeIndex: 0,
    );
  }
}

class _BottomTimelineCard extends StatelessWidget {
  final _WindMapPalette colors;
  final List<HourlyWeather> hours;
  final bool windInKph;
  final bool isAnimating;
  final int activeIndex;
  final double displayWindSpeedKph;
  final VoidCallback onToggleAnimation;
  final bool isEnabled;
  const _BottomTimelineCard({
    required this.colors,
    required this.hours,
    required this.windInKph,
    required this.isAnimating,
    required this.activeIndex,
    required this.displayWindSpeedKph,
    required this.onToggleAnimation,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final slots = hours.take(7).toList();
    final dateLabel = _formatLongDate(DateTime.now());
    final highlight = slots.isEmpty
        ? 0
        : activeIndex.clamp(0, slots.length - 1);

    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: isEnabled ? onToggleAnimation : null,
                child: Icon(
                  isAnimating ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: isEnabled
                      ? colors.textPrimary
                      : colors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Wind Speed • ${windLabel(displayWindSpeedKph, windInKph)}",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < slots.length; i++)
                _timeSlot(
                  i == 0 ? "Now" : _formatHour(slots[i].time),
                  i == highlight,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeSlot(String text, bool isSelected) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
        color: isSelected ? colors.accentBlue : colors.textSecondary,
      ),
    );
  }
}

String _formatHour(DateTime time) {
  return time.hour.toString().padLeft(2, '0');
}

String _formatLongDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return "${date.day} ${months[date.month - 1]} ${date.year} ${days[date.weekday - 1]}";
}

_WindSample _interpolatedWind(
  List<HourlyWeather> hours,
  CurrentWeather current,
  double t,
) {
  if (hours.length < 2) {
    return _WindSample.fromCurrent(current);
  }
  final span = hours.length - 1;
  final clamped = t.clamp(0.0, 1.0);
  final position = clamped * span;
  final index = position.floor().clamp(0, span - 1).toInt();
  final next = math.min(index + 1, span);
  final localT = position - index;

  final a = _windPoint(hours[index], current);
  final b = _windPoint(hours[next], current);

  final speed = _lerpDouble(a.speedKph, b.speedKph, localT);
  final direction = _lerpAngle(a.directionDegrees, b.directionDegrees, localT);

  return _WindSample(
    speedKph: speed,
    directionDegrees: direction,
    activeIndex: index,
  );
}

_WindSample _windPoint(HourlyWeather hour, CurrentWeather current) {
  return _WindSample(
    speedKph: hour.windSpeedKph,
    directionDegrees:
        (hour.windDirectionDegrees ?? current.windDirectionDegrees).toDouble(),
    activeIndex: 0,
  );
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

double _lerpAngle(double a, double b, double t) {
  final diff = ((b - a + 540) % 360) - 180;
  final value = (a + diff * t) % 360;
  return value < 0 ? value + 360 : value;
}
