import 'dart:async';
import 'package:flutter/material.dart';
import '../models/feedback_item.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ItemsState extends ChangeNotifier {
  final _svc = FirestoreService();

  User? _user;
  StreamSubscription? _sub;

  List<FeedbackItem> items = [];
  bool loading = false;
  String? error;

  void bindUser(User? u) {
    if (_user?.uid == u?.uid) return;
    _user = u;
    _sub?.cancel();
    items = [];
    error = null;

    if (_user == null) {
      notifyListeners();
      return;
    }

    loading = true;
    notifyListeners();

    _sub = _svc.streamFeedbacks(_user!.uid).listen((data) {
      items = data;
      loading = false;
      notifyListeners();
    }, onError: (e) {
      error = e.toString();
      loading = false;
      notifyListeners();
    });
  }

  Future<void> add(String message) async {
    final uid = _user?.uid;
    if (uid == null) return;
    await _svc.addFeedback(uid, message);
  }

  Future<void> remove(String id) async {
    final uid = _user?.uid;
    if (uid == null) return;
    await _svc.deleteFeedback(uid, id);
  }
}
