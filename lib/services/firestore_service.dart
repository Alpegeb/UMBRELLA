import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_item.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('feedbacks');

  Stream<List<FeedbackItem>> streamFeedbacks(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FeedbackItem.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> addFeedback(String uid, String message) async {
    await _col(uid).add({
      'message': message,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFeedback(String uid, FeedbackItem item) async {
    await _col(uid).doc(item.id).update({'message': item.message});
  }

  Future<void> deleteFeedback(String uid, String id) async {
    await _col(uid).doc(id).delete();
  }
}
