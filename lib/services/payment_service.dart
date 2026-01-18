import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class PaymentService {
  // 🔒 REPLACE THIS with your actual backend URL
  // For local testing: http://localhost:5001/YOUR_PROJECT_ID/us-central1
  // For production: https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net
  static const String _baseUrl = 'https://us-central1-bharat-doorstep-native.cloudfunctions.net';


  static Future<Map<String, dynamic>> createOrder({
    required String bookingId,
    required double serviceCharge,
    required String area, // "standard" or "premium"
    required String userId,
  }) async {
    try {
      debugPrint('📤 Creating Razorpay order...');
      debugPrint('Service Charge: ₹$serviceCharge');
      debugPrint('Area: $area');

      final response = await http.post(
        Uri.parse('$_baseUrl/createRazorpayOrder'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'bookingId': bookingId,
          'serviceCharge': serviceCharge,
          'area': area, // "standard" = 299, "premium" = 399
          'userId': userId,
        }),
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Order created: ${data['orderId']}');
        debugPrint('💰 Total Amount: ₹${data['breakdown']['totalAmount']}');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to create order');
      }
    } catch (e) {
      debugPrint('❌ Error creating order: $e');
      rethrow;
    }
  }

  /// Verify Payment Signature (CRITICAL SECURITY CHECK)
  /// 
  /// This MUST be done on backend to prevent fraud.
  /// Frontend should NEVER mark payment as successful without backend verification.
  static Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String bookingId,
  }) async {
    try {
      debugPrint('🔐 Verifying payment signature...');
      debugPrint('Order ID: $razorpayOrderId');
      debugPrint('Payment ID: $razorpayPaymentId');

      final response = await http.post(
        Uri.parse('$_baseUrl/verifyPayment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
          'bookingId': bookingId,
        }),
      );

      debugPrint('📥 Verification status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Payment verified successfully');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Payment verification failed');
      }
    } catch (e) {
      debugPrint('❌ Error verifying payment: $e');
      rethrow;
    }
  }

  /// Get payment details (optional - for debugging/admin)
  static Future<Map<String, dynamic>> getPaymentDetails(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/getPaymentDetails?paymentId=$paymentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch payment details');
      }
    } catch (e) {
      debugPrint('❌ Error fetching payment details: $e');
      rethrow;
    }
  }
}