import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoggedIn = false;

  UserModel? get user => _user;
  bool get isLoggedIn => _isLoggedIn;

  // Load user data on app start
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    if (userData != null && isLoggedIn) {
      _user = UserModel.fromJson(json.decode(userData));
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  // Save user after signup/login
  Future<void> saveUser(UserModel user) async {
    _user = user;
    _isLoggedIn = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(user.toJson()));
    await prefs.setBool('isLoggedIn', true);
    
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    _user = null;
    _isLoggedIn = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.setBool('isLoggedIn', false);
    
    notifyListeners();
  }
}