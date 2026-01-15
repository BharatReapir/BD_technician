import 'package:firebase_database/firebase_database.dart';
import '../models/wallet_transaction_model.dart';

class WalletService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  static const double BOOKING_DEDUCTION = 200.0;

  /// ✅ FAKE: Deduct ₹200 when job accepted
  Future<bool> deductBookingAmount(String technicianId, String jobId) async {
    try {
      final techRef = _db.child('technicians').child(technicianId);

      final snapshot = await techRef.child('walletBalance').get();
      double currentBalance = 0.0;

      if (snapshot.exists) {
        currentBalance = (snapshot.value as num).toDouble();
      }

      if (currentBalance < BOOKING_DEDUCTION) {
        throw Exception('Insufficient balance');
      }

      final newBalance = currentBalance - BOOKING_DEDUCTION;

      print('🔥 NEW WALLET SERVICE CALLED');

      await techRef.update({
        'walletBalance': newBalance,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Save transaction
      await _db.child('wallet_transactions').push().set({
        'technicianId': technicianId,
        'amount': BOOKING_DEDUCTION,
        'type': 'debit',
        'description': 'Booking acceptance charge',
        'balanceAfter': newBalance,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'jobId': jobId,
      });

      return true;
    } catch (e) {
      print('❌ Error deducting amount: $e');
      return false;
    }
  }

  /// ✅ FAKE: Recharge wallet instantly
  Future<bool> rechargeWallet(String technicianId, double amount) async {
    try {
      final techRef = _db.child('technicians').child(technicianId);

      final snapshot = await techRef.child('walletBalance').get();
      double currentBalance = 0.0;

      if (snapshot.exists) {
        currentBalance = (snapshot.value as num).toDouble();
      }

      final newBalance = currentBalance + amount;

      await techRef.update({
        'walletBalance': newBalance,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Save transaction
      await _db.child('wallet_transactions').push().set({
        'technicianId': technicianId,
        'amount': amount,
        'type': 'credit',
        'description': 'Wallet recharge',
        'balanceAfter': newBalance,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      print('❌ Error recharging wallet: $e');
      return false;
    }
  }

  /// ✅ Transaction history
  Stream<List<WalletTransaction>> getTransactionHistory(String technicianId) {
    return _db
        .child('wallet_transactions')
        .orderByChild('technicianId')
        .equalTo(technicianId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return [];
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      return data.values
          .map((e) => WalletTransaction.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList()
        ..sort(
          (a, b) => b.timestamp.compareTo(a.timestamp),
        );
    });
  }

  /// ✅ Get wallet balance
  Future<double> getWalletBalance(String technicianId) async {
    try {
      final snapshot =
          await _db.child('technicians').child(technicianId).child('walletBalance').get();

      if (snapshot.exists) {
        return (snapshot.value as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('❌ Error getting wallet balance: $e');
      return 0.0;
    }
  }
}
