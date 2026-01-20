import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class TechPaymentService {
  // Replace with your actual Firebase Cloud Function URL
  static const String _baseUrl = 'https://us-central1-bharat-doorstep-native.cloudfunctions.net';

  /// Create wallet recharge order
  static Future<Map<String, dynamic>> createWalletRechargeOrder({
    required String technicianId,
    required double amount,
  }) async {
    try {
      debugPrint('📤 Creating wallet recharge order...');
      debugPrint('Technician ID: $technicianId');
      debugPrint('Amount: ₹$amount');

      final response = await http.post(
        Uri.parse('$_baseUrl/createWalletRechargeOrder'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'technicianId': technicianId,
          'amount': amount,
        }),
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Order created successfully');
        debugPrint('Order ID: ${data['orderId']}');
        return data;
      } else {
        final error = json.decode(response.body);
        debugPrint('❌ Error response: $error');
        throw Exception(error['error'] ?? 'Failed to create order');
      }
    } catch (e) {
      debugPrint('❌ Exception in createWalletRechargeOrder: $e');
      rethrow;
    }
  }

  /// Verify wallet recharge payment
  static Future<Map<String, dynamic>> verifyWalletPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String technicianId,
  }) async {
    try {
      debugPrint('🔐 Verifying wallet payment...');
      debugPrint('Order ID: $razorpayOrderId');
      debugPrint('Payment ID: $razorpayPaymentId');
      debugPrint('Technician ID: $technicianId');

      final response = await http.post(
        Uri.parse('$_baseUrl/verifyWalletPayment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
          'technicianId': technicianId,
        }),
      );

      debugPrint('📥 Verification status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Payment verified successfully');
        debugPrint('New balance: ${data['newBalance']}');
        return data;
      } else {
        final error = json.decode(response.body);
        debugPrint('❌ Verification failed: $error');
        throw Exception(error['error'] ?? 'Payment verification failed');
      }
    } catch (e) {
      debugPrint('❌ Exception in verifyWalletPayment: $e');
      rethrow;
    }
  }
}