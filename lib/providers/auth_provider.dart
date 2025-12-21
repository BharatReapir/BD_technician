import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoggedIn = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? get user => _user;
  bool get isLoggedIn => _isLoggedIn;

  /// 🔹 LOAD USER ON APP START
  Future<void> loadUser() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      _isLoggedIn = false;
      notifyListeners();
      return;
    }

    // 1️⃣ Try Firestore first (source of truth)
    final doc =
        await _firestore.collection('users').doc(firebaseUser.uid).get();

    if (doc.exists) {
      _user = UserModel.fromJson(doc.data()!);
      _isLoggedIn = true;

      // Cache locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(_user!.toJson()));
      await prefs.setBool('isLoggedIn', true);

      notifyListeners();
      return;
    }

    // 2️⃣ Fallback to local storage
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (userData != null && loggedIn) {
      _user = UserModel.fromJson(json.decode(userData));
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  /// 🔹 SAVE USER AFTER OTP
  Future<void> saveUser(UserModel user) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    _user = user;
    _isLoggedIn = true;

    // 1️⃣ Save to Firestore
    await _firestore.collection('users').doc(firebaseUser.uid).set(
      user.toJson(),
      SetOptions(merge: true),
    );

    // 2️⃣ Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(user.toJson()));
    await prefs.setBool('isLoggedIn', true);

    notifyListeners();
  }

  /// 🔹 LOGOUT
  Future<void> logout() async {
    await _auth.signOut();

    _user = null;
    _isLoggedIn = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }
}
