import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder.dart';

class ReminderRepository {
  ReminderRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('reminders');

  Stream<List<Reminder>> streamReminders(String uid) {
    return _col
        .where('createdBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Reminder.fromDoc).toList());
  }

  Future<void> addReminder({
    required String uid,
    required String title,
    String? note,
    required DateTime scheduledAt,
  }) async {
    final docRef = _col.doc();
    await docRef.set({
      'id': docRef.id,
      'createdBy': uid,
      'createdAt': Timestamp.now(),
      'title': title,
      'note': note,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'isDone': false,
    });
  }

  Future<void> updateReminder(Reminder updated) async {
    await _col.doc(updated.id).update({
      'title': updated.title,
      'note': updated.note,
      'scheduledAt': updated.scheduledAt,
      'isDone': updated.isDone,
    });
  }

  Future<void> deleteReminder(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> setDone(String id, bool isDone) async {
    await _col.doc(id).update({'isDone': isDone});
  }
}
