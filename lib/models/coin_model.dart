// models/coin_model.dart
class CoinBalance {
  final int totalCoins;
  final double discountValue;
  final int expiringCoins;
  final int daysUntilExpiry;
  final DateTime? lastUpdated;

  CoinBalance({
    required this.totalCoins,
    required this.discountValue,
    this.expiringCoins = 0,
    this.daysUntilExpiry = 0,
    this.lastUpdated,
  });

  factory CoinBalance.fromJson(Map<String, dynamic> json) {
    return CoinBalance(
      totalCoins: json['totalCoins'] ?? 0,
      discountValue: (json['totalCoins'] ?? 0) / 100.0,
      expiringCoins: json['expiringCoins'] ?? 0,
      daysUntilExpiry: json['daysUntilExpiry'] ?? 0,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCoins': totalCoins,
      'discountValue': discountValue,
      'expiringCoins': expiringCoins,
      'daysUntilExpiry': daysUntilExpiry,
      'lastUpdated': lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}

class CoinTransaction {
  final String id;
  final String type; // 'earned', 'redeemed', 'expired', 'reversed'
  final int coins;
  final double value;
  final String description;
  final DateTime timestamp;
  final String? bookingId;
  final bool isCredit;
  final DateTime? expiryDate;
  final bool isExpired;

  CoinTransaction({
    required this.id,
    required this.type,
    required this.coins,
    required this.value,
    required this.description,
    required this.timestamp,
    this.bookingId,
    required this.isCredit,
    this.expiryDate,
    this.isExpired = false,
  });

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: json['id'] ?? '',
      type: json['type'] ?? 'earned',
      coins: json['coins'] ?? 0,
      value: (json['coins'] ?? 0) / 100.0,
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      bookingId: json['bookingId'],
      isCredit: json['isCredit'] ?? false,
      expiryDate: json['expiryDate'] != null 
          ? DateTime.parse(json['expiryDate']) 
          : null,
      isExpired: json['isExpired'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'coins': coins,
      'value': value,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'bookingId': bookingId,
      'isCredit': isCredit,
      'expiryDate': expiryDate?.toIso8601String(),
      'isExpired': isExpired,
    };
  }
}

class WelcomeCoinRule {
  static const Map<int, int> welcomeCoins = {
    1: 1000, // ₹10
    2: 1500, // ₹15
    3: 2000, // ₹20
    4: 2500, // ₹25
    5: 3000, // ₹30
  };

  static int getWelcomeCoins(int bookingNumber) {
    return welcomeCoins[bookingNumber] ?? 0;
  }

  static bool isWelcomeBooking(int bookingNumber) {
    return bookingNumber >= 1 && bookingNumber <= 5;
  }
}

class RegularCoinRule {
  static const List<int> allowedSlabs = [10, 20, 30, 40, 50, 60, 70, 80, 90];
  static const int maxCoinsPerBooking = 90;

  static bool isValidCoinAmount(int coins) {
    return allowedSlabs.contains(coins) && coins <= maxCoinsPerBooking;
  }
}

class CoinRedemption {
  final int coinsToRedeem;
  final double discountAmount;
  final double serviceCharges;
  final double visitingCharges;
  final double taxableValue;
  final double gstAmount;
  final double totalPayable;

  CoinRedemption({
    required this.coinsToRedeem,
    required this.discountAmount,
    required this.serviceCharges,
    required this.visitingCharges,
    required this.taxableValue,
    required this.gstAmount,
    required this.totalPayable,
  });

  factory CoinRedemption.calculate({
    required int coinsToRedeem,
    required double serviceCharges,
    required double visitingCharges,
    double gstRate = 0.18,
  }) {
    // Coin discount = coins / 100
    final discountAmount = coinsToRedeem / 100.0;
    
    // Total before discount
    final totalBeforeDiscount = serviceCharges + visitingCharges;
    
    // Apply coin discount
    final afterDiscount = totalBeforeDiscount - discountAmount;
    
    // This is the taxable value
    final taxableValue = afterDiscount;
    
    // Calculate GST on taxable value
    final gstAmount = taxableValue * gstRate;
    
    // Total payable
    final totalPayable = taxableValue + gstAmount;

    return CoinRedemption(
      coinsToRedeem: coinsToRedeem,
      discountAmount: discountAmount,
      serviceCharges: serviceCharges,
      visitingCharges: visitingCharges,
      taxableValue: taxableValue,
      gstAmount: gstAmount,
      totalPayable: totalPayable,
    );
  }
}