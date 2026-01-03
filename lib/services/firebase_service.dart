import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../models/technician_model.dart';
import '../models/booking_model.dart';


class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;

  // ========== USER OPERATIONS ==========

  /// Create or update user
  static Future<void> saveUser(UserModel user) async {
    await _realtimeDb.ref('users/${user.uid}').set(user.toJson());
  }

  /// Get user by ID
  static Future<UserModel?> getUser(String uid) async {
    final snapshot = await _realtimeDb.ref('users/$uid').get();
    if (snapshot.exists) {
      return UserModel.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
    }
    return null;
  }

  /// Update user profile
  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = DateTime.now().toIso8601String();
    await _realtimeDb.ref('users/$uid').update(data);
  }

  /// Delete user
  static Future<void> deleteUser(String uid) async {
    await _realtimeDb.ref('users/$uid').remove();
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
    final bookingId = _realtimeDb.ref('bookings').push().key!;
    await _realtimeDb.ref('bookings/$bookingId').set(booking.toJson());
    return bookingId;
  }

  /// Get booking by ID
  static Future<BookingModel?> getBooking(String bookingId) async {
    final snapshot = await _realtimeDb.ref('bookings/$bookingId').get();
    if (snapshot.exists) {
      return BookingModel.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
    }
    return null;
  }

  /// Update booking status
  static Future<void> updateBookingStatus(
      String bookingId, String status) async {
    await _realtimeDb.ref('bookings/$bookingId').update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Assign technician to booking
  static Future<void> assignTechnicianToBooking(
      String bookingId, String technicianId, String technicianName) async {
    await _realtimeDb.ref('bookings/$bookingId').update({
      'technicianId': technicianId,
      'technicianName': technicianName,
      'status': 'accepted',
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Get user's bookings
  static Future<List<BookingModel>> getUserBookings(String userId) async {
    final snapshot = await _realtimeDb.ref('bookings').orderByChild('userId').equalTo(userId).get();
    if (snapshot.exists) {
      final bookingsMap = Map<String, dynamic>.from(snapshot.value as Map);
      return bookingsMap.values.map((bookingData) => BookingModel.fromJson(Map<String, dynamic>.from(bookingData))).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return [];
  }

  /// Get technician's bookings
  static Future<List<BookingModel>> getTechnicianBookings(
      String technicianId) async {
    final snapshot = await _realtimeDb.ref('bookings').orderByChild('technicianId').equalTo(technicianId).get();
    if (snapshot.exists) {
      final bookingsMap = Map<String, dynamic>.from(snapshot.value as Map);
      return bookingsMap.values.map((bookingData) => BookingModel.fromJson(Map<String, dynamic>.from(bookingData))).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return [];
  }

  /// Get pending bookings for technician (by city and service)
  static Future<List<BookingModel>> getPendingBookingsForTechnician({
    required String city,
    required List<String> specializations,
  }) async {
    final snapshot = await _realtimeDb.ref('bookings').orderByChild('status').equalTo('pending').get();
    if (snapshot.exists) {
      final bookingsMap = Map<String, dynamic>.from(snapshot.value as Map);
      return bookingsMap.values
          .map((bookingData) => BookingModel.fromJson(Map<String, dynamic>.from(bookingData)))
          .where((booking) =>
              specializations.contains(booking.service) &&
              booking.address?.contains(city) == true)
          .toList();
    }
    return [];
  }

  /// Stream user's bookings (real-time updates)
  static Stream<List<BookingModel>> streamUserBookings(String userId) {
    return _realtimeDb.ref('bookings').orderByChild('userId').equalTo(userId).onValue.map((event) {
      if (event.snapshot.exists) {
        final bookingsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        return bookingsMap.values.map((bookingData) => BookingModel.fromJson(Map<String, dynamic>.from(bookingData))).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return [];
    });
  }

  /// Stream technician's bookings (real-time updates)
  static Stream<List<BookingModel>> streamTechnicianBookings(
      String technicianId) {
    return _realtimeDb.ref('bookings').orderByChild('technicianId').equalTo(technicianId).onValue.map((event) {
      if (event.snapshot.exists) {
        final bookingsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        return bookingsMap.values.map((bookingData) => BookingModel.fromJson(Map<String, dynamic>.from(bookingData))).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return [];
    });
  }
}

