import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // ✅ ADD: For debugPrint
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/technician_model.dart';
import '../models/booking_model.dart';
import '../models/billing_model.dart';
import '../firebase_options.dart';
import 'fcm_service.dart';

class FirebaseService {
  // ✅ SINGLETON: Create database instance ONCE and reuse it
  static FirebaseDatabase? _realtimeDbInstance;
  static bool _isInitialized = false;
  
  static FirebaseDatabase get _realtimeDb {
    if (_realtimeDbInstance == null || !_isInitialized) {
      try {
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
        
        debugPrint('🔥 Initializing Firebase Realtime Database with URL: $databaseURL');
        
        // ✅ FIX: Use instanceFor with the app and databaseURL
        _realtimeDbInstance = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: databaseURL!,
        );
        
        // Enable persistence for offline support (not available on web)
        if (!kIsWeb) {
          _realtimeDbInstance!.setPersistenceEnabled(true);
          _realtimeDbInstance!.setPersistenceCacheSizeBytes(10000000); // 10MB cache
        }
        
        _isInitialized = true;
        debugPrint('✅ Firebase Realtime Database initialized successfully');
      } catch (e) {
        debugPrint('❌ Error initializing Firebase Database: $e');
        rethrow;
      }
    }
    return _realtimeDbInstance!;
  }

  // ========== USER OPERATIONS ==========

  /// Create or update user
  static Future<void> saveUser(UserModel user) async {
    try {
      debugPrint('💾 Saving user: ${user.uid}');
      final userJson = user.toJson();
      debugPrint('📄 User data: $userJson');
      
      await _realtimeDb.ref('users/${user.uid}').set(userJson);
      debugPrint('✅ User saved successfully to Realtime Database');
    } catch (e) {
      debugPrint('❌ Error saving user: $e');
      rethrow;
    }
  }

  /// Get user by ID
  static Future<UserModel?> getUser(String uid) async {
    try {
      debugPrint('🔍 Fetching user: $uid');
      final snapshot = await _realtimeDb.ref('users/$uid').get();
      if (snapshot.exists && snapshot.value != null) {
        debugPrint('✅ User found: $uid');
        return UserModel.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
      }
      debugPrint('⚠️ User not found: $uid');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user: $e');
      return null;
    }
  }

  /// Update user profile
  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = DateTime.now().toIso8601String();
      await _realtimeDb.ref('users/$uid').update(data);
      debugPrint('✅ User updated: $uid');
    } catch (e) {
      debugPrint('❌ Error updating user: $e');
      rethrow;
    }
  }

  /// Delete user
  static Future<void> deleteUser(String uid) async {
    try {
      await _realtimeDb.ref('users/$uid').remove();
      debugPrint('✅ User deleted: $uid');
    } catch (e) {
      debugPrint('❌ Error deleting user: $e');
      rethrow;
    }
  }

  // ========== TECHNICIAN OPERATIONS ==========

  /// Create or update technician - Updated to match backend structure
  static Future<void> saveTechnician(TechnicianModel technician) async {
    try {
      debugPrint('💾 Saving technician: ${technician.uid}');
      
      // Backend structure for technician
      final techJson = {
        'uid': technician.uid,
        'name': technician.name,
        'mobile': technician.mobile,
        'email': technician.email,
        'city': technician.city,
        'primaryPincode': technician.primaryPincode,
        'fcmToken': technician.fcmToken,
        'specializations': technician.specializations,
        'status': technician.isOnline ? 'online' : 'offline', // Backend uses 'status'
        'busy': false, // Backend tracks busy state
        'totalJobs': technician.totalJobs,
        'rating': technician.rating,
        'walletBalance': technician.walletBalance,
        'profileImage': technician.profileImage,
        'createdAt': technician.createdAt.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      debugPrint('🔧 Technician data: $techJson');
      
      // 🔑 STEP 2A: Save to main technicians node
      await _realtimeDb.ref('technicians/${technician.uid}').set(techJson);
      debugPrint('✅ Technician saved to main node');
      
      // 🔑 STEP 2B: Save to pincode mapping (matches backend structure)
      await _saveTechnicianToMapping(technician);
      
      debugPrint('✅ Technician saved successfully to Realtime Database');
    } catch (e) {
      debugPrint('❌ Error saving technician: $e');
      rethrow;
    }
  }

  /// 🔑 STEP 2B: Save technician to pincode mapping (Updated to match backend)
  static Future<void> _saveTechnicianToMapping(TechnicianModel technician) async {
    try {
      debugPrint('🗺️ Creating pincode mapping for: ${technician.uid} -> ${technician.primaryPincode}');
      
      // Create mapping data (simplified for backend compatibility)
      final mappingData = {
        'active': technician.isOnline,
        'fcm': technician.fcmToken ?? '',
        'rating': technician.rating,
      };
      
      // Save to pincode_map/{pincode}/{technicianId} (matches backend)
      await _realtimeDb
          .ref('pincode_map/${technician.primaryPincode}/${technician.uid}')
          .set(mappingData);
      
      debugPrint('✅ Technician mapped to pincode: ${technician.primaryPincode}');
    } catch (e) {
      debugPrint('❌ Error creating pincode mapping: $e');
      rethrow;
    }
  }

  /// Get technician by ID - Updated to handle backend structure
  static Future<TechnicianModel?> getTechnician(String uid) async {
    try {
      final snapshot = await _realtimeDb.ref('technicians/$uid').get();
      
      if (snapshot.exists && snapshot.value != null) {
        final techData = Map<String, dynamic>.from(snapshot.value as Map);
        
        // Convert backend structure to model structure
        final modelData = {
          'uid': techData['uid'] ?? '',
          'name': techData['name'] ?? '',
          'mobile': techData['mobile'] ?? '',
          'email': techData['email'] ?? '',
          'city': techData['city'] ?? '',
          'primaryPincode': techData['primaryPincode'] ?? '',
          'fcmToken': techData['fcmToken'],
          'specializations': techData['specializations'] ?? [],
          'isOnline': techData['status'] == 'online', // Convert status to isOnline
          'totalJobs': techData['totalJobs'] ?? 0,
          'completedJobs': techData['completedJobs'] ?? 0, // Add this field
          'rating': techData['rating'] ?? 0.0,
          'walletBalance': techData['walletBalance'] ?? 0.0,
          'profileImage': techData['profileImage'],
          'createdAt': techData['createdAt'],
          'updatedAt': techData['updatedAt'],
        };
        
        final technician = TechnicianModel.fromJson(modelData);
        return technician;
      }
      
      return null;
    } catch (e, stackTrace) {
      return null;
    }
  }

  /// Update technician status (online/offline) - Updated to match backend
  static Future<void> updateTechnicianStatus(String uid, bool isOnline) async {
    try {
      debugPrint('🔄 Updating technician status: $uid -> ${isOnline ? 'ONLINE' : 'OFFLINE'}');
      
      // Update main technician node with backend structure
      await _realtimeDb.ref('technicians/$uid').update({
        'status': isOnline ? 'online' : 'offline', // Backend uses 'status' not 'isOnline'
        'busy': false, // Reset busy state when updating status
        'currentBooking': null, // Clear current booking
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Update mapping node status (pincode_map structure)
      final techSnapshot = await _realtimeDb.ref('technicians/$uid').get();
      if (techSnapshot.exists && techSnapshot.value != null) {
        final techData = Map<String, dynamic>.from(techSnapshot.value as Map);
        final pincode = techData['primaryPincode'];
        
        if (pincode != null) {
          await _realtimeDb
              .ref('pincode_map/$pincode/$uid')
              .update({'active': isOnline});
          debugPrint('✅ Updated pincode mapping: $pincode -> ${isOnline ? 'active' : 'inactive'}');
        }
      }
      
      debugPrint('✅ Technician status updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating technician status: $e');
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
      debugPrint('✅ Technician stats updated: $uid');
    } catch (e) {
      debugPrint('❌ Error updating technician stats: $e');
      rethrow;
    }
  }

  /// Update technician wallet balance
  static Future<void> updateTechnicianWallet(String uid, double newBalance) async {
    try {
      debugPrint('💰 Updating wallet for technician: $uid to ₹$newBalance');
      await _realtimeDb.ref('technicians/$uid').update({
        'walletBalance': newBalance,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Wallet updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating technician wallet: $e');
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
      debugPrint('❌ Error getting online technicians: $e');
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
      debugPrint('❌ Error getting technicians by service: $e');
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

  /// Stream single technician data (real-time updates)
  static Stream<TechnicianModel?> streamTechnician(String uid) {
    return _realtimeDb.ref('technicians/$uid').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final techData = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        // Convert backend structure to model structure
        final modelData = {
          'uid': techData['uid'] ?? '',
          'name': techData['name'] ?? '',
          'mobile': techData['mobile'] ?? '',
          'email': techData['email'] ?? '',
          'city': techData['city'] ?? '',
          'primaryPincode': techData['primaryPincode'] ?? '',
          'fcmToken': techData['fcmToken'],
          'specializations': techData['specializations'] ?? [],
          'isOnline': techData['status'] == 'online', // Convert status to isOnline
          'totalJobs': techData['totalJobs'] ?? 0,
          'completedJobs': techData['completedJobs'] ?? 0, // Add this field
          'rating': techData['rating'] ?? 0.0,
          'walletBalance': techData['walletBalance'] ?? 0.0,
          'profileImage': techData['profileImage'],
          'createdAt': techData['createdAt'],
          'updatedAt': techData['updatedAt'],
        };
        
        return TechnicianModel.fromJson(modelData);
      }
      return null;
    });
  }

  /// Update technician's FCM token
  static Future<void> updateTechnicianFCMToken(String uid, String fcmToken) async {
    try {
      debugPrint('🔔 Updating FCM token for technician: $uid');
      await _realtimeDb.ref('technicians/$uid').update({
        'fcmToken': fcmToken,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Also update in pincode mapping for quick access
      final techSnapshot = await _realtimeDb.ref('technicians/$uid').get();
      if (techSnapshot.exists && techSnapshot.value != null) {
        final techData = Map<String, dynamic>.from(techSnapshot.value as Map);
        final pincode = techData['primaryPincode'];
        
        if (pincode != null) {
          await _realtimeDb
              .ref('pincode_map/$pincode/$uid')
              .update({'fcm': fcmToken});
          debugPrint('✅ FCM token updated in pincode mapping: $pincode');
        }
      }
      
      debugPrint('✅ FCM token updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating FCM token: $e');
      rethrow;
    }
  }

  // ========== BACKEND COMPATIBLE FUNCTIONS ==========

  /// Accept booking (technician side) - With wallet deduction
  static Future<void> acceptBooking(String bookingId, String technicianId) async {
    try {
      debugPrint('✅ Technician accepting booking: $bookingId');
      
      // Get technician info first
      final techSnapshot = await _realtimeDb.ref('technicians/$technicianId').get();
      if (!techSnapshot.exists || techSnapshot.value == null) {
        throw Exception('Technician not found');
      }
      
      final techData = Map<String, dynamic>.from(techSnapshot.value as Map);
      final technicianName = techData['name'] ?? 'Unknown';
      
      // Try to update booking status
      try {
        await _realtimeDb.ref('bookings/$bookingId').update({
          'status': 'accepted',
          'technicianId': technicianId,
          'technicianName': technicianName,
          'assignedTo': technicianId,
          'acceptedAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ Booking updated successfully');
      } catch (updateError) {
        debugPrint('⚠️ Booking update failed (permission issue): $updateError');
      }
      
      // Update technician status to busy (No wallet deduction here, happens at completion)
      await _realtimeDb.ref('technicians/$technicianId').update({
        'busy': true,
        'currentBooking': bookingId,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ Booking accepted successfully by $technicianName');
    } catch (e) {
      debugPrint('❌ Error accepting booking: $e');
      rethrow;
    }
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Reject booking (technician side) - Matches backend logic  
  static Future<void> rejectBooking(String bookingId, String technicianId) async {
    try {
      // Add to reject log
      await _realtimeDb.ref('reject_log/$bookingId/$technicianId').set(true);
      
      // Free up technician
      await _realtimeDb.ref('technicians/$technicianId/busy').set(false);
      
      // Reset booking to pending (backend will reassign)
      await _realtimeDb.ref('bookings/$bookingId').update({
        'status': 'pending',
        'assignedTo': null,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      rethrow;
    }
  }

  /// Stream available bookings for technician — shows bookings that:
  /// 1. Are NOT completed / cancelled / rejected / accepted / in_progress
  /// 2. Have no technician assigned yet
  /// 3. Were created within the last 48 hours
  /// 4. Match the technician's pincode
  static Stream<List<BookingModel>> streamPendingBookingsForTechnician({
    required String pincode,
    required List<String> specializations,
  }) {
    return _realtimeDb.ref('bookings')
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <BookingModel>[];
      }

      final bookingsMap =
          Map<String, dynamic>.from(event.snapshot.value as Map);

      // Statuses that mean "job is done / no longer available"
      const closedStatuses = {
        'completed', 'cancelled', 'rejected', 'declined',
        'expired', 'failed', 'refunded', 'accepted', 'in_progress',
      };

      final cutoff = DateTime.now().subtract(const Duration(hours: 48));
      // Normalize technician pincode for comparison
      final techPincode = pincode.trim();

      final result = bookingsMap.entries
          .map((entry) {
            final bookingData =
                Map<String, dynamic>.from(entry.value as Map);
            bookingData['id'] = entry.key;
            return BookingModel.fromJson(bookingData);
          })
          .where((booking) {
            final status = booking.status.toLowerCase().trim();

            // 1. Hide completed / cancelled / accepted jobs
            if (closedStatuses.contains(status)) return false;

            // 2. Hide jobs already assigned to another technician
            final techId = (booking.technicianId ?? '').trim();
            if (techId.isNotEmpty &&
                techId != 'unassigned' &&
                techId != 'none') return false;

            // 3. Hide jobs older than 48 hours
            if (booking.createdAt.isBefore(cutoff)) return false;

            // 4. ✅ PINCODE FILTER — only show jobs in this technician's area
            if (techPincode.isNotEmpty) {
              final bookingPincode = (booking.pincode ?? '').trim();
              if (bookingPincode.isNotEmpty && bookingPincode != techPincode) {
                debugPrint(
                  '📍 Skipped ${booking.id}: pincode mismatch '
                  '(job=$bookingPincode, tech=$techPincode)',
                );
                return false;
              }
            }

            return true;
          })
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint(
        '📋 Jobs available for pincode $techPincode (≤48h): ${result.length}',
      );
      return result;
    });
  }

  /// Check if a booking is expired (older than 24 hours)
  static bool _isBookingExpired(BookingModel booking) {
    try {
      final now = DateTime.now();
      final createdAt = booking.createdAt; // Already a DateTime object
      final hoursDifference = now.difference(createdAt).inHours;
      
      // Consider booking expired if it's older than 24 hours and still pending
      if (hoursDifference > 24 && (booking.status == 'pending' || booking.status == 'confirmed')) {
        return true;
      }
      
      return false;
    } catch (e) {
      return false; // Don't filter out if we can't determine
    }
  }

  /// Stream technician's assigned bookings (real-time)
  static Stream<List<BookingModel>> streamTechnicianAssignedBookings(String technicianId) {
    return _realtimeDb.ref('bookings')
        .orderByChild('assignedTo')
        .equalTo(technicianId)
        .onValue
        .map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final bookingsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        return bookingsMap.entries
            .map((entry) => BookingModel.fromJson(Map<String, dynamic>.from(entry.value)))
            .where((booking) => ['assigned', 'accepted', 'in_progress'].contains(booking.status))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return [];
    });
  }

  // ========== BOOKING OPERATIONS ==========

  /// Create new booking with pincode
  static Future<String> createBooking(BookingModel booking) async {
    try {
      debugPrint('📝 Creating booking in Realtime Database...');
      debugPrint('🔑 Booking pincode: ${booking.pincode}');
      
      // ✅ Use the singleton _realtimeDb instance
      final bookingRef = _realtimeDb.ref('bookings').push();
      final bookingId = bookingRef.key!;
      
      final bookingJson = booking.toJson();
      bookingJson['id'] = bookingId;
      
      debugPrint('📄 Booking data: $bookingJson');
      await bookingRef.set(bookingJson);
      debugPrint('✅ Booking created with ID: $bookingId');
      
      // 🔔 NEW: Send push notification to technicians in the area
      await _sendBookingNotificationToTechnicians(booking.copyWith(id: bookingId));
      
      return bookingId;
    } catch (e) {
      debugPrint('❌ Error creating booking: $e');
      rethrow;
    }
  }

  /// Send push notification to technicians in the booking area
  static Future<void> _sendBookingNotificationToTechnicians(BookingModel booking) async {
    try {
      debugPrint('🔔 NOTIFICATION DEBUG: Sending notifications for booking ${booking.id}');
      debugPrint('🔔 Booking details: ${booking.service} in ${booking.pincode} for ${booking.userName}');
      
      // Get technicians in the same pincode with matching specializations
      final snapshot = await _realtimeDb.ref('technicians').get();
      if (!snapshot.exists || snapshot.value == null) {
        debugPrint('❌ NOTIFICATION DEBUG: No technicians found in database');
        return;
      }
      
      final techniciansMap = Map<String, dynamic>.from(snapshot.value as Map);
      final matchingTechnicians = <Map<String, String>>[];
      
      debugPrint('🔔 NOTIFICATION DEBUG: Found ${techniciansMap.length} total technicians');
      
      for (final entry in techniciansMap.entries) {
        final techData = Map<String, dynamic>.from(entry.value);
        final techPincode = techData['primaryPincode']?.toString();
        final techSpecializations = List<String>.from(techData['specializations'] ?? []);
        final techFcmToken = techData['fcmToken']?.toString();
        final isOnline = techData['status'] == 'online';
        final techName = techData['name']?.toString() ?? 'Unknown';
        final techId = entry.key;
        
        debugPrint('🔔 CHECKING TECHNICIAN: $techName ($techId)');
        debugPrint('  - Pincode: $techPincode (booking: ${booking.pincode})');
        debugPrint('  - Online: $isOnline');
        debugPrint('  - Specializations: $techSpecializations');
        debugPrint('  - FCM Token: ${techFcmToken?.isNotEmpty == true ? 'Present' : 'Missing'}');
        
        // Check pincode match
        final pincodeMatch = techPincode == booking.pincode;
        debugPrint('  - Pincode Match: $pincodeMatch');
        
        // Check service match
        final directServiceMatch = techSpecializations.contains(booking.service);
        final mappedServiceMatch = _isServiceMatch(booking.service, techSpecializations);
        final serviceMatch = directServiceMatch || mappedServiceMatch;
        debugPrint('  - Service Match: $serviceMatch (direct: $directServiceMatch, mapped: $mappedServiceMatch)');
        
        // Check if technician matches booking criteria
        if (pincodeMatch && 
            isOnline && 
            techFcmToken != null && 
            techFcmToken.isNotEmpty &&
            serviceMatch) {
          matchingTechnicians.add({
            'id': techId,
            'name': techName,
            'token': techFcmToken,
          });
          debugPrint('  ✅ TECHNICIAN MATCHES - Will send notification');
        } else {
          debugPrint('  ❌ TECHNICIAN DOES NOT MATCH');
          if (!pincodeMatch) debugPrint('    - Reason: Pincode mismatch');
          if (!isOnline) debugPrint('    - Reason: Technician offline');
          if (techFcmToken == null || techFcmToken.isEmpty) debugPrint('    - Reason: No FCM token');
          if (!serviceMatch) debugPrint('    - Reason: Service mismatch');
        }
      }
      
      debugPrint('🔔 NOTIFICATION DEBUG: Found ${matchingTechnicians.length} matching technicians');
      
      if (matchingTechnicians.isEmpty) {
        debugPrint('❌ NOTIFICATION DEBUG: No matching technicians found - no notifications sent');
        return;
      }
      
      // Send notifications using FCM service
      for (final tech in matchingTechnicians) {
        try {
          debugPrint('🔔 SENDING NOTIFICATION TO: ${tech['name']} (${tech['id']})');
          await FCMService.sendNotificationToToken(
            token: tech['token']!,
            title: '🔔 New Job Available!',
            body: '${booking.service} in ${booking.pincode} - ₹${booking.totalAmount.toStringAsFixed(0)}',
            data: {
              'type': 'new_booking',
              'bookingId': booking.id,
              'service': booking.service,
              'pincode': booking.pincode ?? '',
              'amount': booking.totalAmount.toString(),
              'customerName': booking.userName,
              'scheduledTime': booking.scheduledTime,
            },
          );
          debugPrint('✅ NOTIFICATION SENT TO: ${tech['name']}');
        } catch (e) {
          debugPrint('❌ FAILED TO SEND NOTIFICATION TO: ${tech['name']} - Error: $e');
          // Continue sending to other technicians even if one fails
        }
      }
      
      // Also send enhanced job alert to area
      try {
        debugPrint('🔔 SENDING AREA ALERT for pincode: ${booking.pincode}');
        await FCMService.sendJobAlertToArea(
          pincode: booking.pincode ?? '',
          service: booking.service,
          bookingId: booking.id,
          amount: booking.totalAmount,
          customerName: booking.userName,
          scheduledTime: booking.scheduledTime,
        );
        debugPrint('✅ AREA ALERT SENT');
      } catch (e) {
        debugPrint('❌ AREA ALERT FAILED: $e');
      }
      
    } catch (e) {
      debugPrint('❌ NOTIFICATION DEBUG: Error in _sendBookingNotificationToTechnicians: $e');
      // Don't block booking creation for notification failures
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
      debugPrint('❌ Error getting booking: $e');
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
      debugPrint('✅ Booking status updated: $bookingId -> $status');
    } catch (e) {
      debugPrint('❌ Error updating booking status: $e');
      rethrow;
    }
  }

  /// Upload job photo to Firebase Storage
  static Future<String> uploadJobPhoto(File photo, String bookingId, String type) async {
    try {
      debugPrint('📸 Uploading $type photo for booking $bookingId');
      final fileName = '${bookingId}_${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('job_photos/$bookingId/$fileName');
      
      final uploadTask = ref.putFile(photo);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('✅ Photo uploaded successfully. URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading photo: $e');
      rethrow;
    }
  }

  /// Update booking with photo URLs
  static Future<void> updateBookingPhotos({
    required String bookingId, 
    List<String>? beforePhotos,
    String? afterPhoto
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (beforePhotos != null && beforePhotos.isNotEmpty) {
        updates['beforePhotoUrls'] = beforePhotos;
      }
      
      if (afterPhoto != null) {
        updates['afterPhotoUrl'] = afterPhoto;
      }
      
      await _realtimeDb.ref('bookings/$bookingId').update(updates);
      debugPrint('✅ Booking photos updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating booking photos: $e');
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
      debugPrint('✅ Payment ID updated: $bookingId -> $paymentId');
    } catch (e) {
      debugPrint('❌ Error updating payment ID: $e');
      rethrow;
    }
  }

  /// 💰 Update payment status and method (Cash/UPI) — called by technician
  static Future<void> updatePaymentStatus({
    required String bookingId,
    required String paymentStatus,
    required String paymentMethod,
  }) async {
    try {
      await _realtimeDb.ref('bookings/$bookingId').update({
        'paymentStatus': paymentStatus,
        'paymentMethod': paymentMethod,
        'paymentCollectedAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Payment status updated: $bookingId → $paymentStatus ($paymentMethod)');
    } catch (e) {
      debugPrint('❌ Error updating payment status: $e');
      rethrow;
    }
  }

  /// Credit technician earnings to wallet after job completion
  /// Rule: Technician Net Earning = Final Bill - GST - Commission
  ///       = Service Amount - Commission
  /// Commission is based on Service Amount only (not Final Bill)
  /// GST goes to company account
  static Future<void> creditTechnicianEarnings({
    required String technicianId,
    required String bookingId,
    required double serviceAmount,
    required double earnings,
    required double gstAmount,
    required double commission,
    double finalBill = 0.0,
    double visitingCharge = 0.0,
    String? paymentMethod,
  }) async {
    try {
      final bool isCash = paymentMethod?.toLowerCase() == 'cash';
      
      debugPrint('💰 Processing earnings for technician $technicianId (Method: $paymentMethod)');
      debugPrint('   Service Amount: Rs.$serviceAmount | Final Bill: Rs.$finalBill');
      debugPrint('   GST: Rs.$gstAmount | Commission: Rs.$commission | Net Earnings: Rs.$earnings');

      // Get current wallet balance
      final balanceSnapshot = await _realtimeDb
          .ref('technicians/$technicianId/walletBalance')
          .get();
      
      final currentBalance = balanceSnapshot.exists 
          ? (balanceSnapshot.value as num).toDouble() 
          : 0.0;
      
      double walletImpact = 0.0;
      String transType = '';
      String transDescription = '';

      if (isCash) {
        // CASE 1: CASH
        // Tech gets full Final Bill from customer in hand.
        // Tech owes Company: GST + Commission.
        // Action: DEDUCT (GST + Commission) from wallet.
        walletImpact = -(gstAmount + commission);
        transType = 'debit';
        transDescription = 'Cash Job Fee: Commission Rs.${commission.toStringAsFixed(0)} + GST Rs.${gstAmount.toStringAsFixed(0)}';
      } else {
        // CASE 2: UPI / ONLINE
        // Company gets full Final Bill.
        // Tech is owed: Net Earnings (Service Amount - Commission).
        // Action: CREDIT (Net Earnings) to wallet.
        walletImpact = earnings;
        transType = 'credit';
        transDescription = 'Earnings: Service Rs.${serviceAmount.toStringAsFixed(0)} - Commission Rs.${commission.toStringAsFixed(0)}';
      }

      final newBalance = currentBalance + walletImpact;
      
      // Update wallet balance
      await _realtimeDb.ref('technicians/$technicianId').update({
        'walletBalance': newBalance,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Log transaction
      await _realtimeDb.ref('wallet_transactions').push().set({
        'technicianId': technicianId,
        'bookingId': bookingId,
        'type': transType,
        'paymentMethod': paymentMethod,
        'amount': walletImpact,
        'description': transDescription,
        'balanceAfter': newBalance,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'serviceAmount': serviceAmount,
        'finalBill': finalBill,
        'gstDeducted': gstAmount,
        'commissionDeducted': commission,
        'visitingCharge': visitingCharge,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Log to company ledger
      await _realtimeDb.ref('company_ledger').push().set({
        'type': 'job_settlement',
        'subType': isCash ? 'cash_deduction' : 'upi_credit',
        'bookingId': bookingId,
        'technicianId': technicianId,
        'serviceAmount': serviceAmount,
        'finalBill': finalBill,
        'gstAmount': gstAmount,
        'commissionAmount': commission,
        'totalCompanyEarning': gstAmount + commission,
        'paymentMethod': paymentMethod,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('✅ Wallet updated. Change: Rs.${walletImpact.toStringAsFixed(0)}. New balance: Rs.${newBalance.toStringAsFixed(0)}');
    } catch (e) {
      debugPrint('❌ Error updating technician wallet: $e');
      rethrow;
    }
  }


  /// Update booking with Razorpay order details and breakdown
  static Future<void> updateBookingOrderDetails({
    required String bookingId,
    required String razorpayOrderId,
    required double visitingCharge,
    required double taxableAmount,
    required double gstAmount,
    required double totalAmount,
  }) async {
    try {
      debugPrint('💰 Updating booking order details: $bookingId');
      await _realtimeDb.ref('bookings/$bookingId').update({
        'razorpayOrderId': razorpayOrderId,
        'visitingCharge': visitingCharge,
        'taxableAmount': taxableAmount,
        'gstAmount': gstAmount,
        'totalAmount': totalAmount,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Booking order details updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating booking order details: $e');
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
      debugPrint('✅ Technician assigned to booking: $bookingId');
    } catch (e) {
      debugPrint('❌ Error assigning technician: $e');
      rethrow;
    }
  }

  /// Get user's bookings
  static Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      debugPrint('🔍 Fetching bookings for user: $userId');
      final snapshot = await _realtimeDb.ref('bookings')
          .orderByChild('userId')
          .equalTo(userId)
          .get();
          
      if (snapshot.exists && snapshot.value != null) {
        final bookingsMap = Map<String, dynamic>.from(snapshot.value as Map);
        final bookings = bookingsMap.entries
            .map((entry) => BookingModel.fromJson(Map<String, dynamic>.from(entry.value)))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        debugPrint('✅ Found ${bookings.length} bookings for user');
        return bookings;
      }
      debugPrint('⚠️ No bookings found for user');
      return [];
    } catch (e) {
      debugPrint('❌ Error getting user bookings: $e');
      return [];
    }
  }

  /// Get technician's bookings
  static Future<List<BookingModel>> getTechnicianBookings(
      String technicianId) async {
    try {
      debugPrint('🔍 Fetching bookings for technician: $technicianId');
      final snapshot = await _realtimeDb.ref('bookings')
          .orderByChild('technicianId')
          .equalTo(technicianId)
          .get();
          
      if (snapshot.exists && snapshot.value != null) {
        final bookingsMap = Map<String, dynamic>.from(snapshot.value as Map);
        final bookings = bookingsMap.entries
            .map((entry) => BookingModel.fromJson(Map<String, dynamic>.from(entry.value)))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        debugPrint('✅ Found ${bookings.length} bookings for technician');
        return bookings;
      }
      debugPrint('⚠️ No bookings found for technician');
      return [];
    } catch (e) {
      debugPrint('❌ Error getting technician bookings: $e');
      return [];
    }
  }

  /// Get pending bookings for technician (by city and service)
  static Future<List<BookingModel>> getPendingBookingsForTechnician({
    required String city,
    required List<String> specializations,
  }) async {
    try {
      debugPrint('🔍 Fetching pending bookings for city: $city');
      final snapshot = await _realtimeDb.ref('bookings')
          .orderByChild('status')
          .equalTo('pending')
          .get();
          
      if (snapshot.exists && snapshot.value != null) {
        final bookingsMap = Map<String, dynamic>.from(snapshot.value as Map);
        final filteredBookings = bookingsMap.entries
            .map((entry) => BookingModel.fromJson(Map<String, dynamic>.from(entry.value)))
            .where((booking) =>
                specializations.contains(booking.service) &&
                (booking.city?.contains(city) ?? booking.address?.contains(city) ?? false))
            .toList();
        
        debugPrint('✅ Found ${filteredBookings.length} pending bookings');
        return filteredBookings;
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting pending bookings: $e');
      return [];
    }
  }

  /// Increment technician's completed jobs count
  static Future<void> incrementTechnicianCompletedJobs(String technicianId) async {
    try {
      debugPrint('📊 Incrementing completed jobs for technician: $technicianId');
      
      // Get current technician data
      final snapshot = await _realtimeDb.ref('technicians/$technicianId').get();
      
      if (snapshot.exists && snapshot.value != null) {
        final techData = Map<String, dynamic>.from(snapshot.value as Map);
        final currentCompletedJobs = techData['completedJobs'] ?? 0;
        final newCompletedJobs = currentCompletedJobs + 1;
        
        // Update completed jobs count
        await _realtimeDb.ref('technicians/$technicianId').update({
          'completedJobs': newCompletedJobs,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        
        debugPrint('✅ Updated completed jobs: $currentCompletedJobs → $newCompletedJobs');
      } else {
        debugPrint('⚠️ Technician not found, creating completed jobs field');
        await _realtimeDb.ref('technicians/$technicianId').update({
          'completedJobs': 1,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('❌ Error incrementing completed jobs: $e');
      throw Exception('Failed to update technician stats: $e');
    }
  }

  /// Submit job rating for technician
  static Future<void> submitJobRating({
    required String bookingId,
    required String technicianId,
    required double rating,
    String? feedback,
  }) async {
    try {
      debugPrint('⭐ Submitting rating $rating for technician $technicianId');

      // Save rating record
      await _realtimeDb.ref('ratings/$bookingId').set({
        'bookingId': bookingId,
        'technicianId': technicianId,
        'rating': rating,
        'feedback': feedback ?? '',
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Recalculate technician average rating
      final ratingsSnapshot = await _realtimeDb
          .ref('ratings')
          .orderByChild('technicianId')
          .equalTo(technicianId)
          .get();

      if (ratingsSnapshot.exists && ratingsSnapshot.value != null) {
        final ratingsMap = Map<String, dynamic>.from(ratingsSnapshot.value as Map);
        final ratings = ratingsMap.values
            .map((r) => _toDouble((r as Map)['rating']))
            .toList();
        final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;

        await _realtimeDb.ref('technicians/$technicianId').update({
          'rating': double.parse(avgRating.toStringAsFixed(1)),
          'updatedAt': DateTime.now().toIso8601String(),
        });
        debugPrint('✅ Technician rating updated to $avgRating');
      }
    } catch (e) {
      debugPrint('❌ Error submitting rating: $e');
      // Don't rethrow — rating failure shouldn't block the flow
    }
  }

  /// Complete job and clear technician status
  static Future<void> completeJobAndClearTechnician(String bookingId, String technicianId) async {
    try {
      debugPrint('🎯 Completing job and clearing technician status: $bookingId');
      
      // 1. Update booking status to completed
      await updateBookingStatus(bookingId, 'completed');
      
      // 2. Increment technician's completed jobs count
      await incrementTechnicianCompletedJobs(technicianId);
      
      // 3. Clear technician's busy status and current booking - KEEP ONLINE STATUS
      final techSnapshot = await _realtimeDb.ref('technicians/$technicianId').get();
      if (techSnapshot.exists && techSnapshot.value != null) {
        final techData = Map<String, dynamic>.from(techSnapshot.value as Map);
        final currentStatus = techData['status'] ?? 'offline'; // Preserve current online/offline status
        
        await _realtimeDb.ref('technicians/$technicianId').update({
          'status': currentStatus, // Keep the same online/offline status
          'busy': false, // Clear busy status
          'currentBooking': null, // Clear current booking
          'updatedAt': DateTime.now().toIso8601String(),
        });
        
        debugPrint('✅ Technician status cleared - Status: $currentStatus, Busy: false');
      }
      
      debugPrint('✅ Job completion process finished successfully');
    } catch (e) {
      debugPrint('❌ Error completing job: $e');
      rethrow;
    }
  }

  /// Stream user's bookings (real-time updates)
  static Stream<List<BookingModel>> streamUserBookings(String userId) {
    return _realtimeDb.ref('bookings')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .asyncMap((event) async {
      try {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final bookingsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
          
          final bookings = bookingsMap.entries
              .map((entry) {
                final bookingData = Map<String, dynamic>.from(entry.value);
                bookingData['id'] = entry.key; // Add the booking ID
                return BookingModel.fromJson(bookingData);
              })
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return bookings;
        }
        return <BookingModel>[];
      } catch (e) {
        // Check if it's a permission error
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('permission') || errorStr.contains('denied')) {
          // Return empty list for permission errors to avoid breaking the UI
          return <BookingModel>[];
        }
        
        // Re-throw other errors
        rethrow;
      }
    }).handleError((error) {
      // Return empty stream on error to prevent UI crashes
      return <BookingModel>[];
    });
  }

  /// Fix existing bookings by extracting pincode from address
  static Future<void> fixBookingPincodes() async {
    try {
      debugPrint('🔧 Fixing existing bookings with missing pincodes...');
      
      final snapshot = await _realtimeDb.ref('bookings').get();
      if (!snapshot.exists || snapshot.value == null) return;
      
      final bookingsMap = Map<String, dynamic>.from(snapshot.value as Map);
      int fixedCount = 0;
      
      for (final entry in bookingsMap.entries) {
        final bookingId = entry.key;
        final bookingData = Map<String, dynamic>.from(entry.value);
        
        // Skip if pincode already exists
        if (bookingData['pincode'] != null && bookingData['pincode'].toString().isNotEmpty) {
          continue;
        }
        
        // Extract pincode from address
        final address = bookingData['address']?.toString() ?? '';
        final pincodeRegex = RegExp(r'\b\d{6}\b');
        final match = pincodeRegex.firstMatch(address);
        
        if (match != null) {
          final extractedPincode = match.group(0)!;
          
          // Update booking with extracted pincode
          await _realtimeDb.ref('bookings/$bookingId').update({
            'pincode': extractedPincode,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          
          debugPrint('✅ Fixed booking $bookingId: extracted pincode $extractedPincode from address');
          fixedCount++;
        } else {
          debugPrint('⚠️ Could not extract pincode from address: $address');
        }
      }
      
      debugPrint('✅ Fixed $fixedCount bookings with missing pincodes');
    } catch (e) {
      debugPrint('❌ Error fixing booking pincodes: $e');
    }
  }

  /// Check if booking service matches technician specializations (with mapping)
  static bool _isServiceMatch(String bookingService, List<String> specializations) {
    // Direct match first
    if (specializations.contains(bookingService)) return true;
    
    // Service mapping for common variations
    final serviceMap = {
      // AC Related Services
      'General Service': ['AC Repair', 'Appliance Repair'],
      'Normal Service': ['AC Repair', 'Appliance Repair'],
      'AC Installation': ['AC Repair'],
      'AC Service': ['AC Repair'],
      'AC Repair Service': ['AC Repair'],
      'Split AC Service': ['AC Repair'],
      'Window AC Service': ['AC Repair'],
      'AC Gas Filling': ['AC Repair'],
      'AC Cleaning': ['AC Repair'],
      'AC Uninstallation': ['AC Repair'],
      'Foam Service': ['AC Repair'],
      
      // Appliance Services
      'Jet Machine Service': ['Appliance Repair'],
      'Washing Machine Repair': ['Appliance Repair'],
      'Washing Machine Service': ['Appliance Repair'],
      'Refrigerator Repair': ['Appliance Repair'],
      'Refrigerator Service': ['Appliance Repair'],
      'Single Door - Slow Working': ['Appliance Repair'],
      'Single Door - Gas Refill': ['Appliance Repair'],
      'Microwave Repair': ['Appliance Repair'],
      'Water Purifier Service': ['Appliance Repair'],
      'Chimney Service': ['Appliance Repair'],
      'Gas Refilling': ['Appliance Repair'],
      
      // Installation Services
      'Installation - Inspection Required': ['AC Repair', 'Appliance Repair'],
      
      // Carpenter Services
      'Carpenter Work': ['Carpenter'],
      'Wood Work': ['Carpenter'],
      'Furniture Repair': ['Carpenter'],
    };
    
    final mappedServices = serviceMap[bookingService] ?? [];
    final hasMatch = specializations.any((spec) => mappedServices.contains(spec));
    
    return hasMatch;
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

  // ==================== DYNAMIC SERVICES & PRICING ====================

  /// Get all active services from Firebase (checks both services/ and pricing/ nodes)
  static Future<List<dynamic>> getActiveServices() async {
    try {
      debugPrint('🔍 Fetching active services from Firebase...');
      
      List<Map<String, dynamic>> allServices = [];
      
      // Try services/ node first
      final servicesSnapshot = await _realtimeDb.ref('services').get();
      if (servicesSnapshot.exists) {
        final Map<dynamic, dynamic> servicesMap = servicesSnapshot.value as Map<dynamic, dynamic>;
        servicesMap.forEach((key, value) {
          final serviceData = Map<String, dynamic>.from(value as Map);
          serviceData['id'] = key;
          
          // Only include active services
          if (serviceData['status'] == 'active') {
            allServices.add(serviceData);
          }
        });
        debugPrint('✅ Found ${allServices.length} services in services/ node');
      }
      
      // Also check pricing/ node for additional services
      final pricingSnapshot = await _realtimeDb.ref('pricing').get();
      if (pricingSnapshot.exists) {
        final Map<dynamic, dynamic> pricingMap = pricingSnapshot.value as Map<dynamic, dynamic>;
        
        // Extract unique service types from pricing
        Set<String> uniqueServiceTypes = {};
        pricingMap.forEach((key, value) {
          final pricingData = Map<String, dynamic>.from(value as Map);
          final serviceType = pricingData['serviceType'] ?? pricingData['acType'] ?? '';
          if (serviceType.isNotEmpty) {
            uniqueServiceTypes.add(serviceType);
          }
        });
        
        // Add unique service types as services
        for (var serviceType in uniqueServiceTypes) {
          // Check if this service type already exists
          final exists = allServices.any((s) => 
            s['name'].toString().toLowerCase() == serviceType.toLowerCase()
          );
          
          if (!exists) {
            allServices.add({
              'id': serviceType.toLowerCase().replaceAll(' ', '-'),
              'name': serviceType,
              'icon': _getIconForServiceType(serviceType),
              'bgColor': _getColorForServiceType(serviceType),
              'type': serviceType.toLowerCase().replaceAll(' ', '_'),
              'status': 'active',
              'order': allServices.length + 100,
            });
            debugPrint('✅ Added service from pricing: $serviceType');
          }
        }
      }

      // Sort by order
      allServices.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));
      
      debugPrint('✅ Total active services: ${allServices.length}');
      return allServices;
    } catch (e) {
      debugPrint('❌ Error fetching services: $e');
      return [];
    }
  }

  /// Get icon for service type
  static String _getIconForServiceType(String serviceType) {
    final type = serviceType.toLowerCase();
    if (type.contains('cctv')) return 'videocam';
    if (type.contains('plumb')) return 'plumbing';
    if (type.contains('tv')) return 'tv';
    if (type.contains('electric')) return 'bolt';
    if (type.contains('paint')) return 'format_paint';
    if (type.contains('carpen')) return 'carpenter';
    if (type.contains('clean')) return 'cleaning_services';
    if (type.contains('ac') || type.contains('air')) return 'ac_unit';
    return 'build';
  }

  /// Get color for service type
  static String _getColorForServiceType(String serviceType) {
    final type = serviceType.toLowerCase();
    if (type.contains('cctv')) return '#FFE0B2';
    if (type.contains('plumb')) return '#E1F5FE';
    if (type.contains('tv')) return '#F3E5F5';
    if (type.contains('electric')) return '#FFF9C4';
    if (type.contains('paint')) return '#F1F8E9';
    if (type.contains('carpen')) return '#FFF3E0';
    if (type.contains('clean')) return '#E0F2F1';
    return '#E0F7F4';
  }

  /// Get pricing for a specific service
  static Future<Map<String, dynamic>?> getServicePricing(String serviceId) async {
    try {
      debugPrint('🔍 Fetching pricing for service: $serviceId');
      final snapshot = await _realtimeDb.ref('pricing/$serviceId').get();
      
      if (!snapshot.exists) {
        debugPrint('⚠️ No pricing found for service: $serviceId');
        return null;
      }

      final pricingData = Map<String, dynamic>.from(snapshot.value as Map);
      pricingData['serviceId'] = serviceId;
      
      debugPrint('✅ Fetched pricing for $serviceId');
      return pricingData;
    } catch (e) {
      debugPrint('❌ Error fetching pricing: $e');
      return null;
    }
  }

  /// Get all pricing data
  static Future<Map<String, Map<String, dynamic>>> getAllPricing() async {
    try {
      debugPrint('🔍 Fetching all pricing data...');
      final snapshot = await _realtimeDb.ref('pricing').get();
      
      if (!snapshot.exists) {
        debugPrint('⚠️ No pricing data found');
        return {};
      }

      final Map<dynamic, dynamic> pricingMap = snapshot.value as Map<dynamic, dynamic>;
      final Map<String, Map<String, dynamic>> pricing = {};

      pricingMap.forEach((key, value) {
        final pricingData = Map<String, dynamic>.from(value as Map);
        pricingData['serviceId'] = key;
        pricing[key] = pricingData;
      });

      debugPrint('✅ Fetched pricing for ${pricing.length} services');
      return pricing;
    } catch (e) {
      debugPrint('❌ Error fetching all pricing: $e');
      return {};
    }
  }

  /// Listen to services changes in real-time
  static Stream<List<Map<String, dynamic>>> servicesStream() {
    return _realtimeDb.ref('services').onValue.map((event) {
      if (!event.snapshot.exists) {
        return <Map<String, dynamic>>[];
      }

      final Map<dynamic, dynamic> servicesMap = event.snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> services = [];

      servicesMap.forEach((key, value) {
        final serviceData = Map<String, dynamic>.from(value as Map);
        serviceData['id'] = key;
        
        // Only include active services
        if (serviceData['status'] == 'active') {
          services.add(serviceData);
        }
      });

      // Sort by order
      services.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));
      
      return services;
    });
  }

  /// Listen to pricing changes in real-time
  static Stream<Map<String, Map<String, dynamic>>> pricingStream() {
    return _realtimeDb.ref('pricing').onValue.map((event) {
      if (!event.snapshot.exists) {
        return <String, Map<String, dynamic>>{};
      }

      final Map<dynamic, dynamic> pricingMap = event.snapshot.value as Map<dynamic, dynamic>;
      final Map<String, Map<String, dynamic>> pricing = {};

      pricingMap.forEach((key, value) {
        final pricingData = Map<String, dynamic>.from(value as Map);
        pricingData['serviceId'] = key;
        pricing[key] = pricingData;
      });

      return pricing;
    });
  }

  // ========== PROFILE & KYC OPERATIONS ==========

  /// Update technician profile fields
  static Future<void> updateTechnicianProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = DateTime.now().toIso8601String();
      await _realtimeDb.ref('technicians/$uid').update(data);
      debugPrint('✅ Technician profile updated: $uid');
    } catch (e) {
      debugPrint('❌ Error updating technician profile: $e');
      rethrow;
    }
  }

  /// Upload KYC document URL and save to Firebase (no Storage, store URL directly)
  static Future<void> uploadKYCDocument(String uid, String type, String imageUrl) async {
    try {
      debugPrint('📄 Saving KYC document ($type) for technician: $uid');
      await _realtimeDb.ref('technicians/$uid/kyc').update({
        type: imageUrl,
        '${type}Status': 'pending_review',
        '${type}UploadedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ KYC document saved: $type');
    } catch (e) {
      debugPrint('❌ Error saving KYC document: $e');
      rethrow;
    }
  }

  /// Get recent notifications combining FCM notifications + pending bookings
  static Future<List<Map<String, dynamic>>> getRecentNotifications(
    String technicianId,
    String pincode,
    List<String> specializations,
  ) async {
    try {
      final List<Map<String, dynamic>> allNotifications = [];

      // Fetch recent pending bookings matching pincode + specializations
      final snapshot = await _realtimeDb.ref('bookings').get();
      if (snapshot.exists && snapshot.value != null) {
        final bookingsMap = Map<String, dynamic>.from(snapshot.value as Map);
        final now = DateTime.now();

        for (final entry in bookingsMap.entries) {
          final bookingData = Map<String, dynamic>.from(entry.value);
          bookingData['id'] = entry.key;

          final status = bookingData['status']?.toString() ?? '';
          if (status != 'pending') continue;

          // Pincode check
          String? bookingPincode = bookingData['pincode']?.toString();
          if (bookingPincode == null || bookingPincode.isEmpty) {
            final address = bookingData['address']?.toString() ?? '';
            final match = RegExp(r'\b\d{6}\b').firstMatch(address);
            bookingPincode = match?.group(0);
          }
          if (bookingPincode != pincode) continue;

          // Service match
          final service = bookingData['service']?.toString() ?? '';
          final serviceMatch = specializations.contains(service) ||
              _isServiceMatch(service, specializations);
          if (!serviceMatch) continue;

          // Only bookings from last 24h
          try {
            final createdAt = DateTime.parse(bookingData['createdAt'].toString());
            if (now.difference(createdAt).inHours > 24) continue;
          } catch (_) {}

          allNotifications.add({
            'type': 'new_booking',
            'title': '🔔 New Job Available!',
            'body': '${bookingData['service']} in $bookingPincode - ₹${bookingData['totalAmount'] ?? 'N/A'}',
            'service': service,
            'amount': bookingData['totalAmount']?.toString(),
            'bookingId': entry.key,
            'customerName': bookingData['userName'],
            'timestamp': bookingData['createdAt'],
            'source': 'firebase',
          });
        }
      }

      // Sort by timestamp descending
      allNotifications.sort((a, b) {
        try {
          return DateTime.parse(b['timestamp'].toString())
              .compareTo(DateTime.parse(a['timestamp'].toString()));
        } catch (_) {
          return 0;
        }
      });

      debugPrint('🔔 getRecentNotifications: found ${allNotifications.length} items');
      return allNotifications;
    } catch (e) {
      debugPrint('❌ Error fetching recent notifications: $e');
      return [];
    }
  }

  /// Get service by ID
  static Future<Map<String, dynamic>?> getServiceById(String serviceId) async {
    try {
      debugPrint('🔍 Fetching service: $serviceId');
      final snapshot = await _realtimeDb.ref('services/$serviceId').get();
      
      if (!snapshot.exists) {
        debugPrint('⚠️ Service not found: $serviceId');
        return null;
      }

      final serviceData = Map<String, dynamic>.from(snapshot.value as Map);
      serviceData['id'] = serviceId;
      
      debugPrint('✅ Fetched service: $serviceId');
      return serviceData;
    } catch (e) {
      debugPrint('❌ Error fetching service: $e');
      return null;
    }
  }
}
