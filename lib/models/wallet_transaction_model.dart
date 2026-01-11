class WalletTransaction {
  final String id;
  final String technicianId;
  final double amount;
  final String type;
  final String description;
  final double balanceAfter;
  final DateTime timestamp;
  final String? jobId;

  WalletTransaction({
    required this.id,
    required this.technicianId,
    required this.amount,
    required this.type,
    required this.description,
    required this.balanceAfter,
    required this.timestamp,
    this.jobId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technicianId': technicianId,
      'amount': amount,
      'type': type,
      'description': description,
      'balanceAfter': balanceAfter,
      'timestamp': timestamp.toIso8601String(),
      'jobId': jobId,
    };
  }

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? '',
      technicianId: json['technicianId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      balanceAfter: (json['balanceAfter'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      jobId: json['jobId'],
    );
  }
}