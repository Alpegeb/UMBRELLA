import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';

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

class WindMapScreen extends StatelessWidget {
  const WindMapScreen({super.key, required this.appTheme});
  final AppTheme appTheme;

  @override
  Widget build(BuildContext context) {
    final colors = _WindMapPalette.fromAppTheme(appTheme);

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Container(
            color: colors.background,
            child: Center(
              child: Text(
                "Map View",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ).copyWith(color: colors.textSecondary.withOpacity(0.3)),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CircularButton(
                        colors: colors,
                        icon: Icons.close,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(height: 16),
                      _WindLegendCard(colors: colors),
                    ],
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Column(
                      children: [
                        _CircularButton(
                          colors: colors,
                          icon: Icons.layers_outlined,
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        _CircularButton(
                          colors: colors,
                          icon: Icons.my_location,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _BottomTimelineCard(colors: colors),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final _WindMapPalette colors;

  const _CircularButton({
    required this.icon,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.controlButtonColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: colors.iconColor, size: 22),
      ),
    );
  }
}

class _WindLegendCard extends StatelessWidget {
  final _WindMapPalette colors;

  const _WindLegendCard({required this.colors});

  @override
  Widget build(BuildContext context) {
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
            "Wind (km/\nh)",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _legendItem(Colors.redAccent, "120"),
          const SizedBox(height: 6),
          _legendItem(Colors.orange, "80"),
          const SizedBox(height: 6),
          _legendItem(Colors.green, "40"),
          const SizedBox(height: 6),
          _legendItem(Colors.blue, "0"),
        ],
      ),
    );
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

class _BottomTimelineCard extends StatelessWidget {
  final _WindMapPalette colors;
  const _BottomTimelineCard({required this.colors});

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.play_arrow_rounded, color: colors.textPrimary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Wind Speed",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    "6 November 2025 Thursday",
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
              _timeSlot("14", false),
              _timeSlot("Now", true),
              _timeSlot("18", false),
              _timeSlot("20", false),
              _timeSlot("22", false),
              _timeSlot("00", false),
              _timeSlot("02", false),
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