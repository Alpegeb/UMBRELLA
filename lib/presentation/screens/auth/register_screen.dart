import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
        title: Text('Register', style: TextStyle(color: textColor)),
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
                  final navigator = Navigator.of(context);
                  try {
                    await context.read<AuthState>().register(
                      emailCtrl.text,
                      passCtrl.text,
                    );
                    if (!mounted) return;
                    navigator.pop();
                  } catch (_) {

                  }
                },
                child: auth.isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Create account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


