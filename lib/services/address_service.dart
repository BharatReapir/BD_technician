import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddressService {
  static const String _addressesKey = 'saved_addresses';

  static Future<List<Map<String, String>>> getSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = prefs.getString(_addressesKey);
      
      if (addressesJson != null) {
        final List<dynamic> addressesList = json.decode(addressesJson);
        return addressesList.map((address) => Map<String, String>.from(address)).toList();
      }
      
      
      return _getDefaultAddresses();
    } catch (e) {
      print('❌ Error getting saved addresses: $e');
      return _getDefaultAddresses();
    }
  }

  /// Save a new address
  static Future<bool> saveAddress(Map<String, String> address) async {
    try {
      final addresses = await getSavedAddresses();
      addresses.add(address);
      
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = json.encode(addresses);
      await prefs.setString(_addressesKey, addressesJson);
      
      print('✅ Address saved successfully');
      return true;
    } catch (e) {
      print('❌ Error saving address: $e');
      return false;
    }
  }

  /// Update an existing address
  static Future<bool> updateAddress(int index, Map<String, String> updatedAddress) async {
    try {
      final addresses = await getSavedAddresses();
      
      if (index >= 0 && index < addresses.length) {
        addresses[index] = updatedAddress;
        
        final prefs = await SharedPreferences.getInstance();
        final addressesJson = json.encode(addresses);
        await prefs.setString(_addressesKey, addressesJson);
        
        print('✅ Address updated successfully');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error updating address: $e');
      return false;
    }
  }

  /// Delete an address
  static Future<bool> deleteAddress(int index) async {
    try {
      final addresses = await getSavedAddresses();
      
      if (index >= 0 && index < addresses.length) {
        addresses.removeAt(index);
        
        final prefs = await SharedPreferences.getInstance();
        final addressesJson = json.encode(addresses);
        await prefs.setString(_addressesKey, addressesJson);
        
        print('✅ Address deleted successfully');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error deleting address: $e');
      return false;
    }
  }

  /// Get default addresses (fallback)
  static List<Map<String, String>> _getDefaultAddresses() {
    return [
      {
        'type': 'Home',
        'address': '123, MG Road, Sector 12',
        'city': 'Mumbai',
        'pincode': '400001',
        'landmark': 'Near Metro Station',
      },
      {
        'type': 'Office',
        'address': '456, Park Street, Block A',
        'city': 'Mumbai',
        'pincode': '400002',
        'landmark': 'Opposite Shopping Mall',
      },
    ];
  }

  /// Clear all saved addresses
  static Future<bool> clearAllAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_addressesKey);
      print('✅ All addresses cleared');
      return true;
    } catch (e) {
      print('❌ Error clearing addresses: $e');
      return false;
    }
  }
}