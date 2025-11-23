import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../router/app_router.dart' show ThemePref;

/// SettingsScreen controls app-wide theme via a callback,
/// and also holds a local copy of the selected theme so
/// the segment control updates immediately.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.appTheme,
    required this.themePref,
    required this.onThemePrefChanged,
  });

  final AppTheme appTheme;
  final ThemePref themePref;
  final ValueChanged<ThemePref> onThemePrefChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemePref _selectedPref;

  @override
  void initState() {
    super.initState();
    _selectedPref = widget.themePref;
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the root app changes the theme pref externally,
    // keep the local selection in sync.
    if (oldWidget.themePref != widget.themePref) {
      _selectedPref = widget.themePref;
    }
  }

  void _handleThemeChange(ThemePref pref) {
    setState(() {
      _selectedPref = pref; // updates the segment control immediately
    });
    widget.onThemePrefChanged(pref); // updates global app theme
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.appTheme;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Settings",
          style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
        ),
      ),
      body: SettingsPage(
        title: "Settings",
        colors: c,
        themePref: _selectedPref,
        onSetThemePref: _handleThemeChange,
      ),
    );
  }
}

// ================== SETTINGS PAGE (MAIN) ==================
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.title,
    required this.colors,
    required this.themePref,
    required this.onSetThemePref,
  });

  final String title;
  final AppTheme colors;
  final ThemePref themePref;
  final ValueChanged<ThemePref> onSetThemePref;

  TextStyle getTitleStyle() =>
      TextStyle(color: colors.text, fontWeight: FontWeight.w700);
  TextStyle getLabelStyle() =>
      TextStyle(color: colors.text, fontWeight: FontWeight.w600);
  TextStyle getSubStyle() => TextStyle(color: colors.sub);

  @override
  Widget build(BuildContext context) {
    final labelStyle = getLabelStyle();
    final subStyle = getSubStyle();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          _Section(
            title: "Appearance",
            color: colors,
            children: [
              _ThemeSegment(
                color: colors,
                value: themePref,
                onChanged: onSetThemePref,
              ),
              _SwitchTile(
                color: colors,
                icon: Icons.umbrella_outlined,
                title: "Show Umbrella Index",
                subtitle: "Display the top index bar",
                value: true,
                onChanged: (_) {},
                labelStyle: labelStyle,
                subStyle: subStyle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: "Units",
            color: colors,
            children: [
              _SwitchTile(
                color: colors,
                icon: Icons.thermostat,
                title: "Temperature in Celsius",
                subtitle: "Switch to Fahrenheit if disabled",
                value: true,
                onChanged: (_) {},
                labelStyle: labelStyle,
                subStyle: subStyle,
              ),
              _SwitchTile(
                color: colors,
                icon: Icons.air_rounded,
                title: "Wind in km/h",
                subtitle: "Switch to mph if disabled",
                value: true,
                onChanged: (_) {},
                labelStyle: labelStyle,
                subStyle: subStyle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: "Notifications",
            color: colors,
            children: [
              _NavTile(
                color: colors,
                icon: Icons.notifications_active_outlined,
                title: "Notification Settings",
                subtitle: "Alerts, quiet hours, channels",
                labelStyle: labelStyle,
                subStyle: subStyle,
                trailing: Icon(Icons.chevron_right, color: colors.sub),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NotificationSettingsPage(colors: colors),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: "About",
            color: colors,
            children: [
              _NavTile(
                color: colors,
                icon: Icons.info_outline,
                title: "About Umbrella",
                subtitle: "Version 0.1 • Mock build",
                labelStyle: labelStyle,
                subStyle: subStyle,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Umbrella 0.1 (mock)")),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- Theme Segment (Light / System / Dark) -----------------------------------
class _ThemeSegment extends StatelessWidget {
  const _ThemeSegment({
    required this.color,
    required this.value,
    required this.onChanged,
  });

  final AppTheme color;
  final ThemePref value;
  final ValueChanged<ThemePref> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (ThemePref.light, Icons.wb_sunny_outlined, "Light"),
      (ThemePref.system, Icons.settings_suggest_outlined, "System"),
      (ThemePref.dark, Icons.nights_stay_outlined, "Dark"),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: color.cardAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.border),
        ),
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (final opt in options) ...[
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onChanged(opt.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: value == opt.$1 ? color.card : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: value == opt.$1 ? Border.all(color: color.border) : null,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          opt.$2,
                          color: value == opt.$1 ? color.text : color.sub,
                          size: 18,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          opt.$3,
                          style: TextStyle(
                            color: value == opt.$1 ? color.text : color.sub,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (opt != options.last) const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Building blocks (unchanged from your previous version) ───────────────────
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.color,
    required this.children,
  });

  final String title;
  final AppTheme color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      color: color.sub,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(title, style: headerStyle),
        ),
        Container(
          decoration: BoxDecoration(
            color: color.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 0, thickness: 1, color: color.border),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.labelStyle,
    required this.subStyle,
  });

  final AppTheme color;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final TextStyle labelStyle;
  final TextStyle subStyle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color.sub),
      title: Text(title, style: labelStyle),
      subtitle: Text(subtitle, style: subStyle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: color.accent,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.color,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    required this.labelStyle,
    required this.subStyle,
  });

  final AppTheme color;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final TextStyle labelStyle;
  final TextStyle subStyle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color.sub),
      title: Text(title, style: labelStyle),
      subtitle: subtitle != null ? Text(subtitle!, style: subStyle) : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: color.sub),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

// ================== NOTIFICATION SETTINGS PAGE ==================
// (your existing NotificationSettingsPage code that uses AppTheme as `colors`)
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key, required this.colors});
  final AppTheme colors;

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool severeAlerts = true;
  bool rainStarting = true;
  bool dailySummary = true;
  TimeOfDay summaryTime = const TimeOfDay(hour: 8, minute: 0);

  bool quietHours = false;
  TimeOfDay quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay quietEnd = const TimeOfDay(hour: 7, minute: 0);

  bool channelBanner = true;
  bool channelSound = true;
  bool channelBadge = true;

  bool areaCurrent = true;
  bool areaSaved = true;

  AppTheme get c => widget.colors;

  TextStyle get _titleStyle =>
      TextStyle(color: c.text, fontWeight: FontWeight.w700);
  TextStyle get _labelStyle =>
      TextStyle(color: c.text, fontWeight: FontWeight.w600);
  TextStyle get _subStyle => TextStyle(color: c.sub);

  Future<void> _pickTime(
      TimeOfDay initial, ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: c.card,
              hourMinuteTextColor: c.text,
              dialHandColor: c.accent,
            ),
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: c.accent,
              surface: c.card,
              onSurface: c.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Notification Settings", style: _titleStyle),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            _Section(
              title: "Alerts",
              color: c,
              children: [
                _SwitchTile(
                  color: c,
                  icon: Icons.warning_amber_rounded,
                  title: "Severe Weather Alerts",
                  subtitle: "Storms, extreme temps, hazardous conditions",
                  value: severeAlerts,
                  onChanged: (v) => setState(() => severeAlerts = v),
                  labelStyle: _labelStyle,
                  subStyle: _subStyle,
                ),
                _SwitchTile(
                  color: c,
                  icon: Icons.beach_access,
                  title: "Rain Starting",
                  subtitle: "Notify when rain is about to begin",
                  value: rainStarting,
                  onChanged: (v) => setState(() => rainStarting = v),
                  labelStyle: _labelStyle,
                  subStyle: _subStyle,
                ),
                _SwitchTile(
                  color: c,
                  icon: Icons.today_outlined,
                  title: "Daily Summary",
                  subtitle: "Receive a morning overview",
                  value: dailySummary,
                  onChanged: (v) => setState(() => dailySummary = v),
                  labelStyle: _labelStyle,
                  subStyle: _subStyle,
                ),
                if (dailySummary)
                  ListTile(
                    leading: Icon(Icons.schedule_rounded, color: c.sub),
                    title: Text("Summary Time", style: _labelStyle),
                    subtitle: Text(summaryTime.format(context), style: _subStyle),
                    trailing: Icon(Icons.chevron_right, color: c.sub),
                    onTap: () => _pickTime(
                        summaryTime, (t) => setState(() => summaryTime = t)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: "Quiet Hours",
              color: c,
              children: [
                _SwitchTile(
                  color: c,
                  icon: Icons.nightlight_round,
                  title: "Enable Quiet Hours",
                  subtitle: "Pause notifications during the night",
                  value: quietHours,
                  onChanged: (v) => setState(() => quietHours = v),
                  labelStyle: _labelStyle,
                  subStyle: _subStyle,
                ),
                if (quietHours)
                  Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.login_rounded, color: c.sub),
                        title: Text("Start", style: _labelStyle),
                        subtitle:
                        Text(quietStart.format(context), style: _subStyle),
                        trailing: Icon(Icons.chevron_right, color: c.sub),
                        onTap: () => _pickTime(
                            quietStart, (t) => setState(() => quietStart = t)),
                      ),
                      Divider(height: 0, thickness: 1, color: c.border),
                      ListTile(
                        leading: Icon(Icons.logout_rounded, color: c.sub),
                        title: Text("End", style: _labelStyle),
                        subtitle:
                        Text(quietEnd.format(context), style: _subStyle),
                        trailing: Icon(Icons.chevron_right, color: c.sub),
                        onTap: () => _pickTime(
                            quietEnd, (t) => setState(() => quietEnd = t)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: "Notification Channels",
              color: c,
              children: [
                _SwitchTile(
                  color: c,
                  icon: Icons.text_fields,
                  title: "Banners",
                  subtitle: "Show heads-up notifications",
                  value: channelBanner,
                  onChanged: (v) => setState(() => channelBanner = v),
                  labelStyle: _labelStyle,
                  subStyle: _subStyle,
                ),
                _SwitchTile(
                  color: c,
                  icon: Icons.volume_up_outlined,
                  title: "Sound",
                  subtitle: "Play a tone with alerts",
                  value: channelSound,
                  onChanged: (v) => setState(() => channelSound = v),
                  labelStyle: _labelStyle,
                  subStyle: _subStyle,
                ),
                _SwitchTile(
                  color: c,
                  icon: Icons.circle_notifications_outlined,
                  title: "Badges",
                  subtitle: "Show unread count on app icon",
                  value: channelBadge,
                  onChanged: (v) => setState(() => channelBadge = v),
                  labelStyle: _labelStyle,
                  subStyle: _subStyle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: "Areas",
              color: c,
              children: [
                _SwitchTile(
                  color: c,
                  icon: Icons.my_location,
                  title: "Current Location",
                  subtitle: "Follow you for timely alerts",
                  value: areaCurrent,
                  onChanged: (v) => setState(() => areaCurrent = v),
                  labelStyle: _labelStyle,
                  subStyle: _subStyle,
                ),
                _SwitchTile(
                  color: c,
                  icon: Icons.place_outlined,
                  title: "Saved Locations",
                  subtitle: "Alert for places you pin",
                  value: areaSaved,
                  onChanged: (v) => setState(() => areaSaved = v),
                  labelStyle: _labelStyle,
                  subStyle: _subStyle,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}