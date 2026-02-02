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
    );
  }
}

class PricingCalculator {
  // Fixed commission per booking (199-399)
  static const double FIXED_COMMISSION = 199.0;
  
  // Visiting charges (area-wise)
  static const double VISITING_CHARGE_STANDARD = 299.0;
  static const double VISITING_CHARGE_PREMIUM = 399.0;
  
  // GST rate
  static const double GST_RATE = 0.18; // 18%
  static const double CGST_RATE = 0.09; // 9%
  static const double SGST_RATE = 0.09; // 9%

  /// Calculate visiting charge based on area/pincode
  static double getVisitingCharge(String pincode) {
    // Premium areas (can be configured based on pincode)
    final premiumAreas = ['110001', '400001', '560001', '600001']; // Example premium pincodes
    
    if (premiumAreas.contains(pincode)) {
      return VISITING_CHARGE_PREMIUM;
    }
    return VISITING_CHARGE_STANDARD;
  }

  /// Calculate complete billing breakdown
  static BillingModel calculateBilling({
    required String customerName,
    required String serviceAddress,
    required String serviceName,
    required double servicePrice,
    required String pincode,
    required double coinDiscount,
    required String technicianName,
    required String bookingId,
  }) {
    // Get visiting charge based on area
    final visitingCharge = getVisitingCharge(pincode);
    
    // Calculate final service charges (service + visiting charge)
    final finalServiceCharges = servicePrice + visitingCharge;
    
    // Apply coin discount
    final netTaxableValue = finalServiceCharges - coinDiscount;
    
    // Calculate GST
    final cgstAmount = netTaxableValue * CGST_RATE;
    final sgstAmount = netTaxableValue * SGST_RATE;
    final totalGst = cgstAmount + sgstAmount;
    
    // Calculate gross service value
    final grossServiceValue = netTaxableValue + totalGst;
    
    // Visiting charge is already paid at booking time, so it's adjusted
    final visitingChargePaid = visitingCharge;
    
    // Balance payable (gross value minus visiting charge already paid)
    final balancePayable = grossServiceValue - visitingChargePaid;
    
    // Generate invoice number
    final invoiceNumber = _generateInvoiceNumber();
    
    return BillingModel(
      invoiceNumber: invoiceNumber,
      invoiceDate: DateTime.now(),
      customerName: customerName,
      serviceAddress: serviceAddress,
      serviceName: serviceName,
      servicePrice: finalServiceCharges,
      visitingCharge: visitingCharge,
      coinDiscount: coinDiscount,
      netTaxableValue: netTaxableValue,
      cgstAmount: cgstAmount,
      sgstAmount: sgstAmount,
      totalGst: totalGst,
      grossServiceValue: grossServiceValue,
      visitingChargePaid: visitingChargePaid,
      balancePayable: balancePayable,
      technicianName: technicianName,
      bookingId: bookingId,
    );
  }

  /// Calculate technician payout
  static double calculateTechnicianPayout(double servicePrice, double visitingCharge) {
    // Technician gets: Service Price (excluding GST and visiting charge) - Fixed Commission
    // Visiting charge is retained by company
    final technicianEarnings = servicePrice - FIXED_COMMISSION;
    return technicianEarnings > 0 ? technicianEarnings : 0;
  }

  /// Calculate booking total at time of booking (for customer payment)
  static Map<String, double> calculateBookingTotal({
    required double servicePrice,
    required String pincode,
    required double coinDiscount,
  }) {
    final visitingCharge = getVisitingCharge(pincode);
    final taxableValue = servicePrice + visitingCharge - coinDiscount;
    final gstAmount = taxableValue * GST_RATE;
    final totalPayable = taxableValue + gstAmount;
    
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