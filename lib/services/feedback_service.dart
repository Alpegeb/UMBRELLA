import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> submit(
      String message, {
        String? email,
        List<String>? tags,
      }) async {
    await _db.collection('feedback').add({
      'message': message.trim(),
      'email': email,
      'tags': tags ?? [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
