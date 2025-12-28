import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/technician_model.dart';
import '../models/booking_model.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ========== USER OPERATIONS ==========

  /// Create or update user
  static Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(
          user.toJson(),
          SetOptions(merge: true),
        );
  }

  /// Get user by ID
  static Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }

  /// Update user profile
  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = DateTime.now().toIso8601String();
    await _db.collection('users').doc(uid).update(data);
  }

  /// Delete user
  static Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // ========== TECHNICIAN OPERATIONS ==========

  /// Create or update technician
  static Future<void> saveTechnician(TechnicianModel technician) async {
    await _db.collection('technicians').doc(technician.uid).set(
          technician.toJson(),
          SetOptions(merge: true),
        );
  }

  /// Get technician by ID
  static Future<TechnicianModel?> getTechnician(String uid) async {
    final doc = await _db.collection('technicians').doc(uid).get();
    if (doc.exists) {
      return TechnicianModel.fromJson(doc.data()!);
    }
    return null;
  }

  /// Update technician status (online/offline)
  static Future<void> updateTechnicianStatus(String uid, bool isOnline) async {
    await _db.collection('technicians').doc(uid).update({
      'isOnline': isOnline,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Update technician stats
  static Future<void> updateTechnicianStats({
    required String uid,
    required int totalJobs,
    required double monthlyEarnings,
    required double rating,
  }) async {
    await _db.collection('technicians').doc(uid).update({
      'totalJobs': totalJobs,
      'monthlyEarnings': monthlyEarnings,
      'rating': rating,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get all online technicians by city
  static Future<List<TechnicianModel>> getOnlineTechnicians(String city) async {
    final snapshot = await _db
        .collection('technicians')
        .where('city', isEqualTo: city)
        .where('isOnline', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => TechnicianModel.fromJson(doc.data()))
        .toList();
  }

  /// Get technicians by specialization
  static Future<List<TechnicianModel>> getTechniciansByService(
      String service, String city) async {
    final snapshot = await _db
        .collection('technicians')
        .where('city', isEqualTo: city)
        .where('specializations', arrayContains: service)
        .get();

    return snapshot.docs
        .map((doc) => TechnicianModel.fromJson(doc.data()))
        .toList();
  }

  // ========== BOOKING OPERATIONS ==========

  /// Create new booking
  static Future<String> createBooking(BookingModel booking) async {
    final docRef = await _db.collection('bookings').add(booking.toJson());
    return docRef.id;
  }

  /// Get booking by ID
  static Future<BookingModel?> getBooking(String bookingId) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (doc.exists) {
      return BookingModel.fromJson(doc.data()!);
    }
    return null;
  }

  /// Update booking status
  static Future<void> updateBookingStatus(
      String bookingId, String status) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Assign technician to booking
  static Future<void> assignTechnicianToBooking(
      String bookingId, String technicianId, String technicianName) async {
    await _db.collection('bookings').doc(bookingId).update({
      'technicianId': technicianId,
      'technicianName': technicianName,
      'status': 'accepted',
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get user's bookings
  static Future<List<BookingModel>> getUserBookings(String userId) async {
    final snapshot = await _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromJson(doc.data()))
        .toList();
  }

  /// Get technician's bookings
  static Future<List<BookingModel>> getTechnicianBookings(
      String technicianId) async {
    final snapshot = await _db
        .collection('bookings')
        .where('technicianId', isEqualTo: technicianId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => BookingModel.fromJson(doc.data()))
        .toList();
  }

  /// Get pending bookings for technician (by city and service)
  static Future<List<BookingModel>> getPendingBookingsForTechnician({
    required String city,
    required List<String> specializations,
  }) async {
    final snapshot = await _db
        .collection('bookings')
        .where('status', isEqualTo: 'pending')
        .get();

    // Filter by city and specialization in memory
    return snapshot.docs
        .map((doc) => BookingModel.fromJson(doc.data()))
        .where((booking) =>
            specializations.contains(booking.service) &&
            booking.address?.contains(city) == true)
        .toList();
  }

  /// Stream user's bookings (real-time updates)
  static Stream<List<BookingModel>> streamUserBookings(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromJson(doc.data()))
            .toList());
  }

  /// Stream technician's bookings (real-time updates)
  static Stream<List<BookingModel>> streamTechnicianBookings(
      String technicianId) {
    return _db
        .collection('bookings')
        .where('technicianId', isEqualTo: technicianId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromJson(doc.data()))
            .toList());
  }
}

