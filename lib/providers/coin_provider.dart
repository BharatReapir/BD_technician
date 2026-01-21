// providers/coin_provider.dart
import 'package:flutter/material.dart';
import '../models/coin_model.dart';
import '../services/coin_service.dart';

class CoinProvider extends ChangeNotifier {
  final String userId; // Add userId
  
  CoinProvider(this.userId); // Update constructor

  // State variables
  CoinBalance? _coinBalance;
  List<CoinTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // Getters
  CoinBalance? get coinBalance => _coinBalance;
  List<CoinTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // Load coin balance
  Future<void> loadCoinBalance() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _coinBalance = await CoinService.getCoinBalance(userId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load transaction history
  Future<void> loadTransactions({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _transactions = [];
      _hasMore = true;
    }

    if (!_hasMore) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final newTransactions = await CoinService.getCoinHistory(
        userId,
        page: _currentPage,
        limit: 20,
      );

      if (newTransactions.isEmpty) {
        _hasMore = false;
      } else {
        _transactions.addAll(newTransactions);
        _currentPage++;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadCoinBalance(),
      loadTransactions(refresh: true),
    ]);
  }

  // Calculate billing with coins
  CoinRedemption? calculateBilling({
    required int coinsToRedeem,
    required double serviceCharges,
    required double visitingCharges,
  }) {
    if (_coinBalance == null || coinsToRedeem > _coinBalance!.totalCoins) {
      return null;
    }

    return CoinService.calculateBilling(
      coinsToRedeem: coinsToRedeem,
      serviceCharges: serviceCharges,
      visitingCharges: visitingCharges,
    );
  }

  // Validate redemption
  bool canRedeem(int coins) {
    if (_coinBalance == null) return false;
    return coins > 0 && coins <= _coinBalance!.totalCoins;
  }

  // Redeem coins
  Future<bool> redeemCoins({
    required String bookingId,
    required int coinsToRedeem,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await CoinService.redeemCoins(
        userId: userId,
        bookingId: bookingId,
        coinsToRedeem: coinsToRedeem,
      );

      if (success) {
        await refreshAll();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }



  // Credit coins
  Future<bool> creditCoins({
    required String bookingId,
    required int coins,
    required int bookingNumber,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await CoinService.creditCoins(
        userId: userId,
        bookingId: bookingId,
        coins: coins,
        bookingNumber: bookingNumber,
      );

      if (success) {
        await refreshAll();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reverse coins
  Future<bool> reverseCoins({required String bookingId}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await CoinService.reverseCoins(
        userId: userId,
        bookingId: bookingId,
      );

      if (success) {
        await refreshAll();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}