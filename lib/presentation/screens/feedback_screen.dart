import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController feedbackCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();

  final Set<String> selected = {};
  final List<String> tags = const [
    'Inaccurate positioning?',
    'Wrong city location?',
    'Wrong city name?',
    'Inaccurate weather?',
    'Too many ads?',
    'Other',
  ];

  bool isLight = true;

  @override
  Widget build(BuildContext context) {
    final theme = isLight ? AppTheme.light : AppTheme.dark;

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
        actions: [
          IconButton(
            icon: Icon(
              isLight ? Icons.dark_mode : Icons.light_mode,
              color: theme.sub,
            ),
            onPressed: () => setState(() => isLight = !isLight),
          )
        ],
        title: Text(
          'Feedback',
          style: TextStyle(
            color: theme.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Card(
            theme: theme,
            child: TextField(
              controller: feedbackCtrl,
              maxLines: 5,
              style: TextStyle(color: theme.text),
              decoration: InputDecoration(
                hintText: 'Write your feedback...',
                hintStyle: TextStyle(color: theme.sub),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((text) {
              final sel = selected.contains(text);
              return ChoiceChip(
                label: Text(
                  text,
                  style: TextStyle(
                    color: sel ? Colors.white : theme.sub,
                  ),
                ),
                selected: sel,
                selectedColor: theme.accent,
                backgroundColor: theme.cardAlt,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      selected.add(text);
                    } else {
                      selected.remove(text);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _Card(
            theme: theme,
            child: TextField(
              controller: emailCtrl,
              style: TextStyle(color: theme.text),
              decoration: InputDecoration(
                icon: Icon(Icons.email, color: theme.accent),
                hintText: 'Your email (optional)',
                hintStyle: TextStyle(color: theme.sub),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {},
              child: Text(
                'Submit',
                style: TextStyle(
                  color: theme.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final AppTheme theme;

  const _Card({required this.child, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
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
