import 'package:flutter/material.dart';

import '../../../core/data/models/reminder.dart';
import '../../../core/data/repositories/reminder_repository.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({
    super.key,
    required this.uid,
    required this.repo,
  });

  final String uid;
  final ReminderRepository repo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders (Realtime)')),
      body: StreamBuilder<List<Reminder>>(
        stream: repo.streamReminders(uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No reminders yet.'));
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = items[i];
              return ListTile(
                title: Text(r.title),
                subtitle: Text(r.note),
                trailing: Checkbox(
                  value: r.isDone,
                  onChanged: (v) {
                    if (v == null) return;
                    repo.setDone(r.id, v);
                  },
                ),
                onLongPress: () => repo.deleteReminder(r.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await repo.createReminder(
            uid: uid,
            title: 'Demo reminder',
            note: 'Created via Repository (no Firestore in UI)',
            scheduledAt: DateTime.now().add(const Duration(hours: 2)),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
