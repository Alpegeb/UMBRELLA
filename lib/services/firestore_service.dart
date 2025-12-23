import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('items');

  Stream<List<Map<String, dynamic>>> streamItems(String uid) {
    return _col(uid)
        .orderBy('createdAtServer', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {
                  'id': d.id,
                  ...d.data(),
                })
            .toList());
  }

  Future<void> addItem(String uid, String title) async {
    await _col(uid).add({
      'title': title,
      'createdBy': uid,

      // UI/Local için hemen değer
      'createdAt': Timestamp.now(),

      // Sunucu zamanı (orderBy için daha stabil)
      'createdAtServer': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateItem(String uid, String id, {required String title}) async {
    await _col(uid).doc(id).update({
      'title': title,
      'updatedAt': Timestamp.now(),
      'updatedAtServer': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteItem(String uid, String id) async {
    await _col(uid).doc(id).delete();
  }
}
