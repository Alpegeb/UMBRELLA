import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../../providers/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  bool _obscurePass = true;
  bool _emailValid = false;
  bool _passValid = false;

  static final _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    emailCtrl.addListener(_validate);
    passCtrl.addListener(_validate);
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  void _validate() {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;
    setState(() {
      _emailValid = _emailRegex.hasMatch(email);
      _passValid = pass.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final auth = context.watch<AuthState>();
    final primary = theme.accent;
    final glow = theme.sunny;
    final rules = _passwordRules(passCtrl.text);
    final passedRules = rules.where((r) => r.met).length;
    final canSubmit = _emailValid && _passValid && !auth.isLoading;

    InputDecoration deco(
      String label,
      String hint, {
      IconData? icon,
    }) =>
        InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: theme.cardAlt,
          labelStyle: TextStyle(color: theme.sub),
          hintStyle: TextStyle(color: theme.sub),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: theme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primary, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
          ),
          prefixIcon: icon == null
              ? null
              : Icon(icon, color: theme.sub, size: 18),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        );

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: TapRegion(
          onTapOutside: (_) =>
              FocusManager.instance.primaryFocus?.unfocus(),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.bg,
                        theme.cardAlt.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -120,
                right: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primary.withOpacity(0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -140,
                left: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        glow.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud_outlined, color: primary, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          'Umbrella',
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Create your account',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Get personalized forecasts, alerts, and synced locations.',
                      style: TextStyle(color: theme.sub, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 4,
                      width: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: [
                            primary,
                            glow,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.cardAlt,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: theme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: primary, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Personalized insights',
                            style: TextStyle(
                              color: theme.sub,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: emailCtrl,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _passFocus.requestFocus(),
                      onTapOutside: (_) => _emailFocus.unfocus(),
                      style: TextStyle(color: theme.text),
                      cursorColor: primary,
                      decoration: deco(
                        'Email',
                        'name@email.com',
                        icon: Icons.mail_outline,
                      ).copyWith(
                        suffixIcon: _emailValid
                            ? Icon(Icons.check_circle,
                                color: Colors.green.shade400)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      focusNode: _passFocus,
                      obscureText: _obscurePass,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onTapOutside: (_) => _passFocus.unfocus(),
                      style: TextStyle(color: theme.text),
                      cursorColor: primary,
                      decoration: deco(
                        'Password',
                        'Create a password',
                        icon: Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                              () => _obscurePass = !_obscurePass),
                          icon: Icon(
                            _obscurePass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: theme.sub,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$passedRules/4 requirements met',
                      style: TextStyle(
                        color: theme.sub,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _PasswordRuleList(theme: theme, rules: rules),
                    if (auth.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        auth.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _GradientActionButton(
                      enabled: canSubmit,
                      loading: auth.isLoading,
                      label: 'Create account',
                      primary: primary,
                      glow: glow,
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        try {
                          await context.read<AuthState>().register(
                                emailCtrl.text,
                                passCtrl.text,
                              );
                          if (!mounted) return;
                          navigator.pop();
                        } catch (_) {}
                      },
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: auth.isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          'Back to login',
                          style: TextStyle(color: primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordRule {
  const _PasswordRule(this.label, this.met);

  final String label;
  final bool met;
}

List<_PasswordRule> _passwordRules(String value) {
  final hasMin = value.length >= 6;
  final hasUpper = value.contains(RegExp(r'[A-Z]'));
  final hasLower = value.contains(RegExp(r'[a-z]'));
  final hasNumber = value.contains(RegExp(r'[0-9]'));
  return [
    _PasswordRule('Minimum 6 characters', hasMin),
    _PasswordRule('One uppercase letter', hasUpper),
    _PasswordRule('One lowercase letter', hasLower),
    _PasswordRule('One number', hasNumber),
  ];
}

class _PasswordRuleList extends StatelessWidget {
  const _PasswordRuleList({required this.theme, required this.rules});

  final AppTheme theme;
  final List<_PasswordRule> rules;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rules
          .map(
            (rule) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: rule.met ? Colors.green.shade400 : theme.border,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      rule.met ? Icons.check : Icons.close,
                      size: 12,
                      color: rule.met ? Colors.white : theme.sub,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rule.label,
                    style: TextStyle(
                      color: rule.met ? theme.text : theme.sub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.enabled,
    required this.loading,
    required this.label,
    required this.primary,
    required this.glow,
    required this.onTap,
  });

  final bool enabled;
  final bool loading;
  final String label;
  final Color primary;
  final Color glow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = enabled
        ? Colors.transparent
        : Theme.of(context).disabledColor.withOpacity(0.2);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: enabled
              ? LinearGradient(
                  colors: [
                    primary,
                    glow,
                  ],
                )
              : null,
        ),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
