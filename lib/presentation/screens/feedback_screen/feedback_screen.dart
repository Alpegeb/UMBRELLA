import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../../services/feedback_service.dart';
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({
    super.key,
    required this.appTheme,
  });

  final AppTheme appTheme;

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

  AppTheme get theme => widget.appTheme;

  @override
  Widget build(BuildContext context) {
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
              onPressed: () async {
                if (feedbackCtrl.text.trim().isEmpty) return;

                await FeedbackService.submit(
                  feedbackCtrl.text,
                  email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  tags: selected.toList(),
                );

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feedback sent. Thank you!')),
                );


                feedbackCtrl.clear();
                emailCtrl.clear();
                selected.clear();


              },
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