import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../router/app_router.dart' show ThemePref;
import '../../../providers/settings_state.dart';
import '../../../providers/weather_state.dart';
import '../../../services/weather_models.dart';
import '../../../services/weather_utils.dart';
import '../../../services/weather_units.dart';
import '../settings_screen/settings_screen.dart';
import '../location_screen/location_screen.dart';
import '../insights_screen/insights_screen.dart';
import '../averages_screen/averages_screen.dart';
import '../windmap_screen/windmap_screen.dart';
import '../graphs_screen/temperature_graphs_screen.dart';
import '../graphs_screen/precipitation_graphs_screen.dart';
import '../../widgets/wind_map_view.dart';

class MainScreen extends StatefulWidget {
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
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final PageController _pageController;
  int _activePage = 0;

  @override
  void initState() {
    super.initState();
    final weather = context.read<WeatherState>();
    _activePage = weather.locations.isEmpty ? 0 : weather.activeIndex + 1;
    _pageController = PageController(initialPage: _activePage);
  }

  void _setPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _handlePageChanged(int index) {
    setState(() => _activePage = index);
    context.read<WeatherState>().updateActivePage(index);
  }

  void _openSettings() {
    final theme = widget.appTheme;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          appTheme: theme,
          themePref: widget.themePref,
          onThemePrefChanged: widget.onThemePrefChanged,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.appTheme;
    final weather = context.watch<WeatherState>();
    final pageCount = weather.locations.length + 1;
    final orderToken = weather.locations
        .map((loc) => loc.placeId ?? '${loc.latitude},${loc.longitude}')
        .join('|');
    if (_activePage >= pageCount) {
      _activePage = pageCount - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _pageController.jumpToPage(_activePage);
      });
    }

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: PageView.builder(
          key: ValueKey(orderToken),
          controller: _pageController,
          onPageChanged: _handlePageChanged,
          itemCount: pageCount,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                children: [
                  Expanded(
                    child: LocationsView(
                      theme: theme,
                      showBackButton: false,
                      onSelectIndex: (locationIndex) {
                        context
                            .read<WeatherState>()
                            .setActiveIndex(locationIndex);
                        _setPage(locationIndex + 1);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _BottomActions(
                      theme: theme,
                      count: pageCount,
                      active: _activePage,
                      onOpenLocations: () => _setPage(0),
                      onOpenSettings: _openSettings,
                      onDotTap: _setPage,
                    ),
                  ),
                ],
              );
            }

            final locationIndex = index - 1;
            final snapshot = weather.snapshotForIndex(locationIndex);
            return MainScreenBody(
              theme: theme,
              snapshot: snapshot,
              errorMessage: weather.errorForIndex(locationIndex),
              isOffline: weather.isOffline,
              locationIndex: locationIndex,
              pageCount: pageCount,
              activePage: _activePage,
              onOpenLocations: () => _setPage(0),
              onOpenSettings: _openSettings,
              onPageDotTap: _setPage,
            );
          },
        ),
      ),
    );
  }
}

class MainScreenBody extends StatefulWidget {
  const MainScreenBody({
    super.key,
    required this.theme,
    required this.snapshot,
    required this.errorMessage,
    required this.isOffline,
    required this.locationIndex,
    required this.pageCount,
    required this.activePage,
    required this.onOpenLocations,
    required this.onOpenSettings,
    required this.onPageDotTap,
  });

  final AppTheme theme;
  final WeatherSnapshot snapshot;
  final String? errorMessage;
  final bool isOffline;
  final int locationIndex;
  final int pageCount;
  final int activePage;
  final VoidCallback onOpenLocations;
  final VoidCallback onOpenSettings;
  final ValueChanged<int> onPageDotTap;

  @override
  State<MainScreenBody> createState() => _MainScreenBodyState();
}

class _MainScreenBodyState extends State<MainScreenBody> {
  final ScrollController _sc = ScrollController();
  double _t = 0.0;

