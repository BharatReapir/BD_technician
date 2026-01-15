import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/technician_model.dart';
import '../models/booking_model.dart';
import '../firebase_options.dart';

class FirebaseService {
  static FirebaseDatabase? _realtimeDbInstance;
  
  static FirebaseDatabase get _realtimeDb {
    if (_realtimeDbInstance == null) {
      try {
        // Get the databaseURL from firebase_options.dart based on platform
        String? databaseURL;
        
        if (kIsWeb) {
          databaseURL = DefaultFirebaseOptions.web.databaseURL;
        } else {
          switch (defaultTargetPlatform) {
            case TargetPlatform.android:
              databaseURL = DefaultFirebaseOptions.android.databaseURL;
              break;
            case TargetPlatform.iOS:
              databaseURL = DefaultFirebaseOptions.ios.databaseURL;
              break;
            case TargetPlatform.macOS:
              databaseURL = DefaultFirebaseOptions.macos.databaseURL;
              break;
            case TargetPlatform.windows:
              databaseURL = DefaultFirebaseOptions.windows.databaseURL;
              break;
            default:
              databaseURL = DefaultFirebaseOptions.android.databaseURL;
          }
        }
        
        print('Initializing Firebase Realtime Database with URL: $databaseURL');
        
        _realtimeDbInstance = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: databaseURL!,
        );
        
        // Enable persistence for offline support (not available on web)
        if (!kIsWeb) {
          _realtimeDbInstance!.setPersistenceEnabled(true);
        }
        
        print('Firebase Realtime Database initialized successfully');
      } catch (e) {
        print('Error initializing Firebase Database: $e');
        rethrow;
      }
    }
    return _realtimeDbInstance!;
  }

  // ========== USER OPERATIONS ==========

  /// Create or update user
  static Future<void> saveUser(UserModel user) async {
    try {
      print('Saving user: ${user.uid}');
      final userJson = user.toJson();
      print('User data: $userJson');
      
      await _realtimeDb.ref('users/${user.uid}').set(userJson);
      print('User saved successfully to Realtime Database');
    } catch (e) {
      print('Error saving user: $e');
      rethrow;
    }
  }

  /// Get user by ID
  static Future<UserModel?> getUser(String uid) async {
    try {
      print('Fetching user: $uid');
      final snapshot = await _realtimeDb.ref('users/$uid').get();
      if (snapshot.exists && snapshot.value != null) {
        print('User found: $uid');
        return UserModel.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
      }
      print('User not found: $uid');
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Update user profile
  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = DateTime.now().toIso8601String();
      await _realtimeDb.ref('users/$uid').update(data);
      print('User updated: $uid');
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  /// Delete user
  static Future<void> deleteUser(String uid) async {
    try {
      await _realtimeDb.ref('users/$uid').remove();
      print('User deleted: $uid');
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // ========== TECHNICIAN OPERATIONS ==========

  /// Create or update technician
  static Future<void> saveTechnician(TechnicianModel technician) async {
    try {
      print('Saving technician: ${technician.uid}');
      final techJson = technician.toJson();
      print('Technician data: $techJson');
      
      await _realtimeDb.ref('technicians/${technician.uid}').set(techJson);
      print('Technician saved successfully to Realtime Database');
    } catch (e) {
      print('Error saving technician: $e');
      rethrow;
    }
  }

  /// Get technician by ID
  static Future<TechnicianModel?> getTechnician(String uid) async {
    try {
      final snapshot = await _realtimeDb.ref('technicians/$uid').get();
      if (snapshot.exists && snapshot.value != null) {
        return TechnicianModel.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
      }
      return null;
    } catch (e) {
      print('Error getting technician: $e');
      return null;
    }
  }

  /// Update technician status (online/offline)
  static Future<void> updateTechnicianStatus(String uid, bool isOnline) async {
    try {
      await _realtimeDb.ref('technicians/$uid').update({
        'isOnline': isOnline,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating technician status: $e');
      rethrow;
    }
  }

  /// Update technician stats
  static Future<void> updateTechnicianStats({
    required String uid,
    required int totalJobs,
    required double monthlyEarnings,
    required double rating,
  }) async {
    try {
      await _realtimeDb.ref('technicians/$uid').update({
        'totalJobs': totalJobs,
        'monthlyEarnings': monthlyEarnings,
        'rating': rating,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating technician stats: $e');
      rethrow;
    }
  }

  /// Update technician wallet balance
  static Future<void> updateTechnicianWallet(String uid, double newBalance) async {
    try {
      print('💰 Updating wallet for technician: $uid to ₹$newBalance');
      await _realtimeDb.ref('technicians/$uid').update({
        'walletBalance': newBalance,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Wallet updated successfully');
    } catch (e) {
      print('Error updating technician wallet: $e');
      rethrow;
    }
  }

  /// Get all online technicians by city
  static Future<List<TechnicianModel>> getOnlineTechnicians(String city) async {
    try {
      final snapshot = await _realtimeDb.ref('technicians').get();
      if (!snapshot.exists || snapshot.value == null) return [];

      final techniciansMap = Map<String, dynamic>.from(snapshot.value as Map);
      return techniciansMap.entries
          .map((entry) => TechnicianModel.fromJson(Map<String, dynamic>.from(entry.value)))
          .where((tech) => tech.city == city && tech.isOnline == true)
          .toList();
    } catch (e) {
      print('Error getting online technicians: $e');
      return [];
    }
  }

  /// Get technicians by specialization
  static Future<List<TechnicianModel>> getTechniciansByService(
      String service, String city) async {
    try {
      final snapshot = await _realtimeDb.ref('technicians').get();
      if (!snapshot.exists || snapshot.value == null) return [];

      final techniciansMap = Map<String, dynamic>.from(snapshot.value as Map);
      return techniciansMap.entries
          .map((entry) => TechnicianModel.fromJson(Map<String, dynamic>.from(entry.value)))
          .where((tech) => 
              tech.city == city && 
              tech.specializations.contains(service))
          .toList();
    } catch (e) {
      print('Error getting technicians by service: $e');
      return [];
    }
  }

  /// Stream online technicians by city (real-time updates)
  static Stream<List<TechnicianModel>> streamOnlineTechnicians(String city) {
    return _realtimeDb.ref('technicians').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final techniciansMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        return techniciansMap.entries
            .map((entry) => TechnicianModel.fromJson(Map<String, dynamic>.from(entry.value)))
            .where((tech) => tech.city == city && tech.isOnline == true)
            .toList();
      }
      return [];
    });
  }

  // ========== BOOKING OPERATIONS ==========

  /// Create new booking
  static Future<String> createBooking(BookingModel booking) async {
    try {
      print('Creating booking in Realtime Database...');
      final bookingRef = _realtimeDb.ref('bookings').push();
      final bookingId = bookingRef.key!;
      
      final bookingJson = booking.toJson();
      bookingJson['id'] = bookingId;
      
      print('Booking data: $bookingJson');
      await bookingRef.set(bookingJson);
      print('Booking created with ID: $bookingId');
      
      return bookingId;
    } catch (e) {
      print('Error creating booking: $e');
      rethrow;
    }
  }

  /// Get booking by ID
  static Future<BookingModel?> getBooking(String bookingId) async {
    try {
      final snapshot = await _realtimeDb.ref('bookings/$bookingId').get();
      if (snapshot.exists && snapshot.value != null) {
        return BookingModel.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
      }
      return null;
    } catch (e) {
      print('Error getting booking: $e');
      return null;
    }
  }

  /// Update booking status
  static Future<void> updateBookingStatus(
      String bookingId, String status) async {
    try {
      await _realtimeDb.ref('bookings/$bookingId').update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Booking status updated: $bookingId -> $status');
    } catch (e) {
      print('Error updating booking status: $e');
      rethrow;
    }
  }

  /// Update booking payment details
  static Future<void> updateBookingPaymentId(
      String bookingId, String paymentId) async {
    try {
      await _realtimeDb.ref('bookings/$bookingId').update({
        'paymentId': paymentId,
        'paymentStatus': 'completed',
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Payment ID updated: $bookingId -> $paymentId');
    } catch (e) {
      print('Error updating payment ID: $e');
      rethrow;
    }
  }

  /// Assign technician to booking
  static Future<void> assignTechnicianToBooking(
      String bookingId, String technicianId, String technicianName) async {
    try {
      await _realtimeDb.ref('bookings/$bookingId').update({
        'technicianId': technicianId,
        'technicianName': technicianName,
        'status': 'accepted',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error assigning technician: $e');
      rethrow;
    }
  }

  /// Get user's bookings
  static Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      final snapshot = await _realtimeDb.ref('bookings')
          .orderByChild('userId')
          .equalTo(userId)
          .get();
          
      if (snapshot.exists && snapshot.value != null) {
        final bookingsMap = Map<String, dynamic>.from(snapshot.value as Map);
        return bookingsMap.entries
            .map((entry) => BookingModel.fromJson(Map<String, dynamic>.from(entry.value)))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return [];
    } catch (e) {
      print('Error getting user bookings: $e');
      return [];
    }
  }

  /// Get technician's bookings
  static Future<List<BookingModel>> getTechnicianBookings(
      String technicianId) async {
    try {
      final snapshot = await _realtimeDb.ref('bookings')
          .orderByChild('technicianId')
          .equalTo(technicianId)
          .get();
          
      if (snapshot.exists && snapshot.value != null) {
        final bookingsMap = Map<String, dynamic>.from(snapshot.value as Map);
        return bookingsMap.entries
            .map((entry) => BookingModel.fromJson(Map<String, dynamic>.from(entry.value)))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return [];
    } catch (e) {
      print('Error getting technician bookings: $e');
      return [];
    }
  }

  /// Get pending bookings for technician (by city and service)
  static Future<List<BookingModel>> getPendingBookingsForTechnician({
    required String city,
    required List<String> specializations,
  }) async {
    try {
      final snapshot = await _realtimeDb.ref('bookings')
          .orderByChild('status')
          .equalTo('pending')
          .get();
          
      if (snapshot.exists && snapshot.value != null) {
        final bookingsMap = Map<String, dynamic>.from(snapshot.value as Map);
        return bookingsMap.entries
            .map((entry) => BookingModel.fromJson(Map<String, dynamic>.from(entry.value)))
            .where((booking) =>
                specializations.contains(booking.service) &&
                (booking.address?.contains(city) ?? false))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting pending bookings: $e');
      return [];
    }
  }

  /// Stream user's bookings (real-time updates)
  static Stream<List<BookingModel>> streamUserBookings(String userId) {
    return _realtimeDb.ref('bookings')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final bookingsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        return bookingsMap.entries
            .map((entry) => BookingModel.fromJson(Map<String, dynamic>.from(entry.value)))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return [];
    });
  }

  /// Stream technician's bookings (real-time updates)
  static Stream<List<BookingModel>> streamTechnicianBookings(
      String technicianId) {
    return _realtimeDb.ref('bookings')
        .orderByChild('technicianId')
        .equalTo(technicianId)
        .onValue
        .map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final bookingsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        return bookingsMap.entries
            .map((entry) => BookingModel.fromJson(Map<String, dynamic>.from(entry.value)))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return [];
    });
  }
}