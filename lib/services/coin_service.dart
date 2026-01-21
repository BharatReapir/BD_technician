// services/coin_service.dart
import 'package:firebase_database/firebase_database.dart';
import '../models/coin_model.dart';

class CoinService {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ========== COIN BALANCE OPERATIONS ==========

  /// Get coin balance for user
  static Future<CoinBalance> getCoinBalance(String userId) async {
    try {
      print('🪙 Fetching coin balance for user: $userId');
      final snapshot = await _db.ref('coins/$userId/balance').get();
      
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        // Calculate expiring coins
        final expiringData = await _getExpiringCoins(userId);
        data['expiringCoins'] = expiringData['coins'];
        data['daysUntilExpiry'] = expiringData['days'];
        
        print('✅ Balance fetched: ${data['totalCoins']} coins');
        return CoinBalance.fromJson(data);
      }
      
      // Create new balance if doesn't exist
      print('📝 Creating new coin balance');
      final newBalance = CoinBalance(
        totalCoins: 0,
        discountValue: 0.0,
        lastUpdated: DateTime.now(),
      );
      await _db.ref('coins/$userId/balance').set(newBalance.toJson());
      return newBalance;
    } catch (e) {
      print('❌ Error fetching coin balance: $e');
      rethrow;
    }
  }

  /// Get expiring coins info
  static Future<Map<String, dynamic>> _getExpiringCoins(String userId) async {
    try {
      final now = DateTime.now();
      final sevenDaysLater = now.add(const Duration(days: 7));
      
      final snapshot = await _db.ref('coins/$userId/transactions').get();
      if (!snapshot.exists || snapshot.value == null) {
        return {'coins': 0, 'days': 0};
      }

      final transactionsMap = Map<String, dynamic>.from(snapshot.value as Map);
      int expiringCoins = 0;
      
      for (var entry in transactionsMap.entries) {
        final txn = Map<String, dynamic>.from(entry.value);
        if (txn['isExpired'] == false && 
            txn['isCredit'] == true && 
            txn['expiryDate'] != null) {
          final expiryDate = DateTime.parse(txn['expiryDate']);
          if (expiryDate.isBefore(sevenDaysLater) && expiryDate.isAfter(now)) {
            expiringCoins += (txn['coins'] as int? ?? 0);
          }
        }
      }
      
      return {'coins': expiringCoins, 'days': 7};
    } catch (e) {
      print('❌ Error getting expiring coins: $e');
      return {'coins': 0, 'days': 0};
    }
  }

  // ========== TRANSACTION OPERATIONS ==========

  /// Get transaction history
  static Future<List<CoinTransaction>> getCoinHistory(String userId, {required int page, required int limit}) async {
    try {
      print('📜 Fetching coin history for user: $userId');
      final snapshot = await _db.ref('coins/$userId/transactions')
          .orderByChild('timestamp')
          .get();
      
      if (snapshot.exists && snapshot.value != null) {
        final transactionsMap = Map<String, dynamic>.from(snapshot.value as Map);
        final transactions = transactionsMap.entries
            .map((entry) {
              final data = Map<String, dynamic>.from(entry.value);
              data['id'] = entry.key;
              return CoinTransaction.fromJson(data);
            })
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        print('✅ Found ${transactions.length} transactions');
        return transactions;
      }
      
      print('⚠️ No transactions found');
      return [];
    } catch (e) {
      print('❌ Error getting coin history: $e');
      return [];
    }
  }

  /// Stream coin balance (real-time updates)
  static Stream<CoinBalance> streamCoinBalance(String userId) {
    return _db.ref('coins/$userId/balance').onValue.asyncMap((event) async {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        // Get expiring coins
        final expiringData = await _getExpiringCoins(userId);
        data['expiringCoins'] = expiringData['coins'];
        data['daysUntilExpiry'] = expiringData['days'];
        
        return CoinBalance.fromJson(data);
      }
      return CoinBalance(totalCoins: 0, discountValue: 0.0);
    });
  }

  /// Stream transaction history (real-time updates)
  static Stream<List<CoinTransaction>> streamCoinHistory(String userId) {
    return _db.ref('coins/$userId/transactions')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final transactionsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        return transactionsMap.entries
            .map((entry) {
              final data = Map<String, dynamic>.from(entry.value);
              data['id'] = entry.key;
              return CoinTransaction.fromJson(data);
            })
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      return <CoinTransaction>[];
    });
  }

  // ========== COIN CREDIT OPERATIONS ==========

  /// Credit coins after booking completion
  static Future<bool> creditCoins({
    required String userId,
    required String bookingId,
    required int coins,
    required int bookingNumber,
  }) async {
    try {
      print('💰 Crediting $coins coins to user: $userId');
      
      // Check if already credited for this booking
      final existingSnapshot = await _db.ref('coins/$userId/transactions')
          .orderByChild('bookingId')
          .equalTo(bookingId)
          .get();
      
      if (existingSnapshot.exists) {
        print('⚠️ Coins already credited for booking: $bookingId');
        return false;
      }
      
      // Set expiry date (180 days from now)
      final expiryDate = DateTime.now().add(const Duration(days: 180));
      
      // Create transaction
      final transactionRef = _db.ref('coins/$userId/transactions').push();
      final transaction = CoinTransaction(
        id: transactionRef.key!,
        type: 'earned',
        coins: coins,
        value: coins / 100.0,
        description: bookingNumber <= 5
            ? 'Welcome bonus - ${_getOrdinal(bookingNumber)} booking'
            : 'Booking completed - earned coins',
        timestamp: DateTime.now(),
        bookingId: bookingId,
        isCredit: true,
        expiryDate: expiryDate,
        isExpired: false,
      );
      
      await transactionRef.set(transaction.toJson());
      
      // Update balance
      final balanceSnapshot = await _db.ref('coins/$userId/balance').get();
      final currentCoins = balanceSnapshot.exists 
          ? (balanceSnapshot.value as Map)['totalCoins'] ?? 0 
          : 0;
      final newBalance = currentCoins + coins;
      
      await _db.ref('coins/$userId/balance').set({
        'totalCoins': newBalance,
        'discountValue': newBalance / 100.0,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      
      print('✅ Credited $coins coins. New balance: $newBalance');
      return true;
    } catch (e) {
      print('❌ Error crediting coins: $e');
      rethrow;
    }
  }

  // ========== COIN REDEMPTION OPERATIONS ==========

  /// Redeem coins for discount (FIFO)
  static Future<bool> redeemCoins({
    required String userId,
    required String bookingId,
    required int coinsToRedeem,
  }) async {
    try {
      print('🎯 Redeeming $coinsToRedeem coins for user: $userId');
      
      // Get current balance
      final balance = await getCoinBalance(userId);
      if (coinsToRedeem > balance.totalCoins) {
        throw Exception('Insufficient coins. Available: ${balance.totalCoins}');
      }
      
      // Get all non-expired credit transactions (FIFO)
      final snapshot = await _db.ref('coins/$userId/transactions').get();
      if (!snapshot.exists) {
        throw Exception('No coin transactions found');
      }
      
      final transactionsMap = Map<String, dynamic>.from(snapshot.value as Map);
      final creditTransactions = transactionsMap.entries
          .map((entry) {
            final data = Map<String, dynamic>.from(entry.value);
            data['id'] = entry.key;
            return data;
          })
          .where((txn) => 
              txn['isCredit'] == true && 
              txn['isExpired'] == false &&
              (txn['coins'] as int) > 0)
          .toList()
        ..sort((a, b) => DateTime.parse(a['timestamp'])
            .compareTo(DateTime.parse(b['timestamp'])));
      
      // Deduct coins using FIFO
      int remaining = coinsToRedeem;
      for (var txn in creditTransactions) {
        if (remaining <= 0) break;
        
        final available = txn['coins'] as int;
        final toDeduct = remaining > available ? available : remaining;
        
        // Update transaction
        await _db.ref('coins/$userId/transactions/${txn['id']}').update({
          'coins': available - toDeduct,
        });
        
        remaining -= toDeduct;
      }
      
      // Create redemption transaction
      final redemptionRef = _db.ref('coins/$userId/transactions').push();
      final redemption = CoinTransaction(
        id: redemptionRef.key!,
        type: 'redeemed',
        coins: coinsToRedeem,
        value: coinsToRedeem / 100.0,
        description: 'Redeemed on booking',
        timestamp: DateTime.now(),
        bookingId: bookingId,
        isCredit: false,
      );
      
      await redemptionRef.set(redemption.toJson());
      
      // Update balance
      final newBalance = balance.totalCoins - coinsToRedeem;
      await _db.ref('coins/$userId/balance').set({
        'totalCoins': newBalance,
        'discountValue': newBalance / 100.0,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      
      print('✅ Redeemed $coinsToRedeem coins. New balance: $newBalance');
      return true;
    } catch (e) {
      print('❌ Error redeeming coins: $e');
      rethrow;
    }
  }

  // ========== COIN REVERSAL OPERATIONS ==========

  /// Reverse coins when booking cancelled before visit
  static Future<bool> reverseCoins({
    required String userId,
    required String bookingId,
  }) async {
    try {
      print('🔄 Reversing coins for booking: $bookingId');
      
      // Find the earned transaction for this booking
      final snapshot = await _db.ref('coins/$userId/transactions')
          .orderByChild('bookingId')
          .equalTo(bookingId)
          .get();
      
      if (!snapshot.exists) {
        print('⚠️ No coins found for booking: $bookingId');
        return false;
      }
      
      final transactionsMap = Map<String, dynamic>.from(snapshot.value as Map);
      final earnedTxn = transactionsMap.entries
          .firstWhere((entry) => 
              (entry.value as Map)['type'] == 'earned' &&
              (entry.value as Map)['isCredit'] == true);
      
      final coins = (earnedTxn.value as Map)['coins'] as int;
      
      // Mark transaction as expired
      await _db.ref('coins/$userId/transactions/${earnedTxn.key}').update({
        'isExpired': true,
        'coins': 0,
      });
      
      // Create reversal transaction
      final reversalRef = _db.ref('coins/$userId/transactions').push();
      final reversal = CoinTransaction(
        id: reversalRef.key!,
        type: 'reversed',
        coins: coins,
        value: coins / 100.0,
        description: 'Booking cancelled - coins reversed',
        timestamp: DateTime.now(),
        bookingId: bookingId,
        isCredit: false,
      );
      
      await reversalRef.set(reversal.toJson());
      
      // Update balance
      final balance = await getCoinBalance(userId);
      final newBalance = balance.totalCoins - coins;
      await _db.ref('coins/$userId/balance').set({
        'totalCoins': newBalance,
        'discountValue': newBalance / 100.0,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      
      print('✅ Reversed $coins coins. New balance: $newBalance');
      return true;
    } catch (e) {
      print('❌ Error reversing coins: $e');
      rethrow;
    }
  }

  // ========== HELPER FUNCTIONS ==========

  static String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) return '${number}th';
    switch (number % 10) {
      case 1: return '${number}st';
      case 2: return '${number}nd';
      case 3: return '${number}rd';
      default: return '${number}th';
    }
  }

  /// Calculate billing with coins
  static CoinRedemption calculateBilling({
    required int coinsToRedeem,
    required double serviceCharges,
    required double visitingCharges,
  }) {
    return CoinRedemption.calculate(
      coinsToRedeem: coinsToRedeem,
      serviceCharges: serviceCharges,
      visitingCharges: visitingCharges,
    );
  }

  /// Validate coin redemption
  static Future<bool> validateRedemption({
    required String userId,
    required int coinsToRedeem,
  }) async {
    try {
      final balance = await getCoinBalance(userId);
      return coinsToRedeem > 0 && coinsToRedeem <= balance.totalCoins;
    } catch (e) {
      return false;
    }
  }
}