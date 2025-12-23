import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../../core/theme_pref.dart';
import '../../../providers/items_state.dart';

import '../settings_screen/settings_screen.dart';
import '../location_screen/location_screen.dart';
import '../insights_screen/insights_screen.dart';
import '../averages_screen/averages_screen.dart';
import '../windmap_screen/windmap_screen.dart';
import '../graphs_screen/temperature_graphs_screen.dart';
import '../graphs_screen/precipitation_graphs_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({
    super.key,
    required this.appTheme,
    required this.themePref,
    required this.onThemePrefChanged,
  });

  final AppTheme appTheme;
  final ThemePref themePref;
  final ValueChanged<ThemePref> onThemePrefChanged;

  @override
  Widget build(BuildContext context) {
    final theme = appTheme;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: MainScreenBody(
          theme: theme,
          themePref: themePref,
          onThemePrefChanged: onThemePrefChanged,
        ),
      ),
    );
  }
}

class MainScreenBody extends StatefulWidget {
  const MainScreenBody({
    super.key,
    required this.theme,
    required this.themePref,
    required this.onThemePrefChanged,
  });

  final AppTheme theme;
  final ThemePref themePref;
  final ValueChanged<ThemePref> onThemePrefChanged;

  @override
  State<MainScreenBody> createState() => _MainScreenBodyState();
}

class _MainScreenBodyState extends State<MainScreenBody> {
  final ScrollController _sc = ScrollController();
  double _t = 0.0;

  ThemePref get themePref => widget.themePref;
  ValueChanged<ThemePref> get onThemePrefChanged => widget.onThemePrefChanged;

