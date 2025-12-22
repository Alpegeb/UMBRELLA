import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_state.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    // Reliable dark/light detection even if ThemeData.brightness is wrong
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final isDark = bg.computeLuminance() < 0.5;

    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white70 : Colors.black54;
    final borderColor = isDark ? Colors.white54 : Colors.black45;
    final primary = Theme.of(context).colorScheme.primary;

    InputDecoration deco(String label) => InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: subColor),
      hintStyle: TextStyle(color: subColor),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: primary, width: 2),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Login', style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: textColor),
              cursorColor: primary,
              decoration: deco('Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: TextStyle(color: textColor),
              cursorColor: primary,
              decoration: deco('Password'),
            ),
            const SizedBox(height: 16),
            if (auth.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  auth.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: auth.isLoading
                    ? null
                    : () async {
                  try {
                    await context.read<AuthState>().login(
                      emailCtrl.text,
                      passCtrl.text,
                    );
                  } catch (_) {

                  }
                },
                child: auth.isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Login'),
              ),
            ),
            TextButton(
              onPressed: auth.isLoading
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: Text(
                'Create account',
                style: TextStyle(color: primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
