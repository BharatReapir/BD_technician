class CommissionCalculator {
  /// Calculate technician earnings after commission deduction
  /// Services >= ₹1000: ₹399 commission
  /// Services < ₹1000: ₹199 commission
  static Map<String, dynamic> calculateEarnings(double totalAmount) {
    double commission;
    
    if (totalAmount >= 1000) {
      commission = 399.0;
    } else {
      commission = 199.0;
    }
    
    double technicianEarnings = totalAmount - commission;
    
    // Ensure earnings are not negative
    if (technicianEarnings < 0) {
      technicianEarnings = 0;
      commission = totalAmount;
    }
    
    return {
      'totalAmount': totalAmount,
      'commission': commission,
      'technicianEarnings': technicianEarnings,
      'commissionPercentage': totalAmount > 0 ? (commission / totalAmount * 100) : 0,
    };
  }
  
  /// Get commission amount for a given total amount
  static double getCommission(double totalAmount) {
    return totalAmount >= 1000 ? 399.0 : 199.0;
  }
  
  /// Get technician earnings for a given total amount
  static double getTechnicianEarnings(double totalAmount) {
    final commission = getCommission(totalAmount);
    final earnings = totalAmount - commission;
    return earnings < 0 ? 0 : earnings;
  }
  
  /// Format commission display text
  static String formatCommissionText(double totalAmount) {
    final commission = getCommission(totalAmount);
    final percentage = totalAmount > 0 ? (commission / totalAmount * 100) : 0;
    return '-₹${commission.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)';
  }
  
  /// Format earnings display text
  static String formatEarningsText(double totalAmount) {
    final earnings = getTechnicianEarnings(totalAmount);
    return '₹${earnings.toStringAsFixed(0)}';
  }
}