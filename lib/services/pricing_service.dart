import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class PricingService {
  static final DatabaseReference _pricingRef = FirebaseDatabase.instance.ref('pricing');

  /// Fetch price for a specific service
  static Future<Map<String, dynamic>?> getServicePricing(String serviceId) async {
    try {
      debugPrint('🔍 Fetching pricing for: $serviceId');
      final snapshot = await _pricingRef.child(serviceId).get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        debugPrint('✅ Found pricing for $serviceId: ₹${data['price']}');
        return data;
      }
      
      debugPrint('⚠️ No pricing found for: $serviceId');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching pricing: $e');
      return null;
    }
  }

  /// Fetch all pricing
  static Future<Map<String, dynamic>> getAllPricing() async {
    try {
      debugPrint('🔍 Fetching all pricing...');
      final snapshot = await _pricingRef.get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        debugPrint('✅ Fetched ${data.length} pricing entries');
        return data;
      }
      
      debugPrint('⚠️ No pricing data found');
      return {};
    } catch (e) {
      debugPrint('❌ Error fetching all pricing: $e');
      return {};
    }
  }

  /// Listen to real-time price changes for a specific service
  static Stream<Map<String, dynamic>> watchServicePricing(String serviceId) {
    return _pricingRef.child(serviceId).onValue.map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return {};
    });
  }

  /// Listen to all pricing changes in real-time
  static Stream<Map<String, dynamic>> watchAllPricing() {
    return _pricingRef.onValue.map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return {};
    });
  }

  /// Get price with fallback
  static int getPrice(Map<String, dynamic>? pricing, int fallbackPrice) {
    if (pricing == null) return fallbackPrice;
    return pricing['price'] ?? fallbackPrice;
  }

  /// Get price type (fixed or inspection)
  static String getPriceType(Map<String, dynamic>? pricing) {
    if (pricing == null) return 'fixed';
    return pricing['priceType'] ?? 'fixed';
  }

  /// Check if service requires inspection
  static bool requiresInspection(Map<String, dynamic>? pricing, int fallbackPrice) {
    if (pricing == null) return fallbackPrice == 0;
    final priceType = pricing['priceType'] ?? 'fixed';
    final price = pricing['price'] ?? fallbackPrice;
    return priceType == 'inspection' || price == 0;
  }
}
