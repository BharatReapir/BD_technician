import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../models/technician_model.dart';
import '../services/firebase_service.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  TechnicianModel? _technician;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String _userType = 'user'; // 'user' or 'technician'

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
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

  // ✅ ADDED: Send OTP for Phone Authentication
  Future<void> sendOTP(String phoneNumber) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phoneNumber',
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        throw Exception(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        debugPrint('📱 OTP Sent! Verification ID: $verificationId');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );
  }

  // ✅ ADDED: Verify OTP
  Future<UserCredential> verifyOTP(String otp) async {
    debugPrint('🔐 Verifying OTP with ID: $_verificationId');
    
    if (_verificationId == null || _verificationId!.isEmpty) {
      throw Exception('Please request OTP first');
    }
    
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );
    
    return await _auth.signInWithCredential(credential);
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
      
      // 1️⃣ Try Firebase Realtime DB first
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

  /// Load technician - ✅ UPDATED with Realtime Database logic
  Future<void> _loadTechnician(String uid) async {
    try {
      debugPrint('🔧 Loading technician from Firebase...');
      
      // 1️⃣ Try Firebase Realtime DB first
      final snapshot = await _database.child('technicians').child(uid).get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final techData = TechnicianModel.fromJson(data);
        
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

  // ✅ ADDED: Get technician data from Realtime Database
  Future<TechnicianModel?> getTechnicianData(String uid) async {
    try {
      debugPrint('🔍 Fetching technician data for UID: $uid');
      
      final snapshot = await _database.child('technicians').child(uid).get();
      if (snapshot.exists) {
        debugPrint('✅ Technician data found in Realtime DB');
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return TechnicianModel.fromJson(data);
      } else {
        debugPrint('❌ No technician data found for UID: $uid');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching technician data: $e');
      throw Exception('Error fetching technician data: $e');
    }
  }

  // ✅ ADDED: Stream technician data from Realtime Database
  Stream<TechnicianModel?> technicianStream(String uid) {
    return _database.child('technicians').child(uid).onValue.map((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return TechnicianModel.fromJson(data);
      }
      return null;
    });
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

    // 1️⃣ Save to Firebase
    await FirebaseService.saveUser(user);

    // 2️⃣ Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(user.toJson()));
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userType', 'user');

    notifyListeners();
  }

  /// 🔹 SAVE TECHNICIAN AFTER OTP - ✅ UPDATED with Realtime Database logic
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

    // 1️⃣ Save to Firebase Realtime Database
    await _database
        .child('technicians')
        .child(technician.uid)
        .set(technician.toJson());

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

  /// 🔹 UPDATE TECHNICIAN STATUS - ✅ UPDATED with Realtime Database logic
  Future<void> updateTechnicianStatus(bool isOnline) async {
    if (_technician == null) return;

    debugPrint('🔄 Updating technician status: ${isOnline ? "ONLINE" : "OFFLINE"}');

    // Update in Realtime Database
    await _database.child('technicians').child(_technician!.uid).update({
      'isOnline': isOnline,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
    
    _technician = _technician!.copyWith(isOnline: isOnline);

    // Update cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('technician', json.encode(_technician!.toJson()));

    notifyListeners();
  }

  /// 🔹 LOGOUT - ✅ UPDATED with technician offline status
  Future<void> logout() async {
    debugPrint('👋 Logging out...');
    
    // If technician, set offline before logout
    if (_technician != null && _technician!.isOnline) {
      await _database.child('technicians').child(_technician!.uid).update({
        'isOnline': false,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    }

    await _auth.signOut();

    _user = null;
    _technician = null;
    _isLoggedIn = false;
    _userType = 'user';
    _verificationId = null; // ✅ Clear verification ID

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  // ✅ ADDED: Get current Firebase user
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
}