import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class ItemsState extends ChangeNotifier {
  final _svc = FirestoreService();

  StreamSubscription? _sub;
  User? _user;

  bool loading = false;
  String? error;
  List<Map<String, dynamic>> items = [];

  void bindUser(User? user) {
    if (_user?.uid == user?.uid) return;

    _user = user;
    _sub?.cancel();
    items = [];
    error = null;

    if (_user == null) {
      notifyListeners();
      return;
    }

    loading = true;
    notifyListeners();

    _sub = _svc.streamItems(_user!.uid).listen((data) {
      items = data;
      loading = false;
      notifyListeners();
    }, onError: (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    });
  }

  Future<void> add(String title) async {
    final uid = _user?.uid;
    if (uid == null) return;
    await _svc.addItem(uid, title);
  }

  Future<void> remove(String id) async {
    final uid = _user?.uid;
    if (uid == null) return;
    await _svc.deleteItem(uid, id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
