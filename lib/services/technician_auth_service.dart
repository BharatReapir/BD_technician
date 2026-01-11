import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/technician_model.dart';

class TechnicianAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String? _verificationId; // Changed to static

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
        print('OTP Sent! Verification ID: $verificationId'); // Debug log
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> verifyOTP(String otp) async {
    print('Verifying OTP with ID: $_verificationId'); // Debug log
    
    if (_verificationId == null || _verificationId!.isEmpty) {
      throw Exception('Please request OTP first');
    }

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );

    return await _auth.signInWithCredential(credential);
  }

  Future<TechnicianModel?> getTechnicianData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('technicians').doc(uid).get();

      if (doc.exists) {
        return TechnicianModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching technician data: $e');
    }
  }

  Future<void> createTechnicianProfile(TechnicianModel technician) async {
    await _firestore
        .collection('technicians')
        .doc(technician.uid)
        .set(technician.toJson());
  }

  Future<void> updateTechnicianStatus(String uid, bool isOnline) async {
    await _firestore.collection('technicians').doc(uid).update({
      'isOnline': isOnline,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> signOut() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await updateTechnicianStatus(user.uid, false);
    }
    await _auth.signOut();
  }

  Stream<TechnicianModel?> technicianStream(String uid) {
    return _firestore
        .collection('technicians')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return TechnicianModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}