  void _activateLocation() {
    context.read<WeatherState>().setActiveIndex(widget.locationIndex);
  }

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
    final settings = context.watch<SettingsState>();
    final useCelsius = settings.useCelsius;
    final windInKph = settings.windInKph;
    final showUmbrellaIndex = settings.showUmbrellaIndex;
    final snapshot = widget.snapshot;
    final isFallback = snapshot.isFallback;
    final current = snapshot.current;
    final hourly = snapshot.hourly;
    final daily = snapshot.daily;
    final now = DateTime.now();
    final todayRange = highLowForDate(daily, hourly, now);
    final todayDaily = dailyForDate(daily, now);
    final dailyOutlook = upcomingDaily(daily, now: now, maxDays: 5);
    final showPlaceholder = isFallback;
    final conditionText =
        showPlaceholder ? "--" : displayCondition(current.condition);
    final conditionIcon = showPlaceholder
        ? Icons.cloud_queue
        : _iconForCondition(current.condition);
    final umbrella = showPlaceholder ? null : umbrellaIndex(current);
    final summary =
        showPlaceholder ? "" : summaryText(current, windInKph: windInKph);
    final tempDisplay = tempValue(current.tempC, useCelsius).round();
    final tempText = showPlaceholder ? "--" : "$tempDisplay°";
    final todayHigh = todayRange == null
        ? null
        : tempValue(todayRange.highC, useCelsius).round();
    final todayLow = todayRange == null
        ? null
        : tempValue(todayRange.lowC, useCelsius).round();
    final hiLoText = showPlaceholder || todayRange == null
        ? "H:--  L:--"
        : "H:$todayHigh°  L:$todayLow°";
    final todayHighC = showPlaceholder ? null : todayRange?.highC;
    final avgHighC = showPlaceholder
        ? null
        : _averageDouble(dailyOutlook.map((d) => d.maxTempC).toList());
    final statusText = "Weather unavailable";
    final showErrorCard = widget.errorMessage != null && showPlaceholder;
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
            if (showUmbrellaIndex && umbrella != null)
              GestureDetector(
                onTap: () {
                  _activateLocation();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InsightsScreen(theme: theme),
                    ),
                  );
                },
                child: _UmbrellaIndexLine(
                  theme: theme,
                  index: umbrella,
                  t: _t,
                ),
              ),
            SizedBox(height: showUmbrellaIndex && umbrella != null ? 10 : 0),
            Transform.translate(
              offset: Offset(0, tempDy),
              child: _Header(
                theme: theme,
                tempSize: tempSize,
                locationName: snapshot.location.name,
                condition: conditionText,
                conditionIcon: conditionIcon,
                tempText: tempText,
                hiLoText: hiLoText,
                airQuality: snapshot.airQuality,
                isOffline: widget.isOffline,
                onTempTap: () {
                  _activateLocation();
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
              ),
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
                        if (showErrorCard) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: theme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: theme.text,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (widget.errorMessage != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.errorMessage!,
                                    style: TextStyle(
                                      color: theme.sub,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: () =>
                                      context.read<WeatherState>().refresh(),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: theme.border),
                                    foregroundColor: theme.text,
                                  ),
                                  child: const Text("Retry"),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (summary.isNotEmpty) ...[
                          _SummaryStrip(theme: theme, summary: summary),
                          const SizedBox(height: 10),
                        ],
                        _HourlyRail(
                          theme: theme,
                          hours: hourly,
                          useCelsius: useCelsius,
                          showPlaceholder: showPlaceholder,
                        ),
                        const SizedBox(height: 10),
                        _FiveDayCard(
                          theme: theme,
                          days: dailyOutlook,
                          useCelsius: useCelsius,
                          showPlaceholder: showPlaceholder,
                        ),
                        const SizedBox(height: 10),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    _activateLocation();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TemperatureGraphsScreen(
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
                                      value: showPlaceholder
                                          ? "--"
                                          : tempLabel(
                                              current.feelsLikeC, useCelsius),
                                      caption: showPlaceholder
                                          ? ""
                                          : _feelsLikeCaption(current),
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
                                  child: _MetricAqi(
                                    theme: theme,
                                    airQuality: snapshot.airQuality,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ✅ Step-3 CRUD + realtime section
                        const SizedBox(height: 10),
                        _ItemsCard(theme: theme),

                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            _activateLocation();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AveragesScreen(appTheme: theme),
                              ),
                            );
                          },
                          child: _AveragesPreview(
                            theme: theme,
                            todayHighC: todayHighC,
                            avgHighC: avgHighC,
                            useCelsius: useCelsius,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _WindCompact(
                          theme: theme,
                          windSpeed:
                              showPlaceholder ? null : current.windSpeedKph,
                          windGust: showPlaceholder ? null : current.windGustKph,
                          windDirectionDegrees: showPlaceholder
                              ? null
                              : current.windDirectionDegrees,
                          windInKph: windInKph,
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            _activateLocation();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PrecipitationGraphsScreen(appTheme: theme),
                              ),
                            );
                          },
                          child: _PrecipTile(
                            theme: theme,
                            precipProbability: todayDaily?.precipProbability,
                            precipMm: todayDaily?.precipMm,
                            showPlaceholder:
                                showPlaceholder || todayDaily == null,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: widget.isOffline
                              ? null
                              : () {
                                  _activateLocation();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          WindMapScreen(appTheme: theme),
                                    ),
                                  );
                                },
                          child: _WindMapCard(
                            theme: theme,
                            latitude: snapshot.location.latitude,
                            longitude: snapshot.location.longitude,
                            windSpeed:
                                showPlaceholder ? null : current.windSpeedKph,
                            windDirectionDegrees: showPlaceholder
                                ? null
                                : current.windDirectionDegrees,
                            windInKph: windInKph,
                            isOffline: widget.isOffline,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _BottomActions(
                          theme: theme,
                          count: widget.pageCount,
                          active: widget.activePage,
                          onOpenLocations: widget.onOpenLocations,
                          onOpenSettings: widget.onOpenSettings,
                          onDotTap: widget.onPageDotTap,
                        ),
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
  const _Header({
    required this.theme,
    required this.tempSize,
    required this.locationName,
    required this.condition,
    required this.conditionIcon,
    required this.tempText,
    required this.hiLoText,
    required this.airQuality,
    required this.isOffline,
    required this.onTempTap,
  });
  final AppTheme theme;
  final double tempSize;
  final String locationName;
  final String condition;
  final IconData conditionIcon;
  final String tempText;
  final String hiLoText;
  final AirQuality? airQuality;
  final bool isOffline;
  final VoidCallback onTempTap;

  @override
  Widget build(BuildContext context) {
    final airQualityValue = airQuality;
    final airQualityText = airQualityValue == null
        ? "AQI --"
        : "AQI ${airQualityValue.aqi}";
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.place_outlined, size: 18, color: theme.sub),
            const SizedBox(width: 6),
            Text(
              locationName,
              style: TextStyle(
                color: theme.text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (isOffline) ...[
              _Chip(
                theme: theme,
                text: "Offline",
                icon: Icons.cloud_off_rounded,
              ),
              const SizedBox(width: 8),
            ],
            _Chip(theme: theme, text: condition, icon: conditionIcon),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTempTap,
              child: Text(
                tempText,
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
                hiLoText,
                style: TextStyle(color: theme.sub, fontSize: 13),
              ),
            ),
            const Spacer(),
            _Chip(
              theme: theme,
              text: airQualityText,
              icon: Icons.blur_on,
            ),
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
  const _SummaryStrip({required this.theme, required this.summary});
  final AppTheme theme;
  final String summary;

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
        summary,
        style: TextStyle(color: theme.text, fontSize: 14, height: 1.25),
      ),
    );
  }
}

