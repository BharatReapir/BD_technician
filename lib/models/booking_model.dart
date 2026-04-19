import 'package:flutter/material.dart';

import '../utils/commission_calculator.dart';

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
  final String? pincode; // 🔑 NEW: Pincode for mapping
  final String? technicianId;
  final String? technicianName;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // ✅ NEW: Coin fields
  final int? coinsUsed;
  final double? coinDiscount;

  // 💰 Payment method tracking (Cash/UPI)
  final String? paymentMethod;

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
    this.pincode, // 🔑 NEW: Pincode parameter
    this.technicianId,
    this.technicianName,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    // ✅ NEW: Coin parameters
    this.coinsUsed,
    this.coinDiscount,
    // 💰 Payment method
    this.paymentMethod,
  });

  /// Technician earnings = Service Amount - Commission
  /// Commission is based on serviceCharge (Service Amount), NOT totalAmount (Final Bill)
  double get earnings => CommissionCalculator.getTechnicianEarnings(serviceCharge);
  
  /// Commission slab based on serviceCharge only
  double get commission => CommissionCalculator.getCommission(serviceCharge);
  
  String get commissionText => CommissionCalculator.formatCommissionText(serviceCharge);
  
  String get earningsText => CommissionCalculator.formatEarningsText(serviceCharge);

  /// GST amount on service charge
  double get gstOnService => CommissionCalculator.getGSTAmount(serviceCharge);

  /// Final bill = Service Amount + GST
  double get finalBill => CommissionCalculator.getFinalBill(serviceCharge);

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
      'pincode': pincode, // 🔑 NEW: Pincode in JSON
      'technicianId': technicianId,
      'technicianName': technicianName,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // ✅ NEW: Coin fields in JSON
      'coinsUsed': coinsUsed ?? 0,
      'coinDiscount': coinDiscount ?? 0.0,
      // 💰 Payment method
      'paymentMethod': paymentMethod ?? 'pending',
    };
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userPhone: json['userPhone']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      serviceCharge: _toDouble(json['serviceCharge']),
      visitingCharge: _toDouble(json['visitingCharge']),
      taxableAmount: _toDouble(json['taxableAmount']),
      gstAmount: _toDouble(json['gstAmount']),
      totalAmount: _toDouble(json['totalAmount']),
      paymentId: json['paymentId']?.toString(),
      razorpayOrderId: json['razorpayOrderId']?.toString(),
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      scheduledTime: json['scheduledTime']?.toString() ?? '',
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      pincode: json['pincode']?.toString(), // ✅ FIX: Convert to string
      technicianId: json['technicianId']?.toString(),
      technicianName: json['technicianName']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: _parseDateTime(json['createdAt']), // ✅ FIX: Better date parsing
      updatedAt: _parseDateTime(json['updatedAt']), // ✅ FIX: Better date parsing
      // ✅ NEW: Parse coin fields
      coinsUsed: json['coinsUsed'] is int ? json['coinsUsed'] : (json['coinsUsed'] != null ? int.tryParse(json['coinsUsed'].toString()) : 0),
      coinDiscount: _toDouble(json['coinDiscount']),
      // 💰 Payment method
      paymentMethod: json['paymentMethod']?.toString(),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    // Handle milliseconds timestamp
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    
    // Handle string timestamp
    if (value is String) {
      // Try parsing as milliseconds first
      final timestamp = int.tryParse(value);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      
      // Try parsing as ISO string
      try {
        return DateTime.parse(value);
      } catch (e) {
        debugPrint('⚠️ Failed to parse date: $value');
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

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
    String? pincode, // 🔑 NEW: Pincode in copyWith
    String? technicianId,
    String? technicianName,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    // ✅ NEW: Coin parameters in copyWith
    int? coinsUsed,
    double? coinDiscount,
    // 💰 Payment method
    String? paymentMethod,
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
      pincode: pincode ?? this.pincode, // 🔑 NEW: Pincode in copyWith
      technicianId: technicianId ?? this.technicianId,
      technicianName: technicianName ?? this.technicianName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // ✅ NEW: Coin fields in copyWith
      coinsUsed: coinsUsed ?? this.coinsUsed,
      coinDiscount: coinDiscount ?? this.coinDiscount,
      // 💰 Payment method
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}