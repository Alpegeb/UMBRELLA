import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../../core/theme_pref.dart';
import '../../../providers/auth_state.dart';

import '../feedback_screen/feedback_screen.dart';
import '../notification_screen/notification_screen.dart';

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
    if (oldWidget.themePref != widget.themePref) {
      _selectedPref = widget.themePref;
    }
  }

  void _handleThemeChange(ThemePref pref) {
    setState(() => _selectedPref = pref);
    widget.onThemePrefChanged(pref);
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
                subtitle: "Alerts, real-time indicators",
                labelStyle: labelStyle,
                subStyle: subStyle,
                trailing: Icon(Icons.chevron_right, color: colors.sub),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NotificationScreen(appTheme: colors),
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

          const SizedBox(height: 12),

          _Section(
            title: "Support",
            color: colors,
            children: [
              _NavTile(
                color: colors,
                icon: Icons.feedback_outlined,
                title: "Contact us",
                subtitle: "Share feedback or report an issue",
                labelStyle: labelStyle,
                subStyle: subStyle,
                trailing: Icon(Icons.chevron_right, color: colors.sub),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FeedbackScreen(appTheme: colors),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          _Section(
            title: "Account",
            color: colors,
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  "Sign out",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  await context.read<AuthState>().logout();
                  if (!context.mounted) return;

                  // AuthGate stream ile otomatik LoginScreen'e döner.
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

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
                      border:
                          value == opt.$1 ? Border.all(color: color.border) : null,
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
        thumbColor: WidgetStatePropertyAll(color.cardAlt),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? color.accent.withValues(alpha: 0.4)
              : color.border,
        ),
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
