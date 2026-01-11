import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_transaction_model.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const double BOOKING_DEDUCTION = 200.0;

  Future<bool> deductBookingAmount(String technicianId, String jobId) async {
    try {
      DocumentReference techRef =
          _firestore.collection('technicians').doc(technicianId);

      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot techSnapshot = await transaction.get(techRef);

        if (!techSnapshot.exists) {
          throw Exception('Technician not found');
        }

        double currentBalance =
            (techSnapshot.data() as Map<String, dynamic>)['walletBalance'] ??
                0.0;

        if (currentBalance < BOOKING_DEDUCTION) {
          throw Exception('Insufficient balance');
        }

        double newBalance = currentBalance - BOOKING_DEDUCTION;

        transaction.update(techRef, {
          'walletBalance': newBalance,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        DocumentReference transactionRef =
            _firestore.collection('wallet_transactions').doc();

        WalletTransaction walletTransaction = WalletTransaction(
          id: transactionRef.id,
          technicianId: technicianId,
          amount: BOOKING_DEDUCTION,
          type: 'debit',
          description: 'Booking acceptance charge',
          balanceAfter: newBalance,
          timestamp: DateTime.now(),
          jobId: jobId,
        );

        transaction.set(transactionRef, walletTransaction.toJson());

        return true;
      });
    } catch (e) {
      print('Error deducting amount: $e');
      return false;
    }
  }

  Future<bool> rechargeWallet(String technicianId, double amount) async {
    try {
      DocumentReference techRef =
          _firestore.collection('technicians').doc(technicianId);

      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot techSnapshot = await transaction.get(techRef);

        if (!techSnapshot.exists) {
          throw Exception('Technician not found');
        }

        double currentBalance =
            (techSnapshot.data() as Map<String, dynamic>)['walletBalance'] ??
                0.0;
        double newBalance = currentBalance + amount;

        transaction.update(techRef, {
          'walletBalance': newBalance,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        DocumentReference transactionRef =
            _firestore.collection('wallet_transactions').doc();

        WalletTransaction walletTransaction = WalletTransaction(
          id: transactionRef.id,
          technicianId: technicianId,
          amount: amount,
          type: 'credit',
          description: 'Wallet recharge',
          balanceAfter: newBalance,
          timestamp: DateTime.now(),
        );

        transaction.set(transactionRef, walletTransaction.toJson());

        return true;
      });
    } catch (e) {
      print('Error recharging wallet: $e');
      return false;
    }
  }

  Stream<List<WalletTransaction>> getTransactionHistory(String technicianId) {
    return _firestore
        .collection('wallet_transactions')
        .where('technicianId', isEqualTo: technicianId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              WalletTransaction.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<double> getWalletBalance(String technicianId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('technicians').doc(technicianId).get();

      if (doc.exists) {
        return ((doc.data() as Map<String, dynamic>)['walletBalance'] ?? 0.0)
            .toDouble();
      }
      return 0.0;
    } catch (e) {
      print('Error getting wallet balance: $e');
      return 0.0;
    }
  }
}