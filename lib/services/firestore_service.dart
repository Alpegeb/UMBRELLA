import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('items');

  Stream<List<Map<String, dynamic>>> streamItems(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> addItem(String uid, String title) async {
    await _col(uid).add({
      'title': title,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteItem(String uid, String id) async {
    await _col(uid).doc(id).delete();
  }

  // ✅ Step-3 UPDATE
Future<void> update(String id, String title) async {
  final uid = _user?.uid;
  if (uid == null) return;
  await _svc.updateItem(uid, id, title); // ✅ positional
}
