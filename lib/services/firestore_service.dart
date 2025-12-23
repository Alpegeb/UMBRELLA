import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('items');

  Stream<List<Map<String, dynamic>>> streamItems(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
            .toList());
  }

  Future<void> addItem(String uid, String title) async {
    await _col(uid).add({
      'title': title,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteItem(String uid, String id) async {
    await _col(uid).doc(id).delete();
  }

  Future<void> updateItem(String uid, String id, String title) async {
    await _col(uid).doc(id).update({
      'title': title,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
