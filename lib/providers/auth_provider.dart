import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/technician_model.dart';
import '../services/firebase_service.dart';
import '../services/coin_service.dart'; // 🎉 NEW: Import coin service
import 'dart:convert';
import 'dart:async'; // 🔧 NEW: For Completer

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  TechnicianModel? _technician;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String _userType = 'user'; // 'user' or 'technician'

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // ✅ REMOVED: Don't create separate database instance
  // final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  static String? _verificationId;

  UserModel? get user => _user;
  TechnicianModel? get technician => _technician;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String get userType => _userType;
  bool get isUser => _userType == 'user';
  bool get isTechnician => _userType == 'technician';

  AuthProvider() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser != null) {
        debugPrint('🔵 Auth state changed: User logged in (${firebaseUser.uid})');
        loadUser();
      } else {
        debugPrint('🔴 Auth state changed: User logged out');
        _clearUser();
      }
    });
  }

  void _clearUser() {
    _user = null;
    _technician = null;
    _isLoggedIn = false;
    _userType = 'user';
    notifyListeners();
  }

  // ✅ Send OTP for Phone Authentication
  Future<void> sendOTP(String phoneNumber) async {
    debugPrint('📱 Sending OTP to: +91$phoneNumber');
    
    // Create a completer to wait for the verification ID
    final completer = Completer<void>();
    
    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phoneNumber',
      verificationCompleted: (PhoneAuthCredential credential) async {
        debugPrint('🔐 Auto verification completed');
        await _auth.signInWithCredential(credential);
        if (!completer.isCompleted) completer.complete();
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('❌ Verification failed: ${e.message}');
        if (!completer.isCompleted) completer.completeError(Exception(e.message ?? 'Verification failed'));
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        debugPrint('📱 OTP Sent! Verification ID: $verificationId');
        debugPrint('🔑 Stored verification ID: $_verificationId');
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        debugPrint('⏰ Auto retrieval timeout. Verification ID: $verificationId');
        if (!completer.isCompleted) completer.complete();
      },
      timeout: const Duration(seconds: 60),
    );
    
    // Wait for either codeSent or verificationCompleted
    await completer.future;
    debugPrint('✅ OTP process completed, verification ID: $_verificationId');
  }

  // ✅ Verify OTP with technician-only test bypass
  Future<UserCredential> verifyOTP(String otp) async {
    debugPrint('🔐 Verifying OTP: $otp');
    debugPrint('🔑 Using verification ID: $_verificationId');
    debugPrint('👤 User type: $_userType');
    
    // 🧪 TEST BYPASS: Allow 123456 for technicians (check SharedPreferences too)
    final prefs = await SharedPreferences.getInstance();
    final storedUserType = prefs.getString('userType') ?? 'user';
    debugPrint('💾 Stored user type: $storedUserType');
    
    if (otp == '123456' && (storedUserType == 'technician' || _userType == 'technician')) {
      debugPrint('🧪 Technician test OTP detected - bypassing Firebase verification');
      
      try {
        // Create test account with email/password instead of anonymous
        final testEmail = 'test_tech_${DateTime.now().millisecondsSinceEpoch}@bharatapp.com';
        final testPassword = 'test123456';
        
        debugPrint('🧪 Creating test technician account: $testEmail');
        
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );
        
        debugPrint('✅ Technician test account created: ${userCredential.user?.uid}');
        return userCredential;
      } catch (e) {
        debugPrint('❌ Test account creation failed: $e');
        
        // If creation fails, try to sign in with a default test account
        try {
          debugPrint('🧪 Trying default test account...');
          final userCredential = await _auth.signInWithEmailAndPassword(
            email: 'test.technician@bharatapp.com',
            password: 'test123456',
          );
          debugPrint('✅ Default test account sign in successful: ${userCredential.user?.uid}');
          return userCredential;
        } catch (e2) {
          debugPrint('❌ Default test account failed, creating it: $e2');
          
          // Create the default test account
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: 'test.technician@bharatapp.com',
            password: 'test123456',
          );
          debugPrint('✅ Default test account created: ${userCredential.user?.uid}');
          return userCredential;
        }
      }
    }
    
    if (_verificationId == null || _verificationId!.isEmpty) {
      debugPrint('❌ No verification ID found');
      throw Exception('Please request OTP first');
    }
    
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );
    
    debugPrint('🔐 Signing in with credential...');
    final userCredential = await _auth.signInWithCredential(credential);
    debugPrint('✅ Sign in successful: ${userCredential.user?.uid}');
    
    return userCredential;
  }

  /// 🔹 LOAD USER ON APP START
  Future<void> loadUser() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      debugPrint('❌ No Firebase user found');
      _isLoggedIn = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    debugPrint('🔄 Loading user data for UID: ${firebaseUser.uid}');

    final prefs = await SharedPreferences.getInstance();
    _userType = prefs.getString('userType') ?? 'user';

    debugPrint('📱 User type from prefs: $_userType');

    // ✅ Load based on user type
    if (_userType == 'technician') {
      await _loadTechnician(firebaseUser.uid);
    } else {
      await _loadRegularUser(firebaseUser.uid);
      
      // ✅ Fallback: If user not found, try technician
      if (!_isLoggedIn) {
        debugPrint('🔍 User not found, trying as technician...');
        await _loadTechnician(firebaseUser.uid);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load regular user
  Future<void> _loadRegularUser(String uid) async {
    try {
      debugPrint('👤 Loading regular user from Firebase...');
      
      // 1️⃣ Try Firebase Realtime DB first using FirebaseService
      final userData = await FirebaseService.getUser(uid);

      if (userData != null) {
        debugPrint('✅ User loaded from Firebase: ${userData.name}');
        _user = userData;
        _isLoggedIn = true;
        _userType = 'user';

        // Cache locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user!.toJson()));
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userType', 'user');

        notifyListeners();
        return;
      }

      debugPrint('⚠️ User not found in Firebase, checking local cache...');

      // 2️⃣ Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final cachedUser = prefs.getString('user');
      final loggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (cachedUser != null && loggedIn) {
        debugPrint('✅ User loaded from cache');
        _user = UserModel.fromJson(json.decode(cachedUser));
        _isLoggedIn = true;
        _userType = 'user';
        notifyListeners();
      } else {
        debugPrint('❌ No user data found');
      }
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
    }
  }

  Future<void> _loadTechnician(String uid) async {
    try {
      debugPrint('🔧 Loading technician from Firebase...');
      
      // 1️⃣ Try Firebase Realtime DB first using FirebaseService
      final techData = await FirebaseService.getTechnician(uid);

      if (techData != null) {
        debugPrint('✅ Technician loaded from Firebase: ${techData.name}');
        debugPrint('💰 Wallet Balance: ₹${techData.walletBalance}');
        
        _technician = techData;
        _isLoggedIn = true;
        _userType = 'technician';

        // Cache locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('technician', json.encode(_technician!.toJson()));
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userType', 'technician');

        notifyListeners();
        return;
      }

      debugPrint('⚠️ Technician not found in Firebase, checking local cache...');

      // 2️⃣ Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final cachedTech = prefs.getString('technician');
      final loggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (cachedTech != null && loggedIn) {
        debugPrint('✅ Technician loaded from cache');
        _technician = TechnicianModel.fromJson(json.decode(cachedTech));
        _isLoggedIn = true;
        _userType = 'technician';
        notifyListeners();
      } else {
        debugPrint('❌ No technician data found');
      }
    } catch (e) {
      debugPrint('❌ Error loading technician: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  // ✅ Get technician data from Realtime Database using FirebaseService
  Future<TechnicianModel?> getTechnicianData(String uid) async {
    try {
      debugPrint('🔍 Fetching technician data for UID: $uid');
      return await FirebaseService.getTechnician(uid);
    } catch (e) {
      debugPrint('❌ Error fetching technician data: $e');
      throw Exception('Error fetching technician data: $e');
    }
  }

  // ✅ Stream technician data from Realtime Database using FirebaseService
  Stream<TechnicianModel?> technicianStream(String uid) {
    return FirebaseService.streamTechnician(uid);
  }

  /// 🔹 RELOAD USER/TECHNICIAN DATA (Call this after wallet recharge)
  Future<void> reloadData() async {
    debugPrint('🔄 Reloading user/technician data...');
    await loadUser();
  }

  /// 🔹 SAVE USER AFTER OTP (Regular User)
  Future<void> saveUser(UserModel user) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    debugPrint('💾 Saving user: ${user.name}');

    _user = user;
    _isLoggedIn = true;
    _userType = 'user';

    // 1️⃣ Save to Firebase using FirebaseService
    await FirebaseService.saveUser(user);

    // 🎉 NEW: Add 500 coins welcome bonus for new users
    try {
      final bonusAdded = await CoinService.addWelcomeBonus(
        userId: user.uid,
        userName: user.name,
      );
      
      if (bonusAdded) {
        debugPrint('🎉 Welcome bonus added: 500 coins for ${user.name}');
      } else {
        debugPrint('⚠️ Welcome bonus already exists or failed for ${user.name}');
      }
    } catch (e) {
      debugPrint('❌ Error adding welcome bonus: $e');
      // Don't fail user creation if bonus fails
    }

    // 2️⃣ Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(user.toJson()));
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userType', 'user');

    notifyListeners();
  }

  /// 🔹 SAVE TECHNICIAN AFTER OTP - ✅ UPDATED to use FirebaseService
  Future<void> saveTechnician(TechnicianModel technician) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      debugPrint('❌ No Firebase user found, cannot save technician');
      return;
    }

    debugPrint('💾 Saving technician: ${technician.name}');

    _technician = technician;
    _isLoggedIn = true;
    _userType = 'technician';

    // 1️⃣ Save to Firebase using FirebaseService
    await FirebaseService.saveTechnician(technician);

    // 2️⃣ Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('technician', json.encode(technician.toJson()));
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userType', 'technician');

    notifyListeners();
  }

  /// 🔹 UPDATE USER PROFILE
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (_user == null) return;

    await FirebaseService.updateUser(_user!.uid, updates);
    
    // Update local user object
    _user = _user!.copyWith(
      name: updates['name'] ?? _user!.name,
      email: updates['email'] ?? _user!.email,
      city: updates['city'] ?? _user!.city,
    );

    // Update cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(_user!.toJson()));

    notifyListeners();
  }

  /// 🔹 UPDATE TECHNICIAN STATUS - ✅ UPDATED to use FirebaseService
  Future<void> updateTechnicianStatus(bool isOnline) async {
    if (_technician == null) return;

    debugPrint('🔄 Updating technician status: ${isOnline ? "ONLINE" : "OFFLINE"}');

    // Update using FirebaseService
    await FirebaseService.updateTechnicianStatus(_technician!.uid, isOnline);
    
    _technician = _technician!.copyWith(isOnline: isOnline);

    // Update cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('technician', json.encode(_technician!.toJson()));

    notifyListeners();
  }

  /// 🔹 LOGOUT - ✅ UPDATED to use FirebaseService
  Future<void> logout() async {
    debugPrint('👋 Logging out...');
    
    // If technician, set offline before logout
    if (_technician != null && _technician!.isOnline) {
      await FirebaseService.updateTechnicianStatus(_technician!.uid, false);
    }

    await _auth.signOut();

    _user = null;
    _technician = null;
    _isLoggedIn = false;
    _userType = 'user';
    _verificationId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  // ✅ Get current Firebase user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// 🔹 SWITCH USER TYPE (for testing/development)
  Future<void> switchUserType(String type) async {
    if (type != 'user' && type != 'technician') return;

    debugPrint('🔄 Switching user type to: $type');

    _userType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userType', type);

    // Reload user data
    await loadUser();
  }

  /// 🔹 REFRESH TECHNICIAN DATA (for technician home page)
  Future<void> refreshTechnicianData() async {
    if (_technician == null) return;
    
    debugPrint('🔄 Refreshing technician data...');
    
    try {
      final freshData = await FirebaseService.getTechnician(_technician!.uid);
      if (freshData != null) {
        _technician = freshData;
        
        // Update cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('technician', json.encode(_technician!.toJson()));
        
        notifyListeners();
        debugPrint('✅ Technician data refreshed');
      }
    } catch (e) {
      debugPrint('❌ Error refreshing technician data: $e');
    }
  }
}