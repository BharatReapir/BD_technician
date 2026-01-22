import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  /// Get current location coordinates
  static Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        throw Exception('Location services are disabled. Please enable location services.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permissions are denied');
          throw Exception('Location permissions are denied. Please grant location access.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permissions are permanently denied');
        throw Exception('Location permissions are permanently denied. Please enable location access in settings.');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('✅ Current position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Error getting current position: $e');
      rethrow;
    }
  }

  /// Get detailed address from coordinates
  static Future<Map<String, String>?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        
        // Build complete address
        List<String> addressParts = [];
        
        if (place.subThoroughfare?.isNotEmpty == true) {
          addressParts.add(place.subThoroughfare!);
        }
        if (place.thoroughfare?.isNotEmpty == true) {
          addressParts.add(place.thoroughfare!);
        }
        if (place.subLocality?.isNotEmpty == true) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality?.isNotEmpty == true && place.locality != place.subLocality) {
          addressParts.add(place.locality!);
        }
        
        String completeAddress = addressParts.join(', ');
        
        // Fallback if address is empty
        if (completeAddress.isEmpty) {
          completeAddress = '${place.name ?? ''}, ${place.locality ?? 'Unknown Location'}';
        }

        final addressData = {
          'address': completeAddress,
          'city': place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? 'Unknown City',
          'pincode': place.postalCode ?? '',
          'landmark': place.name ?? '',
          'state': place.administrativeArea ?? '',
          'country': place.country ?? 'India',
        };

        print('✅ Address resolved: $addressData');
        return addressData;
      }
      
      print('❌ No placemarks found for coordinates');
      return null;
    } catch (e) {
      print('❌ Error getting address from coordinates: $e');
      
      // Fallback with coordinate-based address
      return {
        'address': 'Location at $latitude, $longitude',
        'city': 'Unknown City',
        'pincode': '',
        'landmark': '',
        'state': '',
        'country': 'India',
      };
    }
  }

  /// Get current location address (combines position + geocoding)
  static Future<Map<String, String>?> getCurrentLocationAddress() async {
    try {
      print('🔄 Getting current location address...');
      
      // Get current position
      Position? position = await getCurrentPosition();
      if (position == null) {
        throw Exception('Unable to get current location');
      }

      // Get address from coordinates
      Map<String, String>? address = await getAddressFromCoordinates(
        position.latitude, 
        position.longitude
      );

      if (address != null) {
        print('✅ Current location address retrieved successfully');
        return address;
      } else {
        throw Exception('Unable to get address for current location');
      }
    } catch (e) {
      print('❌ Error getting current location address: $e');
      rethrow;
    }
  }

  /// Check if location permissions are granted
  static Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      print('❌ Error checking location permission: $e');
      return false;
    }
  }

  /// Request location permissions
  static Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      print('❌ Error requesting location permission: $e');
      return false;
    }
  }

  /// Open location settings
  static Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      print('❌ Error opening location settings: $e');
      // Fallback to app settings
      await openAppSettings();
    }
  }

  /// Get short location string (city, state)
  static Future<String> getShortLocation() async {
    try {
      final address = await getCurrentLocationAddress();
      if (address != null) {
        return '${address['city']}, ${address['state']}';
      }
      return 'Unknown Location';
    } catch (e) {
      print('❌ Error getting short location: $e');
      return 'Location unavailable';
    }
  }

  /// Get detailed address string
  static Future<String> getDetailedAddress() async {
    try {
      final address = await getCurrentLocationAddress();
      if (address != null) {
        return '${address['address']}, ${address['city']} - ${address['pincode']}';
      }
      return 'Address unavailable';
    } catch (e) {
      print('❌ Error getting detailed address: $e');
      return 'Address unavailable';
    }
  }

  /// Calculate distance between two coordinates (in kilometers)
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    ) / 1000; // Convert meters to kilometers
  }
}