import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isLoggedIn => _auth.currentUser != null;
  User? get currentUser => _auth.currentUser;
  String get userId => _auth.currentUser?.uid ?? '';

  AuthService() {
    _auth.authStateChanges().listen((_) => notifyListeners());
  }

  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}