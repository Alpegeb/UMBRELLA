import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String id;
  final String createdBy;
  final Timestamp createdAt;

  final String title;
  final String? note;
  final Timestamp scheduledAt;
  final bool isDone;

  const Reminder({
    required this.id,
    required this.createdBy,
    required this.createdAt,
    required this.title,
    required this.scheduledAt,
    this.note,
    this.isDone = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'title': title,
      'note': note,
      'scheduledAt': scheduledAt,
      'isDone': isDone,
    };
  }

  static Reminder fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Reminder(
      id: (data['id'] as String?) ?? doc.id,
      createdBy: data['createdBy'] as String,
      createdAt: data['createdAt'] as Timestamp,
      title: data['title'] as String,
      note: data['note'] as String?,
      scheduledAt: data['scheduledAt'] as Timestamp,
      isDone: (data['isDone'] as bool?) ?? false,
    );
  }
}