class _HourlyRail extends StatelessWidget {
  const _HourlyRail({
    required this.theme,
    required this.hours,
    required this.useCelsius,
    required this.showPlaceholder,
  });
  final AppTheme theme;
  final List<HourlyWeather> hours;
  final bool useCelsius;
  final bool showPlaceholder;

  @override
  Widget build(BuildContext context) {
    final hasData = !showPlaceholder && hours.isNotEmpty;
    final slice = hasData ? hours.take(12).toList() : <HourlyWeather>[];
    final placeholders = hasData
        ? <DateTime>[]
        : List.generate(6, (i) {
            final now = DateTime.now();
            return now.add(Duration(hours: i * 3));
          });
    final count = hasData ? slice.length : placeholders.length;
    final tiles = List.generate(count, (i) {
      final time = hasData ? slice[i].time : placeholders[i];
      final label = i == 0 ? "Now" : _formatHour(time);
      final rainPercent = hasData
          ? (normalizeProbability(slice[i].precipProbability) * 100).round()
          : null;
      final temp = hasData
          ? tempValue(slice[i].tempC, useCelsius).round()
          : null;
      return _HourlyTile(
        theme: theme,
        hour: label,
        temp: temp,
        rain: rainPercent,
      );
    });

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => tiles[i],
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
  final int? temp;
  final int? rain;

  @override
  Widget build(BuildContext context) {
    final bool rainy = rain != null && rain! >= 40;
    final tempText = temp == null ? "--" : "$temp°";
    final rainText = rain == null ? "--" : "$rain%";
    final icon = rain == null
        ? Icons.cloud_queue
        : (rainy ? Icons.beach_access : Icons.cloud);

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
          Icon(icon, color: theme.text, size: 20),
          Text(
            tempText,
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
              Text(
                rainText,
                style: TextStyle(color: theme.sub, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FiveDayCard extends StatelessWidget {
  const _FiveDayCard({
    required this.theme,
    required this.days,
    required this.useCelsius,
    required this.showPlaceholder,
  });
  final AppTheme theme;
  final List<DailyWeather> days;
  final bool useCelsius;
  final bool showPlaceholder;

  @override
  Widget build(BuildContext context) {
    final bool placeholder = showPlaceholder || days.isEmpty;
    final maxRows = 5;
    final now = DateTime.now();
    final data = placeholder ? <DailyWeather>[] : days.take(maxRows).toList();
    final rows = List.generate(maxRows, (i) {
      if (i < data.length) {
        final day = data[i];
        final hi = tempValue(day.maxTempC, useCelsius).round();
        final lo = tempValue(day.minTempC, useCelsius).round();
        return _DayRow(
          theme: theme,
          day: _dayLabel(day.date),
          hi: hi,
          lo: lo,
          icon: _iconForCondition(day.condition),
        );
      }
      final date = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      return _DayRow(
        theme: theme,
        day: _dayLabel(date),
        hi: null,
        lo: null,
        icon: Icons.cloud_queue,
      );
    });

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
          ...rows,
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
  final int? hi;
  final int? lo;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final double full = 160;
    final int span = hi == null || lo == null ? 0 : (hi! - lo!).clamp(0, 20);
    final double bar = (span / 20.0) * full;
    final hiLoText =
        hi == null || lo == null ? "-- / --" : "$hi° / $lo°";

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
              hiLoText,
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
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              caption,
              style: TextStyle(color: theme.sub, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricAqi extends StatelessWidget {
  const _MetricAqi({
    required this.theme,
    required this.airQuality,
  });
  final AppTheme theme;
  final AirQuality? airQuality;

  @override
  Widget build(BuildContext context) {
    final aqi = airQuality?.aqi;
    final category = airQuality?.category;
    final percent = _aqiPercent(aqi);
    final displayText =
        aqi == null ? "AQI --" : "AQI $aqi • ${category ?? 'Unknown'}";
    final detailText = aqi == null
        ? "Air quality data is unavailable right now."
        : _aqiDetail(category ?? 'Unknown');

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
                painter: _RingGauge(theme: theme, percent: percent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayText,
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
            detailText,
            style: TextStyle(color: theme.sub, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

double _aqiPercent(int? aqi) {
  if (aqi == null) return 0.0;
  return (aqi / 500).clamp(0.0, 1.0);
}

String _aqiDetail(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('good') || lower.contains('excellent')) {
    return "Air quality is satisfying and poses little or no risk.";
  }
  if (lower.contains('moderate')) {
    return "Air quality is acceptable; sensitive groups should take care.";
  }
  if (lower.contains('poor') || lower.contains('unhealthy')) {
    return "Air quality is poor; consider reducing outdoor activity.";
  }
  return "Air quality conditions vary across the area.";
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
  const _AveragesPreview({
    required this.theme,
    required this.todayHighC,
    required this.avgHighC,
    required this.useCelsius,
  });
  final AppTheme theme;
  final double? todayHighC;
  final double? avgHighC;
  final bool useCelsius;

  @override
  Widget build(BuildContext context) {
    final hasData = todayHighC != null && avgHighC != null;
    final delta = hasData ? todayHighC! - avgHighC! : 0.0;
    final sign = delta >= 0 ? "+" : "-";
    final deltaValue =
        hasData ? tempValue(delta.abs(), useCelsius).round() : null;
    final avgLabel = hasData ? tempLabel(avgHighC!, useCelsius) : "--";
    final deltaText = hasData ? "$sign$deltaValue°" : "--";
    final lineText = hasData
        ? "Today’s high is $sign$deltaValue° vs avg $avgLabel."
        : "Outlook data is updating.";

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
                  lineText,
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
            deltaText,
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
  const _WindCompact({
    required this.theme,
    required this.windSpeed,
    required this.windGust,
    required this.windDirectionDegrees,
    required this.windInKph,
  });
  final AppTheme theme;
  final double? windSpeed;
  final double? windGust;
  final int? windDirectionDegrees;
  final bool windInKph;

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
          Expanded(
            child: _WindMeta(
              theme: theme,
              windSpeed: windSpeed,
              windGust: windGust,
              windDirectionDegrees: windDirectionDegrees,
              windInKph: windInKph,
            ),
          ),
          const SizedBox(width: 8),
          _WindCompass(
            theme: theme,
            windSpeed: windSpeed,
            windDirectionDegrees: windDirectionDegrees,
            windInKph: windInKph,
          ),
        ],
      ),
    );
  }
}

class _WindMeta extends StatelessWidget {
  const _WindMeta({
    required this.theme,
    required this.windSpeed,
    required this.windGust,
    required this.windDirectionDegrees,
    required this.windInKph,
  });
  final AppTheme theme;
  final double? windSpeed;
  final double? windGust;
  final int? windDirectionDegrees;
  final bool windInKph;

  @override
  Widget build(BuildContext context) {
    final speedText =
        windSpeed == null ? "--" : windLabel(windSpeed!, windInKph);
    final gustText = windGust == null ? "--" : windLabel(windGust!, windInKph);
    final directionText = windDirectionDegrees == null
        ? "--"
        : "${windDirectionDegrees!.round()}° ${windDirectionLabel(windDirectionDegrees!)}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(theme: theme, icon: Icons.air_rounded, title: "WIND"),
        const SizedBox(height: 6),
        _KeyRow(
          theme: theme,
          k: "Speed",
          v: speedText,
        ),
        _KeyRow(
          theme: theme,
          k: "Gusts",
          v: gustText,
        ),
        _KeyRow(
          theme: theme,
          k: "Direction",
          v: directionText,
        ),
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
  const _WindCompass({
    required this.theme,
    required this.windSpeed,
    required this.windDirectionDegrees,
    required this.windInKph,
  });
  final AppTheme theme;
  final double? windSpeed;
  final int? windDirectionDegrees;
  final bool windInKph;

  @override
  Widget build(BuildContext context) {
    final speedValue = windSpeed == null
        ? "--"
        : windValue(windSpeed!, windInKph).round().toString();
    final unitText = windSpeed == null ? "" : (windInKph ? "km/h" : "mph");

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(92, 92),
            painter: _CompassPainter(theme, windDirectionDegrees),
          ),
          Text(
            unitText.isEmpty ? speedValue : "$speedValue\n$unitText",
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
  _CompassPainter(this.theme, this.windDirectionDegrees);
  final AppTheme theme;
  final int? windDirectionDegrees;

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

    if (windDirectionDegrees == null) return;

    final double angle = (windDirectionDegrees! - 90) * math.pi / 180;
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
      oldDelegate.theme != theme ||
      oldDelegate.windDirectionDegrees != windDirectionDegrees;
}

class _PrecipTile extends StatelessWidget {
  const _PrecipTile({
    required this.theme,
    required this.precipProbability,
    required this.precipMm,
    required this.showPlaceholder,
  });
  final AppTheme theme;
  final double? precipProbability;
  final double? precipMm;
  final bool showPlaceholder;

  @override
  Widget build(BuildContext context) {
    final chanceText = showPlaceholder || precipProbability == null
        ? "--"
        : "${(normalizeProbability(precipProbability!) * 100).round()}%";
    final mmText = showPlaceholder || precipMm == null
        ? "--"
        : (precipMm! >= 10
            ? precipMm!.round().toString()
            : precipMm!.toStringAsFixed(1));

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
                "$mmText mm today",
                style: TextStyle(
                  color: theme.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                "Chance: $chanceText",
                style: TextStyle(color: theme.sub),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WindMapCard extends StatelessWidget {
  const _WindMapCard({
    required this.theme,
    required this.latitude,
    required this.longitude,
    required this.windSpeed,
    required this.windDirectionDegrees,
    required this.windInKph,
    required this.isOffline,
  });
  final AppTheme theme;
  final double latitude;
  final double longitude;
  final double? windSpeed;
  final int? windDirectionDegrees;
  final bool windInKph;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final hasWind = windSpeed != null && windDirectionDegrees != null;
    final label = hasWind
        ? "Wind ${windLabel(windSpeed!, windInKph)} • ${windDirectionLabel(windDirectionDegrees!)}"
        : "Wind --";

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
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                Positioned.fill(
                  child: isOffline
                      ? _OfflineMapTile(theme: theme)
                      : WindMapView(
                          latitude: latitude,
                          longitude: longitude,
                          windDirectionDegrees:
                              (windDirectionDegrees ?? 0).toDouble(),
                          windSpeedKph: windSpeed ?? 0,
                          overlayColor: hasWind
                              ? theme.accent.withValues(alpha: 0.35)
                              : Colors.transparent,
                          windInKph: windInKph,
                          markerColor: hasWind ? theme.accent : theme.sub,
                          zoom: 7,
                        ),
                ),
                if (!isOffline)
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.card.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.border),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(color: theme.sub, fontSize: 12),
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

class _OfflineMapTile extends StatelessWidget {
  const _OfflineMapTile({required this.theme});

  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.cardAlt,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: theme.sub, size: 26),
            const SizedBox(height: 6),
            Text(
              'Connect to the internet to use the wind map.',
              style: TextStyle(color: theme.sub, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.theme,
    required this.count,
    required this.active,
    required this.onOpenLocations,
    required this.onOpenSettings,
    required this.onDotTap,
  });
  final AppTheme theme;
  final int count;
  final int active;
  final VoidCallback onOpenLocations;
  final VoidCallback onOpenSettings;
  final ValueChanged<int> onDotTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundAction(
          theme: theme,
          icon: Icons.list_alt,
          tooltip: "Locations",
          onTap: onOpenLocations,
        ),
        const Spacer(),
        _PagerDots(
          theme: theme,
          count: count,
          active: active,
          onDotTap: onDotTap,
        ),
        const Spacer(),
        _RoundAction(
          theme: theme,
          icon: Icons.settings,
          tooltip: "Settings",
          onTap: onOpenSettings,
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
    required this.onDotTap,
  });
  final AppTheme theme;
  final int count;
  final int active;
  final ValueChanged<int> onDotTap;

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
            child: GestureDetector(
              onTap: () => onDotTap(i),
              child: Container(
                width: on ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: on
                      ? theme.accent
                      : theme.sub.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(6),
                ),
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

IconData _iconForCondition(String condition) {
  final c = condition.toLowerCase();
  if (c.contains('thunder') || c.contains('storm')) {
    return Icons.flash_on;
  }
  if (c.contains('rain') || c.contains('drizzle')) {
    return Icons.beach_access;
  }
  if (c.contains('snow') || c.contains('sleet')) {
    return Icons.ac_unit;
  }
  if (c.contains('fog') || c.contains('mist') || c.contains('haze')) {
    return Icons.blur_on;
  }
  if (c.contains('sun') || c.contains('clear')) {
    return Icons.wb_sunny_outlined;
  }
  if (c.contains('cloud')) return Icons.cloud;
  return Icons.cloud_queue;
}

String _formatHour(DateTime time) {
  final h = time.hour.toString().padLeft(2, '0');
  return h;
}

String _dayLabel(DateTime date) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[date.weekday - 1];
}

String _feelsLikeCaption(CurrentWeather current) {
  final diff = (current.feelsLikeC - current.tempC).round();
  if (diff <= -2) return "Wind makes it cooler";
  if (diff >= 2) return "Feels warmer than actual";
  return "Feels close to actual";
}

double? _averageDouble(List<double> values) {
  if (values.isEmpty) return null;
  final sum = values.fold<double>(0.0, (acc, v) => acc + v);
  return sum / values.length;
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
