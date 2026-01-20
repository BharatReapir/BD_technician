import 'package:firebase_database/firebase_database.dart';
import '../models/wallet_transaction_model.dart';

class WalletService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Get wallet balance
  Future<double> getWalletBalance(String technicianId) async {
    try {
      final snapshot = await _database
          .child('technicians')
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
    return _database
        .child('wallet_transactions')
        .orderByChild('technicianId')
        .equalTo(technicianId)
        .onValue
        .map((event) {
      final List<WalletTransaction> transactions = [];
      
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          if (value is Map) {
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
      final balanceSnapshot = await _database
          .child('technicians')
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
      await _database
          .child('technicians')
          .child(technicianId)
          .update({
        'walletBalance': newBalance,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Add transaction
      await _database.child('wallet_transactions').push().set({
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
      final balanceSnapshot = await _database
          .child('technicians')
          .child(technicianId)
          .child('walletBalance')
          .get();

      final currentBalance = balanceSnapshot.exists 
          ? (balanceSnapshot.value as num).toDouble() 
          : 0.0;

      final newBalance = currentBalance + amount;

      // Update balance
      await _database
          .child('technicians')
          .child(technicianId)
          .update({
        'walletBalance': newBalance,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Add transaction
      await _database.child('wallet_transactions').push().set({
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