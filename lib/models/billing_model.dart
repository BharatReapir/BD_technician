class BillingModel {
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String customerName;
  final String serviceAddress;
  final String serviceName;
  final double servicePrice;
  final double visitingCharge;
  final double coinDiscount;
  final double netTaxableValue;
  final double cgstAmount;
  final double sgstAmount;
  final double totalGst;
  final double grossServiceValue;
  final double visitingChargePaid;
  final double balancePayable;
  final String technicianName;
  final String bookingId;
  final String? paymentMethod;

  BillingModel({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customerName,
    required this.serviceAddress,
    required this.serviceName,
    required this.servicePrice,
    required this.visitingCharge,
    required this.coinDiscount,
    required this.netTaxableValue,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.totalGst,
    required this.grossServiceValue,
    required this.visitingChargePaid,
    required this.balancePayable,
    required this.technicianName,
    required this.bookingId,
    this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate.toIso8601String(),
      'customerName': customerName,
      'serviceAddress': serviceAddress,
      'serviceName': serviceName,
      'servicePrice': servicePrice,
      'visitingCharge': visitingCharge,
      'coinDiscount': coinDiscount,
      'netTaxableValue': netTaxableValue,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'totalGst': totalGst,
      'grossServiceValue': grossServiceValue,
      'visitingChargePaid': visitingChargePaid,
      'balancePayable': balancePayable,
      'technicianName': technicianName,
      'bookingId': bookingId,
      'paymentMethod': paymentMethod,
    };
  }

  factory BillingModel.fromJson(Map<String, dynamic> json) {
    return BillingModel(
      invoiceNumber: json['invoiceNumber'] ?? '',
      invoiceDate: DateTime.parse(json['invoiceDate']),
      customerName: json['customerName'] ?? '',
      serviceAddress: json['serviceAddress'] ?? '',
      serviceName: json['serviceName'] ?? '',
      servicePrice: (json['servicePrice'] ?? 0).toDouble(),
      visitingCharge: (json['visitingCharge'] ?? 0).toDouble(),
      coinDiscount: (json['coinDiscount'] ?? 0).toDouble(),
      netTaxableValue: (json['netTaxableValue'] ?? 0).toDouble(),
      cgstAmount: (json['cgstAmount'] ?? 0).toDouble(),
      sgstAmount: (json['sgstAmount'] ?? 0).toDouble(),
      totalGst: (json['totalGst'] ?? 0).toDouble(),
      grossServiceValue: (json['grossServiceValue'] ?? 0).toDouble(),
      visitingChargePaid: (json['visitingChargePaid'] ?? 0).toDouble(),
      balancePayable: (json['balancePayable'] ?? 0).toDouble(),
      technicianName: json['technicianName'] ?? '',
      bookingId: json['bookingId'] ?? '',
      paymentMethod: json['paymentMethod']?.toString(),
    );
  }

  BillingModel copyWith({
    String? invoiceNumber,
    DateTime? invoiceDate,
    String? customerName,
    String? serviceAddress,
    String? serviceName,
    double? servicePrice,
    double? visitingCharge,
    double? coinDiscount,
    double? netTaxableValue,
    double? cgstAmount,
    double? sgstAmount,
    double? totalGst,
    double? grossServiceValue,
    double? visitingChargePaid,
    double? balancePayable,
    String? technicianName,
    String? bookingId,
    String? paymentMethod,
  }) {
    return BillingModel(
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      customerName: customerName ?? this.customerName,
      serviceAddress: serviceAddress ?? this.serviceAddress,
      serviceName: serviceName ?? this.serviceName,
      servicePrice: servicePrice ?? this.servicePrice,
      visitingCharge: visitingCharge ?? this.visitingCharge,
      coinDiscount: coinDiscount ?? this.coinDiscount,
      netTaxableValue: netTaxableValue ?? this.netTaxableValue,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      totalGst: totalGst ?? this.totalGst,
      grossServiceValue: grossServiceValue ?? this.grossServiceValue,
      visitingChargePaid: visitingChargePaid ?? this.visitingChargePaid,
      balancePayable: balancePayable ?? this.balancePayable,
      technicianName: technicianName ?? this.technicianName,
      bookingId: bookingId ?? this.bookingId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class PricingCalculator {
  // Commission slab values
  static const double COMMISSION_LOW = 199.0;
  static const double COMMISSION_HIGH = 399.0;
  // For backward compat: minimum commission (used in wallet check)
  static const double FIXED_COMMISSION = 199.0;
  
  // Commission threshold: Service Amount > 1000 => 399, else 199
  static const double COMMISSION_THRESHOLD = 1000.0;
  
  // Visiting charges (area-wise)
  static const double VISITING_CHARGE_STANDARD = 299.0;
  static const double VISITING_CHARGE_PREMIUM = 399.0;
  
  // GST rate
  static const double GST_RATE = 0.18; // 18%
  static const double CGST_RATE = 0.09; // 9%
  static const double SGST_RATE = 0.09; // 9%

  /// Get commission based on SERVICE AMOUNT only (Rule #4, #11)
  /// Commission sirf Service Amount par lagega, Final Bill nahi
  /// - ₹0 to ₹1000 Service Amount = ₹199 Commission
  /// - ₹1001 or above Service Amount = ₹399 Commission
  static double getCommission(double serviceAmount) {
    if (serviceAmount <= 0) return 0.0;
    return serviceAmount > COMMISSION_THRESHOLD
        ? COMMISSION_HIGH
        : COMMISSION_LOW;
  }

  /// Calculate visiting charge based on area/pincode
  static double getVisitingCharge(String pincode) {
    // Premium areas (can be configured based on pincode)
    final premiumAreas = ['110001', '400001', '560001', '600001'];
    
    if (premiumAreas.contains(pincode)) {
      return VISITING_CHARGE_PREMIUM;
    }
    return VISITING_CHARGE_STANDARD;
  }

  /// Calculate complete billing breakdown
  /// Rule: GST is on Service Amount only
  /// Rule: Final Customer Bill = Service Amount + GST
  /// Rule: Visiting charge is adjusted when service is completed
  static BillingModel calculateBilling({
    required String customerName,
    required String serviceAddress,
    required String serviceName,
    required double servicePrice,
    required String pincode,
    required double coinDiscount,
    required String technicianName,
    required String bookingId,
    bool isServiceComplete = true,
  }) {
    // Get visiting charge based on area
    final visitingCharge = getVisitingCharge(pincode);
    
    // Net taxable value = Service Amount - Coin Discount
    // Rule: GST is on service amount, not on visiting charge
    final netTaxableValue = servicePrice - coinDiscount;
    
    // Calculate GST on service amount only
    final cgstAmount = netTaxableValue * CGST_RATE;
    final sgstAmount = netTaxableValue * SGST_RATE;
    final totalGst = cgstAmount + sgstAmount;
    
    // Gross service value = Service Amount + GST
    final grossServiceValue = netTaxableValue + totalGst;
    
    // When service complete, visiting charge gets adjusted into final bill
    // Customer se main service amount hi charge hoga
    final visitingChargePaid = isServiceComplete ? visitingCharge : 0.0;
    
    // Balance payable = Gross value - Visiting Charge already paid
    final balancePayable = grossServiceValue - visitingChargePaid;
    
    // Generate invoice number
    final invoiceNumber = _generateInvoiceNumber();
    
    return BillingModel(
      invoiceNumber: invoiceNumber,
      invoiceDate: DateTime.now(),
      customerName: customerName,
      serviceAddress: serviceAddress,
      serviceName: serviceName,
      servicePrice: servicePrice,
      visitingCharge: visitingCharge,
      coinDiscount: coinDiscount,
      netTaxableValue: netTaxableValue,
      cgstAmount: cgstAmount,
      sgstAmount: sgstAmount,
      totalGst: totalGst,
      grossServiceValue: grossServiceValue,
      visitingChargePaid: visitingChargePaid,
      balancePayable: balancePayable < 0 ? 0 : balancePayable,
      technicianName: technicianName,
      bookingId: bookingId,
    );
  }

  /// Calculate technician payout from SERVICE AMOUNT
  /// Rule: Technician Net Earning = Final Bill - GST - Commission
  ///       = (Service Amount + GST) - GST - Commission
  ///       = Service Amount - Commission
  static double calculateTechnicianPayout(double serviceAmount) {
    final commission = getCommission(serviceAmount);
    final technicianEarnings = serviceAmount - commission;
    return technicianEarnings > 0 ? technicianEarnings : 0;
  }

  /// Calculate booking total at time of booking (for customer payment)
  /// GST is on service price only; visiting charge is separate
  static Map<String, double> calculateBookingTotal({
    required double servicePrice,
    required String pincode,
    required double coinDiscount,
  }) {
    final visitingCharge = getVisitingCharge(pincode);
    // GST only on service price (not visiting charge)
    final taxableValue = servicePrice - coinDiscount;
    final gstAmount = taxableValue * GST_RATE;
    // Total = Service + GST + Visiting Charge
    final totalPayable = taxableValue + gstAmount + visitingCharge;
    
    return {
      'servicePrice': servicePrice,
      'visitingCharge': visitingCharge,
      'coinDiscount': coinDiscount,
      'taxableValue': taxableValue,
      'gstAmount': gstAmount,
      'totalPayable': totalPayable,
    };
  }

  /// Generate unique invoice number
  static String _generateInvoiceNumber() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final timestamp = now.millisecondsSinceEpoch.toString().substring(8);
    
    return 'BDRP-INV-$year$month$day-$timestamp';
  }

  /// Check if technician can accept booking (wallet balance check)
  /// Minimum commission is ₹199 so wallet must have at least that
  static bool canAcceptBooking(double walletBalance) {
    return walletBalance >= FIXED_COMMISSION;
  }

  /// Calculate wallet recharge with GST
  static Map<String, double> calculateWalletRecharge(double rechargeAmount) {
    final gstAmount = rechargeAmount * GST_RATE;
    final totalAmount = rechargeAmount + gstAmount;
    
    return {
      'rechargeAmount': rechargeAmount,
      'gstAmount': gstAmount,
      'totalAmount': totalAmount,
    };
  }
}