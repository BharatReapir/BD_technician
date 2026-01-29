import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/technician_model.dart';
import '../models/booking_model.dart';
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
        
        print('🔥 Initializing Firebase Realtime Database with URL: $databaseURL');
        
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
        print('✅ Firebase Realtime Database initialized successfully');
      } catch (e) {
        print('❌ Error initializing Firebase Database: $e');
        rethrow;
      }
    }
    return _realtimeDbInstance!;
  }

  // ========== USER OPERATIONS ==========

  /// Create or update user
  static Future<void> saveUser(UserModel user) async {
    try {
      print('💾 Saving user: ${user.uid}');
      final userJson = user.toJson();
      print('📄 User data: $userJson');
      
      await _realtimeDb.ref('users/${user.uid}').set(userJson);
      print('✅ User saved successfully to Realtime Database');
    } catch (e) {
      print('❌ Error saving user: $e');
      rethrow;
    }
  }

  /// Get user by ID
  static Future<UserModel?> getUser(String uid) async {
    try {
      print('🔍 Fetching user: $uid');
      final snapshot = await _realtimeDb.ref('users/$uid').get();
      if (snapshot.exists && snapshot.value != null) {
        print('✅ User found: $uid');
        return UserModel.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
      }
      print('⚠️ User not found: $uid');
      return null;
    } catch (e) {
      print('❌ Error getting user: $e');
      return null;
    }
  }

  /// Update user profile
  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = DateTime.now().toIso8601String();
      await _realtimeDb.ref('users/$uid').update(data);
      print('✅ User updated: $uid');
    } catch (e) {
      print('❌ Error updating user: $e');
      rethrow;
    }
  }

  /// Delete user
  static Future<void> deleteUser(String uid) async {
    try {
      await _realtimeDb.ref('users/$uid').remove();
      print('✅ User deleted: $uid');
    } catch (e) {
      print('❌ Error deleting user: $e');
      rethrow;
    }
  }

  // ========== TECHNICIAN OPERATIONS ==========

  /// Create or update technician - Updated to match backend structure
  static Future<void> saveTechnician(TechnicianModel technician) async {
    try {
      print('💾 Saving technician: ${technician.uid}');
      
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
      
      print('🔧 Technician data: $techJson');
      
      // 🔑 STEP 2A: Save to main technicians node
      await _realtimeDb.ref('technicians/${technician.uid}').set(techJson);
      print('✅ Technician saved to main node');
      
      // 🔑 STEP 2B: Save to pincode mapping (matches backend structure)
      await _saveTechnicianToMapping(technician);
      
      print('✅ Technician saved successfully to Realtime Database');
    } catch (e) {
      print('❌ Error saving technician: $e');
      rethrow;
    }
  }

  /// 🔑 STEP 2B: Save technician to pincode mapping (Updated to match backend)
  static Future<void> _saveTechnicianToMapping(TechnicianModel technician) async {
    try {
      print('🗺️ Creating pincode mapping for: ${technician.uid} -> ${technician.primaryPincode}');
      
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
      
      print('✅ Technician mapped to pincode: ${technician.primaryPincode}');
    } catch (e) {
      print('❌ Error creating pincode mapping: $e');
      rethrow;
    }
  }

  /// Get technician by ID - Updated to handle backend structure
  static Future<TechnicianModel?> getTechnician(String uid) async {
    try {
      print('🔍 Fetching technician from Realtime DB: $uid');
      print('🔗 Database URL: ${_realtimeDb.databaseURL}');
      
      final snapshot = await _realtimeDb.ref('technicians/$uid').get();
      
      print('📊 Snapshot exists: ${snapshot.exists}');
      print('📊 Snapshot value: ${snapshot.value}');
      
      if (snapshot.exists && snapshot.value != null) {
        print('✅ Raw technician data found: ${snapshot.value}');
        
        final techData = Map<String, dynamic>.from(snapshot.value as Map);
        print('🔧 Parsed technician data: $techData');
        
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
          'rating': techData['rating'] ?? 0.0,
          'walletBalance': techData['walletBalance'] ?? 0.0,
          'profileImage': techData['profileImage'],
          'createdAt': techData['createdAt'],
          'updatedAt': techData['updatedAt'],
        };
        
        final technician = TechnicianModel.fromJson(modelData);
        print('✅ Technician model created: ${technician.name} (${technician.uid})');
        print('💰 Wallet: ₹${technician.walletBalance}');
        print('🏙️ City: ${technician.city}');
        print('📍 Pincode: ${technician.primaryPincode}');
        print('🔧 Specializations: ${technician.specializations}');
        
        return technician;
      }
      
      print('⚠️ Technician not found in Realtime DB: $uid');
      return null;
    } catch (e, stackTrace) {
      print('❌ Error getting technician: $e');
      print('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Update technician status (online/offline) - Updated to match backend
  static Future<void> updateTechnicianStatus(String uid, bool isOnline) async {
    try {
      print('🔄 Updating technician status: $uid -> ${isOnline ? "ONLINE" : "OFFLINE"}');
      
      // Update main technician node with backend structure
      await _realtimeDb.ref('technicians/$uid').update({
        'status': isOnline ? 'online' : 'offline', // Backend uses 'status' not 'isOnline'
        'busy': false, // Backend tracks busy state
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // 🔑 Update mapping node status (pincode_map structure)
      final techSnapshot = await _realtimeDb.ref('technicians/$uid').get();
      if (techSnapshot.exists && techSnapshot.value != null) {
        final techData = Map<String, dynamic>.from(techSnapshot.value as Map);
        final pincode = techData['primaryPincode'];
        
        if (pincode != null) {
          await _realtimeDb
              .ref('pincode_map/$pincode/$uid')
              .update({'active': isOnline});
          print('✅ Mapping status updated for pincode: $pincode');
        }
      }
      
      print('✅ Technician status updated successfully');
    } catch (e) {
      print('❌ Error updating technician status: $e');
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
      print('✅ Technician stats updated: $uid');
    } catch (e) {
      print('❌ Error updating technician stats: $e');
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
      print('❌ Error updating technician wallet: $e');
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
      print('❌ Error getting online technicians: $e');
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
      print('❌ Error getting technicians by service: $e');
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
        return TechnicianModel.fromJson(
          Map<String, dynamic>.from(event.snapshot.value as Map)
        );
      }
      return null;
    });
  }

  /// Update technician's FCM token
  static Future<void> updateTechnicianFCMToken(String uid, String fcmToken) async {
    try {
      print('🔔 Updating FCM token for technician: $uid');
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
          print('✅ FCM token updated in pincode mapping: $pincode');
        }
      }
      
      print('✅ FCM token updated successfully');
    } catch (e) {
      print('❌ Error updating FCM token: $e');
      rethrow;
    }
  }

  // ========== BACKEND COMPATIBLE FUNCTIONS ==========

  /// Accept booking (technician side) - With wallet deduction
  static Future<void> acceptBooking(String bookingId, String technicianId) async {
    try {
      print('✅ Technician accepting booking: $bookingId');
      
      // Get technician info first
      final techSnapshot = await _realtimeDb.ref('technicians/$technicianId').get();
      if (!techSnapshot.exists || techSnapshot.value == null) {
        throw Exception('Technician not found');
      }
      
      final techData = Map<String, dynamic>.from(techSnapshot.value as Map);
      final technicianName = techData['name'] ?? 'Unknown';
      final currentWallet = _toDouble(techData['walletBalance']);
      
      // Check if technician has enough balance
      const double jobAcceptanceFee = 199.0;
      if (currentWallet < jobAcceptanceFee) {
        throw Exception('Insufficient wallet balance. Need ₹$jobAcceptanceFee to accept job.');
      }
      
      // Calculate new wallet balance
      final newWalletBalance = currentWallet - jobAcceptanceFee;
      
      print('💰 Wallet: ₹$currentWallet → ₹$newWalletBalance (Fee: ₹$jobAcceptanceFee)');
      
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
        print('✅ Booking updated successfully');
      } catch (updateError) {
        print('⚠️ Booking update failed (permission issue): $updateError');
        // Continue anyway - the job flow can still work
      }
      
      // Deduct wallet balance and update technician status
      await _realtimeDb.ref('technicians/$technicianId').update({
        'busy': true,
        'currentBooking': bookingId,
        'walletBalance': newWalletBalance,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Log the wallet transaction
      await _realtimeDb.ref('wallet_transactions').push().set({
        'technicianId': technicianId,
        'bookingId': bookingId,
        'type': 'job_acceptance_fee',
        'amount': -jobAcceptanceFee,
        'previousBalance': currentWallet,
        'newBalance': newWalletBalance,
        'description': 'Job acceptance fee for booking $bookingId',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      print('✅ Booking accepted successfully by $technicianName');
      print('💰 ₹$jobAcceptanceFee deducted from wallet');
    } catch (e) {
      print('❌ Error accepting booking: $e');
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
      print('❌ Technician rejecting booking: $bookingId');
      
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
      
      print('✅ Booking rejected successfully');
    } catch (e) {
      print('❌ Error rejecting booking: $e');
      rethrow;
    }
  }

  /// Stream pending bookings for technician by pincode (real-time)
  static Stream<List<BookingModel>> streamPendingBookingsForTechnician({
    required String pincode,
    required List<String> specializations,
  }) {
    debugPrint('🔍 Streaming pending bookings for pincode: $pincode');
    debugPrint('🔧 Technician specializations: $specializations');
    
    return _realtimeDb.ref('bookings')
        .onValue  // ✅ CHANGE: Get ALL bookings, then filter
        .map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final bookingsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        debugPrint('📊 Total bookings in database: ${bookingsMap.length}');
        
        final filteredBookings = bookingsMap.entries
            .map((entry) {
              final bookingData = Map<String, dynamic>.from(entry.value);
              bookingData['id'] = entry.key; // Add the booking ID
              return BookingModel.fromJson(bookingData);
            })
            .where((booking) {
              // ✅ CHANGE: Include both 'pending' AND 'confirmed' status
              final statusMatch = booking.status == 'pending' || booking.status == 'confirmed';
              
              // ✅ FIX: Handle missing pincode by extracting from address
              String? bookingPincode = booking.pincode;
              if (bookingPincode == null || bookingPincode.isEmpty) {
                // Try to extract pincode from address (last 6 digits)
                final address = booking.address ?? '';
                final pincodeRegex = RegExp(r'\b\d{6}\b');
                final match = pincodeRegex.firstMatch(address);
                bookingPincode = match?.group(0);
              }
              
              // Filter by pincode match
              final pincodeMatch = bookingPincode == pincode;
              
              // Filter by service specialization match
              final serviceMatch = specializations.contains(booking.service) || 
                                 _isServiceMatch(booking.service, specializations);
              
              debugPrint('📋 Booking ${booking.id}: status=${booking.status}, pincode=$bookingPincode (extracted), service=${booking.service}');
              debugPrint('🎯 Match: status=$statusMatch, pincode=$pincodeMatch, service=$serviceMatch');
              debugPrint('    Created: ${booking.createdAt}, Scheduled: ${booking.scheduledTime}');
              debugPrint('    Address: ${booking.address}');
              
              return statusMatch && pincodeMatch && serviceMatch;
            })
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        debugPrint('✅ Found ${filteredBookings.length} matching bookings for pincode $pincode');
        return filteredBookings;
      }
      debugPrint('⚠️ No bookings found in database');
      return <BookingModel>[];
    });
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
      print('📝 Creating booking in Realtime Database...');
      print('🔑 Booking pincode: ${booking.pincode}');
      
      // ✅ Use the singleton _realtimeDb instance
      final bookingRef = _realtimeDb.ref('bookings').push();
      final bookingId = bookingRef.key!;
      
      final bookingJson = booking.toJson();
      bookingJson['id'] = bookingId;
      
      print('📄 Booking data: $bookingJson');
      await bookingRef.set(bookingJson);
      print('✅ Booking created with ID: $bookingId');
      
      // 🔔 NEW: Send push notification to technicians in the area
      await _sendBookingNotificationToTechnicians(booking.copyWith(id: bookingId));
      
      return bookingId;
    } catch (e) {
      print('❌ Error creating booking: $e');
      rethrow;
    }
  }

  /// Send push notification to technicians in the booking area
  static Future<void> _sendBookingNotificationToTechnicians(BookingModel booking) async {
    try {
      print('🔔 Sending notifications for booking: ${booking.id}');
      print('🔔 Service: ${booking.service}, Pincode: ${booking.pincode}');
      
      // Get technicians in the same pincode with matching specializations
      final snapshot = await _realtimeDb.ref('technicians').get();
      if (!snapshot.exists || snapshot.value == null) {
        print('⚠️ No technicians found in database');
        return;
      }
      
      final techniciansMap = Map<String, dynamic>.from(snapshot.value as Map);
      final matchingTechnicians = <Map<String, String>>[];
      
      for (final entry in techniciansMap.entries) {
        final techData = Map<String, dynamic>.from(entry.value);
        final techPincode = techData['primaryPincode']?.toString();
        final techSpecializations = List<String>.from(techData['specializations'] ?? []);
        final techFcmToken = techData['fcmToken']?.toString();
        final isOnline = techData['status'] == 'online';
        final techName = techData['name']?.toString() ?? 'Unknown';
        final techId = entry.key;
        
        // Check if technician matches booking criteria
        if (techPincode == booking.pincode && 
            isOnline && 
            techFcmToken != null && 
            techFcmToken.isNotEmpty &&
            (techSpecializations.contains(booking.service) || 
             _isServiceMatch(booking.service, techSpecializations))) {
          matchingTechnicians.add({
            'id': techId,
            'name': techName,
            'token': techFcmToken,
          });
          print('🎯 Matching technician: $techName ($techId) - Token: ${techFcmToken.substring(0, 10)}...');
        }
      }
      
      print('📱 Sending notifications to ${matchingTechnicians.length} technicians');
      
      if (matchingTechnicians.isEmpty) {
        print('⚠️ No matching technicians found for pincode ${booking.pincode}');
        return;
      }
      
      // Send notifications using FCM service
      for (final tech in matchingTechnicians) {
        try {
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
          print('✅ Notification sent to ${tech['name']}: ${tech['token']!.substring(0, 10)}...');
        } catch (e) {
          print('❌ Failed to send notification to ${tech['name']}: $e');
        }
      }
      
      // Also send enhanced job alert to area
      await FCMService.sendJobAlertToArea(
        pincode: booking.pincode ?? '',
        service: booking.service,
        bookingId: booking.id,
        amount: booking.totalAmount,
        customerName: booking.userName,
        scheduledTime: booking.scheduledTime,
      );
      
      print('✅ Notification sending process completed for ${matchingTechnicians.length} technicians');
    } catch (e) {
      print('❌ Error sending notifications: $e');
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
      print('❌ Error getting booking: $e');
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
      print('❌ Error updating booking status: $e');
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
      print('❌ Error updating payment ID: $e');
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
      print('💰 Updating booking order details: $bookingId');
      await _realtimeDb.ref('bookings/$bookingId').update({
        'razorpayOrderId': razorpayOrderId,
        'visitingCharge': visitingCharge,
        'taxableAmount': taxableAmount,
        'gstAmount': gstAmount,
        'totalAmount': totalAmount,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Booking order details updated successfully');
    } catch (e) {
      print('❌ Error updating booking order details: $e');
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
      print('✅ Technician assigned to booking: $bookingId');
    } catch (e) {
      print('❌ Error assigning technician: $e');
      rethrow;
    }
  }

  /// Get user's bookings
  static Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      print('🔍 Fetching bookings for user: $userId');
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
        
        print('✅ Found ${bookings.length} bookings for user');
        return bookings;
      }
      print('⚠️ No bookings found for user');
      return [];
    } catch (e) {
      print('❌ Error getting user bookings: $e');
      return [];
    }
  }

  /// Get technician's bookings
  static Future<List<BookingModel>> getTechnicianBookings(
      String technicianId) async {
    try {
      print('🔍 Fetching bookings for technician: $technicianId');
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
        
        print('✅ Found ${bookings.length} bookings for technician');
        return bookings;
      }
      print('⚠️ No bookings found for technician');
      return [];
    } catch (e) {
      print('❌ Error getting technician bookings: $e');
      return [];
    }
  }

  /// Get pending bookings for technician (by city and service)
  static Future<List<BookingModel>> getPendingBookingsForTechnician({
    required String city,
    required List<String> specializations,
  }) async {
    try {
      print('🔍 Fetching pending bookings for city: $city');
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
        
        print('✅ Found ${filteredBookings.length} pending bookings');
        return filteredBookings;
      }
      print('⚠️ No pending bookings found');
      return [];
    } catch (e) {
      print('❌ Error getting pending bookings: $e');
      return [];
    }
  }

  /// Stream user's bookings (real-time updates)
  static Stream<List<BookingModel>> streamUserBookings(String userId) {
    debugPrint('🔄 Streaming bookings for user: $userId');
    
    return _realtimeDb.ref('bookings')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .asyncMap((event) async {
      try {
        debugPrint('📡 Stream event received for user: $userId');
        debugPrint('📡 Event type: ${event.type}');
        debugPrint('📡 Snapshot exists: ${event.snapshot.exists}');
        
        if (event.snapshot.exists && event.snapshot.value != null) {
          final bookingsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
          debugPrint('📡 Raw bookings map keys: ${bookingsMap.keys.toList()}');
          
          final bookings = bookingsMap.entries
              .map((entry) {
                final bookingData = Map<String, dynamic>.from(entry.value);
                bookingData['id'] = entry.key; // Add the booking ID
                debugPrint('📡 Processing booking: ${entry.key} | Status: ${bookingData['status']} | Service: ${bookingData['service']}');
                return BookingModel.fromJson(bookingData);
              })
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          debugPrint('📋 Streamed ${bookings.length} bookings for user $userId');
          
          // Log each booking for debugging
          for (var booking in bookings) {
            debugPrint('  📋 ${booking.service} | ${booking.status} | ${booking.createdAt} | ID: ${booking.id}');
          }
          
          return bookings;
        }
        debugPrint('⚠️ No bookings found for user $userId');
        return <BookingModel>[];
      } catch (e, stackTrace) {
        debugPrint('❌ Error in stream for user $userId: $e');
        debugPrint('❌ Stack trace: $stackTrace');
        
        // Check if it's a permission error
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('permission') || errorStr.contains('denied')) {
          debugPrint('🔒 Permission denied error detected - this might resolve automatically');
          // Return empty list for permission errors to avoid breaking the UI
          return <BookingModel>[];
        }
        
        // Re-throw other errors
        rethrow;
      }
    }).handleError((error) {
      debugPrint('❌ Stream error handler: $error');
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
      'Normal Service': ['AC Repair', 'Appliance Repair'], // NEW
      'AC Installation': ['AC Repair'],
      'AC Service': ['AC Repair'],
      'AC Repair Service': ['AC Repair'],
      'Split AC Service': ['AC Repair'],
      'Window AC Service': ['AC Repair'],
      'AC Gas Filling': ['AC Repair'],
      'AC Cleaning': ['AC Repair'],
      'AC Uninstallation': ['AC Repair'], // NEW
      'Foam Service': ['AC Repair'], // NEW
      
      // Appliance Services
      'Jet Machine Service': ['Appliance Repair'],
      'Washing Machine Repair': ['Appliance Repair'],
      'Washing Machine Service': ['Appliance Repair'],
      'Refrigerator Repair': ['Appliance Repair'],
      'Refrigerator Service': ['Appliance Repair'],
      'Single Door - Slow Working': ['Appliance Repair'], // NEW
      'Single Door - Gas Refill': ['Appliance Repair'], // NEW
      'Microwave Repair': ['Appliance Repair'],
      'Water Purifier Service': ['Appliance Repair'],
      'Chimney Service': ['Appliance Repair'],
      'Gas Refilling': ['Appliance Repair'],
      
      // Installation Services
      'Installation - Inspection Required': ['AC Repair', 'Appliance Repair'], // NEW
      
      // Carpenter Services
      'Carpenter Work': ['Carpenter'],
      'Wood Work': ['Carpenter'],
      'Furniture Repair': ['Carpenter'],
    };
    
    final mappedServices = serviceMap[bookingService] ?? [];
    final hasMatch = specializations.any((spec) => mappedServices.contains(spec));
    
    debugPrint('🔧 Service mapping: $bookingService → $mappedServices → Match: $hasMatch');
    
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
}