import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/wallet_transaction_model.dart';
import '../firebase_options.dart';

class WalletService {
  // ✅ Use singleton pattern like FirebaseService
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
        
        print('🔥 WalletService: Using Firebase Database URL: $databaseURL');
        
        // ✅ Use instanceFor with the app and databaseURL
        _realtimeDbInstance = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: databaseURL!,
        );
        
        // Enable persistence for offline support (not available on web)
        if (!kIsWeb) {
          _realtimeDbInstance!.setPersistenceEnabled(true);
        }
        
        _isInitialized = true;
        print('✅ WalletService: Firebase Database initialized successfully');
      } catch (e) {
        print('❌ WalletService: Error initializing Firebase Database: $e');
        rethrow;
      }
    }
    return _realtimeDbInstance!;
  }

  /// Get wallet balance
  Future<double> getWalletBalance(String technicianId) async {
    try {
      final snapshot = await _realtimeDb
          .ref('technicians')
          .child(technicianId)
          .child('walletBalance')
          .get();

      if (snapshot.exists) {
        return (snapshot.value as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('Error getting wallet balance: $e');
      return 0.0;
    }
  }

  /// Get transaction history
  Stream<List<WalletTransaction>> getTransactionHistory(String technicianId) {
    return _realtimeDb
        .ref('wallet_transactions')
        .onValue
        .map((event) {
      final List<WalletTransaction> transactions = [];
      
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          if (value is Map && value['technicianId'] == technicianId) {
            try {
              final transaction = WalletTransaction.fromJson(
                Map<String, dynamic>.from({...value as Map, 'id': key})
              );
              transactions.add(transaction);
            } catch (e) {
              print('Error parsing transaction $key: $e');
            }
          }
        });
      }
      
      // Sort by timestamp (newest first)
      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return transactions;
    });
  }

  /// Deduct amount from wallet (for booking acceptance)
  Future<bool> deductFromWallet({
    required String technicianId,
    required double amount,
    required String description,
    String? jobId,
  }) async {
    try {
      final balanceSnapshot = await _realtimeDb
          .ref('technicians')
          .child(technicianId)
          .child('walletBalance')
          .get();

      final currentBalance = balanceSnapshot.exists 
          ? (balanceSnapshot.value as num).toDouble() 
          : 0.0;

      if (currentBalance < amount) {
        return false; // Insufficient balance
      }

      final newBalance = currentBalance - amount;

      // Update balance
      await _realtimeDb
          .ref('technicians')
          .child(technicianId)
          .update({
        'walletBalance': newBalance,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Add transaction
      await _realtimeDb.ref('wallet_transactions').push().set({
        'technicianId': technicianId,
        'amount': amount,
        'type': 'debit',
        'description': description,
        'balanceAfter': newBalance,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'jobId': jobId,
      });

      return true;
    } catch (e) {
      print('Error deducting from wallet: $e');
      return false;
    }
  }

  /// Add amount to wallet (for recharge)
  Future<bool> addToWallet({
    required String technicianId,
    required double amount,
    required String description,
    String? paymentId,
    String? orderId,
  }) async {
    try {
      final balanceSnapshot = await _realtimeDb
          .ref('technicians')
          .child(technicianId)
          .child('walletBalance')
          .get();

      final currentBalance = balanceSnapshot.exists 
          ? (balanceSnapshot.value as num).toDouble() 
          : 0.0;

      final newBalance = currentBalance + amount;

      // Update balance
      await _realtimeDb
          .ref('technicians')
          .child(technicianId)
          .update({
        'walletBalance': newBalance,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Add transaction
      await _realtimeDb.ref('wallet_transactions').push().set({
        'technicianId': technicianId,
        'amount': amount,
        'type': 'credit',
        'description': description,
        'balanceAfter': newBalance,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'paymentId': paymentId,
        'orderId': orderId,
      });

      return true;
    } catch (e) {
      print('Error adding to wallet: $e');
      return false;
    }
  }

  Future<bool> deductBookingAmount(String uid, String jobId) async {
    return false;
  }
}