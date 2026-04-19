/// Commission & Billing Calculator for BharatApp Technician
///
/// RULES (from Final Billing, Commission & Visiting Charge Guide):
/// 1. Commission is ONLY on Service Amount (not Final Bill)
/// 2. GST is calculated on Service Amount: Final Bill = Service Amount + GST
/// 3. Commission Slab:
///    - Service Amount ₹0 to ₹1000 → Commission = ₹199
///    - Service Amount ₹1001 or above → Commission = ₹399
/// 4. Visiting Charge: No commission on visiting charge
/// 5. Technician Net Earning = Final Bill - GST - Commission
/// 6. When service is complete, visiting charge is adjusted into final bill
class CommissionCalculator {
  /// GST Rate (18%)
  static const double GST_RATE = 0.18;

  /// Commission slab values
  static const double COMMISSION_LOW = 199.0;
  static const double COMMISSION_HIGH = 399.0;

  /// Commission slab threshold (Service Amount)
  static const double COMMISSION_THRESHOLD = 1000.0;

  /// Get commission amount based on SERVICE AMOUNT only (not final bill)
  /// Rule: Commission sirf Service Amount par lagega
  static double getCommission(double serviceAmount) {
    if (serviceAmount <= 0) return 0.0;
    return serviceAmount > COMMISSION_THRESHOLD
        ? COMMISSION_HIGH
        : COMMISSION_LOW;
  }

  /// Calculate GST on Service Amount
  /// Rule: GST service amount par calculate hoga
  static double getGSTAmount(double serviceAmount) {
    return serviceAmount * GST_RATE;
  }

  /// Calculate Final Customer Bill
  /// Rule: Final Customer Bill = Service Amount + GST
  static double getFinalBill(double serviceAmount) {
    return serviceAmount + getGSTAmount(serviceAmount);
  }

  /// Calculate technician earnings
  /// Rule: Technician Net Earning = Final Bill - GST - Commission
  /// Which simplifies to: Service Amount - Commission
  static double getTechnicianEarnings(double serviceAmount) {
    final commission = getCommission(serviceAmount);
    final earnings = serviceAmount - commission;
    return earnings < 0 ? 0 : earnings;
  }

  /// Calculate complete earnings breakdown from SERVICE AMOUNT
  /// This is the main calculation method.
  ///
  /// [serviceAmount] - The actual service charge (kaam ka charge)
  /// [visitingCharge] - Visiting charge (if applicable, default 0)
  /// [isServiceComplete] - Whether service was completed (visiting charge gets adjusted)
  static Map<String, dynamic> calculateEarnings(
    double serviceAmount, {
    double visitingCharge = 0.0,
    bool isServiceComplete = true,
  }) {
    // Commission is ONLY based on Service Amount
    final commission = getCommission(serviceAmount);

    // GST on Service Amount
    final gstAmount = getGSTAmount(serviceAmount);

    // Final Bill = Service Amount + GST
    final finalBill = serviceAmount + gstAmount;

    // When service is complete, visiting charge is adjusted into final bill
    // Customer se main service amount hi charge hoga
    final adjustedVisitingCharge =
        isServiceComplete ? visitingCharge : 0.0;

    // Total amount customer pays (if visiting charge was already paid, it's subtracted)
    final customerPayable = finalBill - adjustedVisitingCharge;

    // Technician Net Earning = Final Bill - GST - Commission
    // = Service Amount - Commission
    final technicianEarnings = serviceAmount - commission;
    final safeTechnicianEarnings =
        technicianEarnings < 0 ? 0.0 : technicianEarnings;

    // Company gets: GST + Commission
    final companyEarnings = gstAmount + commission;

    return {
      'serviceAmount': serviceAmount,
      'visitingCharge': visitingCharge,
      'gstAmount': gstAmount,
      'finalBill': finalBill,
      'commission': commission,
      'technicianEarnings': safeTechnicianEarnings,
      'companyEarnings': companyEarnings,
      'customerPayable': customerPayable < 0 ? 0.0 : customerPayable,
      'adjustedVisitingCharge': adjustedVisitingCharge,
      'commissionSlab': serviceAmount > COMMISSION_THRESHOLD
          ? '₹1001+ → ₹399'
          : '₹0-₹1000 → ₹199',
    };
  }

  /// Format commission display text
  static String formatCommissionText(double serviceAmount) {
    final commission = getCommission(serviceAmount);
    return '-₹${commission.toStringAsFixed(0)}';
  }

  /// Format earnings display text
  static String formatEarningsText(double serviceAmount) {
    final earnings = getTechnicianEarnings(serviceAmount);
    return '₹${earnings.toStringAsFixed(0)}';
  }

  /// Format GST display text
  static String formatGSTText(double serviceAmount) {
    final gst = getGSTAmount(serviceAmount);
    return '-₹${gst.toStringAsFixed(0)}';
  }

  /// Get full earnings breakdown for display (Invoice view)
  ///
  /// Invoice Breakdown:
  /// - Service Amount
  /// - Visiting Charge (if applicable)
  /// - GST
  /// - Total Bill
  ///
  /// Earning Breakdown:
  /// - Total Amount
  /// - GST Deduction
  /// - Commission Deduction
  /// - Net Earning
  static Map<String, String> getInvoiceBreakdown(
    double serviceAmount, {
    double visitingCharge = 0.0,
    bool isServiceComplete = true,
  }) {
    final data = calculateEarnings(
      serviceAmount,
      visitingCharge: visitingCharge,
      isServiceComplete: isServiceComplete,
    );

    final result = <String, String>{};

    // Invoice Section
    result['Service Amount'] =
        '₹${serviceAmount.toStringAsFixed(0)}';
    if (visitingCharge > 0) {
      result['Visiting Charge'] =
          '₹${visitingCharge.toStringAsFixed(0)}';
      if (isServiceComplete) {
        result['Visiting Charge (Adjusted)'] =
            '-₹${visitingCharge.toStringAsFixed(0)}';
      }
    }
    result['GST (18%)'] =
        '₹${(data['gstAmount'] as double).toStringAsFixed(0)}';
    result['Total Bill'] =
        '₹${(data['finalBill'] as double).toStringAsFixed(0)}';

    return result;
  }

  /// Get earnings breakdown for technician display
  static Map<String, String> getEarningsBreakdown(
    double serviceAmount, {
    double visitingCharge = 0.0,
  }) {
    final data = calculateEarnings(serviceAmount,
        visitingCharge: visitingCharge);

    return {
      'Total Amount (Service)':
          '₹${serviceAmount.toStringAsFixed(0)}',
      'GST Deduction':
          '-₹${(data['gstAmount'] as double).toStringAsFixed(0)}',
      'Commission Deduction (${data['commissionSlab']})':
          '-₹${(data['commission'] as double).toStringAsFixed(0)}',
      'Net Earning':
          '₹${(data['technicianEarnings'] as double).toStringAsFixed(0)}',
    };
  }
}