  @override
  void initState() {
    super.initState();
    _sc.addListener(() {
      final v = (_sc.offset / 120.0).clamp(0.0, 1.0);
      if ((v - _t).abs() > 0.001) {
        setState(() => _t = v);
      }
    });
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final tempSize = lerpDouble(56, 36, _t)!;
    final tempDy = lerpDouble(0, -6, _t)!;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.2,
          center: const Alignment(-0.6, -0.9),
          colors: [
            theme.bg.withValues(alpha: 0.95),
            theme.bg,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InsightsScreen(theme: theme),
                  ),
                );
              },
              child: _UmbrellaIndexLine(theme: theme, index: 7.3, t: _t),
            ),
            const SizedBox(height: 10),
            Transform.translate(
              offset: Offset(0, tempDy),
              child: _Header(theme: theme, tempSize: tempSize),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ScrollConfiguration(
                  behavior: const _NoGlowScroll(),
                  child: SingleChildScrollView(
                    controller: _sc,
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        _SummaryStrip(theme: theme),
                        const SizedBox(height: 10),
                        _HourlyRail(theme: theme),
                        const SizedBox(height: 10),
                        _FiveDayCard(theme: theme),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TemperatureGraphsScreen(
                                        appTheme: theme,
                                        initialMode: TempMode.actualVsFeels,
                                      ),
                                    ),
                                  );
                                },
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(minHeight: 132),
                                  child: _MetricCard(
                                    theme: theme,
                                    title: "FEELS LIKE",
                                    value: "13°",
                                    caption: "Wind makes it cooler",
                                    icon: Icons.thermostat_rounded,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(minHeight: 132),
                                child: _MetricAqi(theme: theme),
                              ),
                            ),
                          ],
                        ),

                        // ✅ Step-3 CRUD + realtime section
                        const SizedBox(height: 10),
                        _ItemsCard(theme: theme),

                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AveragesScreen(appTheme: theme),
                              ),
                            );
                          },
                          child: _AveragesPreview(theme: theme),
                        ),
                        const SizedBox(height: 10),
                        _WindCompact(theme: theme),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PrecipitationGraphsScreen(appTheme: theme),
                              ),
                            );
                          },
                          child: _PrecipTile(theme: theme),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WindMapScreen(appTheme: theme),
                              ),
                            );
                          },
                          child: _WindMapCard(theme: theme),
                        ),
                        const SizedBox(height: 16),
                        _BottomActions(theme: theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ Firestore Items UI (Add / Edit / Delete) — uses ItemsState (realtime)
class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Consumer<ItemsState>(
      builder: (context, st, _) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.border),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SectionLabel(
                    theme: theme,
                    icon: Icons.cloud_done,
                    title: "YOUR ITEMS (FIRESTORE)",
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: "Add",
                    onPressed: () => _openAddDialog(context),
                    icon: Icon(Icons.add_circle_outline, color: theme.text),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (st.loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(theme.accent),
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (st.error != null)
                Text(st.error!, style: const TextStyle(color: Colors.red))
              else if (st.items.isEmpty)
                Text(
                  "No items yet. Tap + to add one.",
                  style: TextStyle(color: theme.sub),
                )
              else
                Column(
                  children: st.items.map((m) {
                    final id = (m['id'] ?? '').toString();
                    final title = (m['title'] ?? '').toString();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.border),
                        ),
                        child: ListTile(
                          title: Text(
                            title,
                            style: TextStyle(
                              color: theme.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            "Realtime • owned by user",
                            style: TextStyle(color: theme.sub, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: "Edit",
                                onPressed: () =>
                                    _openEditDialog(context, id, title),
                                icon: Icon(Icons.edit, color: theme.text),
                              ),
                              IconButton(
                                tooltip: "Delete",
                                onPressed: () => st.remove(id),
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAddDialog(BuildContext context) async {
    final items = context.read<ItemsState>(); // ✅ async gap öncesi al
    final ctrl = TextEditingController();

    final ok = await _openTextDialog(
      context,
      title: "Add Item",
      hint: "Title",
      controller: ctrl,
      confirmText: "Add",
    );
    if (ok != true) return;

    final title = ctrl.text.trim();
    if (title.isEmpty) return;

    await items.add(title);
  }

  Future<void> _openEditDialog(
    BuildContext context,
    String id,
    String currentTitle,
  ) async {
    final items = context.read<ItemsState>(); // ✅ async gap öncesi al
    final ctrl = TextEditingController(text: currentTitle);

    final ok = await _openTextDialog(
      context,
      title: "Edit Item",
      hint: "Title",
      controller: ctrl,
      confirmText: "Save",
    );
    if (ok != true) return;

    final title = ctrl.text.trim();
    if (title.isEmpty) return;

    await items.update(id, title);
  }

  Future<bool?> _openTextDialog(
    BuildContext context, {
    required String title,
    required String hint,
    required TextEditingController controller,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final bg = Theme.of(ctx).scaffoldBackgroundColor;
        final isDark = bg.computeLuminance() < 0.5;
        final textColor = isDark ? Colors.white : Colors.black;
        final subColor = isDark ? Colors.white70 : Colors.black54;
        final borderColor = isDark ? Colors.white54 : Colors.black45;
        final primary = Theme.of(ctx).colorScheme.primary;

        InputDecoration deco(String label) => InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: subColor),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primary, width: 2),
              ),
            );

        return AlertDialog(
          title: Text(title, style: TextStyle(color: textColor)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: textColor),
            decoration: deco(hint),
            onSubmitted: (_) => Navigator.pop(ctx, true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }
}

class _UmbrellaIndexLine extends StatelessWidget {
  const _UmbrellaIndexLine({
    required this.theme,
    required this.index,
    required this.t,
  });

  final AppTheme theme;
  final double index;
  final double t;

  static const Color kIndicatorColor = Color(0xFF00E676);

  @override
  Widget build(BuildContext context) {
    final clamped = index.clamp(0, 10).toDouble();
    final fade = 1.0 - t;

    final double barHeight = lerpDouble(16, 4, t)!;
    final double radius = lerpDouble(16, 3, t)!;
    final double padV = lerpDouble(12, 4, t)!;
    final double padH = lerpDouble(14, 0, t)!;
    final double borderA = lerpDouble(1.0, 0.0, t)!;
    final double bgA = lerpDouble(1.0, 0.0, t)!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
      decoration: BoxDecoration(
        color: theme.card.withValues(alpha: 0.98 * bgA),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: theme.border.withValues(alpha: borderA)),
        boxShadow: bgA > 0.01
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ]
            : null,
      ),
      child: Column(
        children: [
          Opacity(
            opacity: fade,
            child: IgnorePointer(
              ignoring: t > 0.98,
              child: Row(
                children: [
                  Icon(Icons.umbrella_outlined, color: kIndicatorColor),
                  const SizedBox(width: 8),
                  Text(
                    "Umbrella Index",
                    style: TextStyle(
                      color: theme.sub,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${clamped.toStringAsFixed(1)}/10",
                    style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: fade > 0 ? 8 * fade : 4),
          SizedBox(
            height: barHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final dotSize = barHeight;
                final centerX = (clamped / 10.0) * (w - 1);
                final left =
                    (centerX - dotSize / 2).clamp(0.0, w - dotSize);

                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(barHeight),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            theme.rainy,
                            Color.lerp(theme.rainy, theme.sunny, 0.5)!,
                            theme.sunny,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: left,
                      top: 0,
                      width: dotSize,
                      height: dotSize,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: kIndicatorColor,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (fade > 0.01) ...[
            const SizedBox(height: 6),
            Opacity(
              opacity: fade,
              child: Text(
                _caption(clamped),
                style: TextStyle(color: theme.sub, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _caption(double idx) {
    if (idx >= 8.5) return "Sunny & calm — no umbrella needed.";
    if (idx >= 6.0) return "Mostly fine — brief showers possible.";
    if (idx >= 3.5) return "Changeable — carry a compact umbrella.";
    return "Wet & windy — definitely bring an umbrella.";
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.theme, required this.tempSize});
  final AppTheme theme;
  final double tempSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.place_outlined, size: 18, color: theme.sub),
            const SizedBox(width: 6),
            Text(
              "Istanbul",
              style: TextStyle(
                color: theme.text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            _Chip(theme: theme, text: "Light rain", icon: Icons.beach_access),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TemperatureGraphsScreen(
                      appTheme: theme,
                      initialMode: TempMode.actualOnly,
                    ),
                  ),
                );
              },
              child: Text(
                "15°",
                style: TextStyle(
                  color: theme.text,
                  fontSize: tempSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "H:19°  L:12°",
                style: TextStyle(color: theme.sub, fontSize: 13),
              ),
            ),
            const Spacer(),
            _Chip(theme: theme, text: "AQI 42", icon: Icons.blur_on),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.theme, required this.text, required this.icon});
  final AppTheme theme;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.sub),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: theme.sub,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      child: Text(
        "Cloudy overnight. Light showers after midnight. Gusts up to 30 km/h.",
        style: TextStyle(color: theme.text, fontSize: 14, height: 1.25),
      ),
    );
  }
}

class _HourlyRail extends StatelessWidget {
  const _HourlyRail({required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(12, (i) {
      final h = (DateTime.now().hour + i) % 24;
      final rain = [10, 25, 55, 70][i % 4];
      return _HourlyTile(
        theme: theme,
        hour: i == 0 ? "Now" : "$h",
        temp: 15 + (i % 4),
        rain: rain,
      );
    });

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: hours.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => hours[i],
      ),
    );
  }
}

class _HourlyTile extends StatelessWidget {
  const _HourlyTile({
    required this.theme,
    required this.hour,
    required this.temp,
    required this.rain,
  });

  final AppTheme theme;
  final String hour;
  final int temp;
  final int rain;

  @override
  Widget build(BuildContext context) {
    final bool rainy = rain >= 40;

    return Container(
      width: 84,
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hour, style: TextStyle(color: theme.sub, fontSize: 12)),
          Icon(
            rainy ? Icons.beach_access : Icons.cloud,
            color: theme.text,
            size: 20,
          ),
          Text(
            "$temp°",
            style: TextStyle(
              color: theme.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water_drop, size: 12, color: theme.sub),
              const SizedBox(width: 4),
              Text("$rain%", style: TextStyle(color: theme.sub, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FiveDayCard extends StatelessWidget {
  const _FiveDayCard({required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    final days = [
      _DayRow(theme: theme, day: "Wed", hi: 19, lo: 12, icon: Icons.cloud),
      _DayRow(theme: theme, day: "Thu", hi: 18, lo: 11, icon: Icons.cloud),
      _DayRow(
        theme: theme,
        day: "Fri",
        hi: 16,
        lo: 10,
        icon: Icons.beach_access,
      ),
      _DayRow(theme: theme, day: "Sat", hi: 14, lo: 9, icon: Icons.cloud_queue),
      _DayRow(
        theme: theme,
        day: "Sun",
        hi: 15,
        lo: 8,
        icon: Icons.wb_sunny_outlined,
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(
            theme: theme,
            icon: Icons.event_note,
            title: "5-DAY OUTLOOK",
          ),
          const SizedBox(height: 6),
          ...days,
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.theme,
    required this.day,
    required this.hi,
    required this.lo,
    required this.icon,
  });

  final AppTheme theme;
  final String day;
  final int hi;
  final int lo;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final double full = 160;
    final int span = (hi - lo).clamp(0, 20);
    final double bar = (span / 20.0) * full;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(day, style: TextStyle(color: theme.text)),
          ),
          SizedBox(width: 26, child: Icon(icon, color: theme.text, size: 18)),
          SizedBox(
            width: 170,
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.cardAlt,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Container(
                  height: 6,
                  width: bar,
                  decoration: BoxDecoration(
                    color: theme.accent.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 60,
            child: Text(
              "$hi° / $lo°",
              textAlign: TextAlign.end,
              style: TextStyle(color: theme.sub),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.theme,
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
  });

  final AppTheme theme;
  final String title;
  final String value;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(theme: theme, icon: icon, title: title),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: theme.text,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(caption, style: TextStyle(color: theme.sub, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MetricAqi extends StatelessWidget {
  const _MetricAqi({required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    const aqi = 42;

    return Container(
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(theme: theme, icon: Icons.blur_on, title: "AIR QUALITY"),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomPaint(
                size: const Size(40, 40),
                painter: _RingGauge(theme: theme, percent: 0.22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "AQI $aqi • Good",
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Air quality is satisfying and poses little or no risk.",
            style: TextStyle(color: theme.sub, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RingGauge extends CustomPainter {
  _RingGauge({required this.theme, required this.percent});
  final AppTheme theme;
  final double percent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final base = Paint()
      ..color = theme.cardAlt
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..shader = SweepGradient(
        colors: [theme.accent, theme.accent.withValues(alpha: 0.6)],
      ).createShader(Rect.fromCircle(center: c, radius: r))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(c, r - 3, base);

    final sweep = 2 * math.pi * percent;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 3),
      -math.pi / 2,
      sweep,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingGauge oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.theme != theme;
}

class _AveragesPreview extends StatelessWidget {
  const _AveragesPreview({required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Icon(Icons.show_chart_rounded, color: theme.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DAILY AVERAGE",
                  style: TextStyle(
                    color: theme.sub,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Today’s high is 6° above normal (21° vs 15°).",
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "+6°",
            style: TextStyle(
              color: theme.sunny,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WindCompact extends StatelessWidget {
  const _WindCompact({required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(child: _WindMeta(theme: theme)),
          const SizedBox(width: 8),
          _WindCompass(theme: theme),
        ],
      ),
    );
  }
}

class _WindMeta extends StatelessWidget {
  const _WindMeta({required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(theme: theme, icon: Icons.air_rounded, title: "WIND"),
        const SizedBox(height: 6),
        _KeyRow(theme: theme, k: "Speed", v: "13 km/h"),
        _KeyRow(theme: theme, k: "Gusts", v: "30 km/h"),
        _KeyRow(theme: theme, k: "Direction", v: "53° NE"),
      ],
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.theme, required this.k, required this.v});
  final AppTheme theme;
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 86, child: Text(k, style: TextStyle(color: theme.sub))),
          Text(v, style: TextStyle(color: theme.text)),
        ],
      ),
    );
  }
}

class _WindCompass extends StatelessWidget {
  const _WindCompass({required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: const Size(92, 92), painter: _CompassPainter(theme)),
          Text(
            "13\nkm/h",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.text,
              fontSize: 12,
              height: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter(this.theme);
  final AppTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;

    final bg = Paint()..color = theme.cardAlt;
    final border = Paint()
      ..color = theme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(c, r, bg);
    canvas.drawCircle(c, r, border);

    final tick = Paint()
      ..color = theme.sub
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(c.dx, c.dy - r),
      Offset(c.dx, c.dy - r + 8),
      tick,
    );

    final double angle = -45 * math.pi / 180;
    final double ux = math.cos(angle);
    final double uy = math.sin(angle);

    final double startR = r * 0.34;
    final double baseR = r * 0.66;
    final double tipR = r * 0.80;

    final Offset start = Offset(c.dx + startR * ux, c.dy + startR * uy);
    final Offset base = Offset(c.dx + baseR * ux, c.dy + baseR * uy);
    final Offset tip = Offset(c.dx + tipR * ux, c.dy + tipR * uy);

    final Paint shaft = Paint()
      ..color = theme.accent
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, base, shaft);

    const double headLen = 8;
    const double headWidth = 7;
    final Offset headBase = Offset(
      tip.dx - ux * headLen,
      tip.dy - uy * headLen,
    );
    final double px = -uy, py = ux;

    final Offset p1 = tip;
    final Offset p2 = Offset(
      headBase.dx + px * (headWidth / 2),
      headBase.dy + py * (headWidth / 2),
    );
    final Offset p3 = Offset(
      headBase.dx - px * (headWidth / 2),
      headBase.dy - py * (headWidth / 2),
    );

    final Path head = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    final Paint headPaint = Paint()..color = theme.accent;
    canvas.drawPath(head, headPaint);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.theme != theme;
}

class _PrecipTile extends StatelessWidget {
  const _PrecipTile({required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            theme: theme,
            icon: Icons.invert_colors,
            title: "PRECIPITATION",
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.beach_access, color: theme.text),
              const SizedBox(width: 10),
              Text(
                "0 mm today",
                style: TextStyle(
                  color: theme.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text("Chance: 35%", style: TextStyle(color: theme.sub)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WindMapCard extends StatelessWidget {
  const _WindMapCard({required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(theme: theme, icon: Icons.map_rounded, title: "WIND MAP"),
          const SizedBox(height: 8),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: theme.cardAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            alignment: Alignment.center,
            child: Text("Map Placeholder", style: TextStyle(color: theme.sub)),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_MainScreenBodyState>();
    final themePref = state?.themePref;
    final onThemePrefChanged = state?.onThemePrefChanged;

    return Row(
      children: [
        _RoundAction(
          theme: theme,
          icon: Icons.list_alt,
          tooltip: "Locations",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LocationScreen(theme: theme),
              ),
            );
          },
        ),
        const Spacer(),
        _PagerDots(theme: theme, count: 5, active: 1),
        const Spacer(),
        _RoundAction(
          theme: theme,
          icon: Icons.settings,
          tooltip: "Settings",
          onTap: () {
            if (themePref == null || onThemePrefChanged == null) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  appTheme: theme,
                  themePref: themePref,
                  onThemePrefChanged: onThemePrefChanged,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.theme,
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final AppTheme theme;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.cardAlt,
            shape: BoxShape.circle,
            border: Border.all(color: theme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: theme.text, size: 22),
        ),
      ),
    );
  }
}

class _PagerDots extends StatelessWidget {
  const _PagerDots({
    required this.theme,
    required this.count,
    required this.active,
  });
  final AppTheme theme;
  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardAlt,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (i) {
          final on = i == active;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: on ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: on ? theme.accent : theme.sub.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.theme,
    required this.icon,
    required this.title,
  });

  final AppTheme theme;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

class _NoGlowScroll extends ScrollBehavior {
  const _NoGlowScroll();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
