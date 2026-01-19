class BookingModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String service;
  final String status;
  final double serviceCharge;
  final double visitingCharge;
  final double taxableAmount;
  final double gstAmount;
  final double totalAmount;
  final String? paymentId;
  final String? razorpayOrderId;
  final String paymentStatus;
  final String scheduledTime;
  final String? address;
  final String? city;
  final String? technicianId;
  final String? technicianName;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.service,
    required this.status,
    required this.serviceCharge,
    required this.visitingCharge,
    required this.taxableAmount,
    required this.gstAmount,
    required this.totalAmount,
    this.paymentId,
    this.razorpayOrderId,
    this.paymentStatus = 'pending',
    required this.scheduledTime,
    this.address,
    this.city,
    this.technicianId,
    this.technicianName,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // ✅ FIX: Return totalAmount instead of null
  double get earnings => totalAmount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'service': service,
      'status': status,
      'serviceCharge': serviceCharge,
      'visitingCharge': visitingCharge,
      'taxableAmount': taxableAmount,
      'gstAmount': gstAmount,
      'totalAmount': totalAmount,
      'paymentId': paymentId,
      'razorpayOrderId': razorpayOrderId,
      'paymentStatus': paymentStatus,
      'scheduledTime': scheduledTime,
      'address': address,
      'city': city,
      'technicianId': technicianId,
      'technicianName': technicianName,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhone: json['userPhone'] ?? '',
      service: json['service'] ?? '',
      status: json['status'] ?? 'pending',
      // ✅ FIX: Safe conversion from any number type to double
      serviceCharge: _toDouble(json['serviceCharge']),
      visitingCharge: _toDouble(json['visitingCharge']),
      taxableAmount: _toDouble(json['taxableAmount']),
      gstAmount: _toDouble(json['gstAmount']),
      totalAmount: _toDouble(json['totalAmount']),
      paymentId: json['paymentId'],
      razorpayOrderId: json['razorpayOrderId'],
      paymentStatus: json['paymentStatus'] ?? 'pending',
      scheduledTime: json['scheduledTime'] ?? '',
      address: json['address'],
      city: json['city'],
      technicianId: json['technicianId'],
      technicianName: json['technicianName'],
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  // ✅ Helper method to safely convert any number type to double
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? service,
    String? status,
    double? serviceCharge,
    double? visitingCharge,
    double? taxableAmount,
    double? gstAmount,
    double? totalAmount,
    String? paymentId,
    String? razorpayOrderId,
    String? paymentStatus,
    String? scheduledTime,
    String? address,
    String? city,
    String? technicianId,
    String? technicianName,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      service: service ?? this.service,
      status: status ?? this.status,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      visitingCharge: visitingCharge ?? this.visitingCharge,
      taxableAmount: taxableAmount ?? this.taxableAmount,
      gstAmount: gstAmount ?? this.gstAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentId: paymentId ?? this.paymentId,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      address: address ?? this.address,
      city: city ?? this.city,
      technicianId: technicianId ?? this.technicianId,
      technicianName: technicianName ?? this.technicianName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}