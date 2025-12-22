import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import 'package:umbrella/providers/items_state.dart';

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

  String _buildTitle() {
    final msg = feedbackCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final tagStr = selected.isEmpty ? '' : ' | tags: ${selected.join(", ")}';
    final emailStr = email.isEmpty ? '' : ' | email: $email';
    return '$msg$emailStr$tagStr';
  }

  Future<void> _submit() async {
    final msg = feedbackCtrl.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback can't be empty")),
      );
      return;
    }

    await context.read<ItemsState>().add(_buildTitle());

    feedbackCtrl.clear();
    emailCtrl.clear();
    setState(() => selected.clear());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Feedback saved to Firestore ✅")),
    );
  }

  @override
  void dispose() {
    feedbackCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<ItemsState>();

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
          // CREATE
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

          const SizedBox(height: 16),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: st.loading ? null : _submit,
              child: Text(
                st.loading ? 'Submitting...' : 'Submit',
                style: TextStyle(
                  color: theme.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // READ (realtime) + DELETE
          Text(
            "Your previous feedback (realtime)",
            style: TextStyle(
              color: theme.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          if (st.error != null)
            Text(st.error!, style: TextStyle(color: theme.sub)),

          if (!st.loading && st.items.isEmpty)
            Text(
              "No feedback yet.",
              style: TextStyle(color: theme.sub),
            ),

          for (final item in st.items.take(10)) ...[
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.border),
              ),
              child: ListTile(
                title: Text(
                  (item['title'] ?? '').toString(),
                  style: TextStyle(color: theme.text, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "id: ${(item['id'] ?? '').toString()}",
                  style: TextStyle(color: theme.sub),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () async {
                    final id = (item['id'] ?? '').toString();
                    await context.read<ItemsState>().remove(id);
                  },
                ),
              ),
            ),
          ],
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
