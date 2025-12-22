import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  User? get user => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setError(null);

    final e = email.trim();
    final p = password;

    if (e.isEmpty) {
      _setError('Please enter an email.');
      return false;
    }
    if (p.isEmpty) {
      _setError('Please enter a password.');
      return false;
    }

    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(email: e, password: p);
      return true;
    } on FirebaseAuthException catch (ex) {
      _setError(_friendlyAuthError(ex));
      return false;
    } catch (_) {
      _setError('Authentication error. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String email, String password) async {
    _setError(null);

    final e = email.trim();
    final p = password;

    if (e.isEmpty) {
      _setError('Please enter an email.');
      return false;
    }
    if (p.isEmpty) {
      _setError('Please enter a password.');
      return false;
    }

    _setLoading(true);
    try {
      await _auth.createUserWithEmailAndPassword(email: e, password: p);
      return true;
    } on FirebaseAuthException catch (ex) {
      _setError(_friendlyAuthError(ex));
      return false;
    } catch (_) {
      _setError('Registration error. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setError(null);
    _setLoading(true);
    try {
      await _auth.signOut();
    } catch (_) {
      _setError('Sign out failed. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'missing-password':
        return 'Please enter a password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This user account is disabled.';
      case 'user-not-found':
        return 'No user found with that email.';
      case 'wrong-password':
        return 'Wrong password.';
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'weak-password':
        return 'Password is too weak (try 6+ characters).';
      case 'operation-not-allowed':
        return 'Login method is currently unavailable.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }
}
