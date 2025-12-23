import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firestore_service.dart';

class ItemsState extends ChangeNotifier {
  final FirestoreService _svc;

  ItemsState({FirestoreService? service}) : _svc = service ?? FirestoreService();

  User? _user;
  StreamSubscription? _sub;

  bool loading = false;
  String? error;
  List<Map<String, dynamic>> items = [];

  void bindUser(User? user) {
    if (_user?.uid == user?.uid) return;

    _user = user;

    // reset
    _sub?.cancel();
    _sub = null;
    items = [];
    error = null;
    loading = false;

    if (user == null) {
      notifyListeners();
      return;
    }

    loading = true;
    notifyListeners();

    _sub = _svc.streamItems(user.uid).listen(
      (data) {
        items = data;
        loading = false;
        error = null;
        notifyListeners();
      },
      onError: (e) {
        loading = false;
        error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> add(String title) async {
    final u = _user;
    if (u == null) return;

    try {
      await _svc.addItem(u.uid, title);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> update(String id, String title) async {
    final u = _user;
    if (u == null) return;

    try {
      await _svc.updateItem(u.uid, id, title);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    final u = _user;
    if (u == null) return;

    try {
      await _svc.deleteItem(u.uid, id);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
