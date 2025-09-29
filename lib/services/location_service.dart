import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'geocoding_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if permission has been requested before
  Future<bool> hasRequestedPermissionBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('location_permission_requested') ?? false;
  }

  // Mark that permission has been requested
  Future<void> markPermissionRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_permission_requested', true);
  }

  // Get current location with proper permission handling
  Future<Position?> getCurrentLocation() async {
    try {
      print('LocationService: Starting getCurrentLocation, isWeb=$kIsWeb');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('LocationService: Services enabled=$serviceEnabled');
      
      if (!serviceEnabled) {
        print('Location services are disabled');
        // On web, services might show as disabled but still work
        if (!kIsWeb) {
          return null;
        }
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      print('LocationService: Current permission=$permission');
      
      // If permission has never been requested
      if (permission == LocationPermission.denied) {
        final hasRequested = await hasRequestedPermissionBefore();
        print('LocationService: Has requested before=$hasRequested');
        
        if (!hasRequested || kIsWeb) { // Always try on web
          // Request permission for the first time
          print('LocationService: Requesting permission...');
          permission = await Geolocator.requestPermission();
          print('LocationService: New permission=$permission');
          await markPermissionRequested();
        } else {
          // Permission was denied before, don't ask again automatically
          print('Permission denied previously');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        // Get current position with high accuracy
        print('LocationService: Getting position...');
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
        print('LocationService: Got position lat=${position.latitude}, lng=${position.longitude}');
        return position;
      }

      return null;
    } catch (e) {
      print('LocationService: Error getting location: $e');
      // On web, try a simpler approach
      if (kIsWeb) {
        try {
          print('LocationService: Trying web fallback...');
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          );
          print('LocationService: Web fallback success lat=${position.latitude}, lng=${position.longitude}');
          return position;
        } catch (webError) {
          print('LocationService: Web fallback failed: $webError');
        }
      }
      return null;
    }
  }

  // Get city name from coordinates - Enhanced with real API
  Future<Map<String, dynamic>?> getCityFromCoordinates(double latitude, double longitude) async {
    try {
      print('LocationService: Getting detailed address for lat=$latitude, lng=$longitude');
      
      // Use the new geocoding service for all platforms
      final addressData = await GeocodingService.getAddressFromCoordinates(latitude, longitude);
      
      if (addressData != null) {
        print('LocationService: Got address data: ${addressData['display']}');
        return addressData;
      }
      
      // Fallback to old geocoding method if API fails
      if (!kIsWeb) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            latitude,
            longitude,
          );
          
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            
            return {
              'formatted': '${place.locality ?? place.subLocality ?? ''}, ${place.administrativeArea ?? ''}',
              'area': place.subLocality ?? '',
              'city': place.locality ?? '',
              'state': place.administrativeArea ?? '',
              'pincode': place.postalCode ?? '',
              'country': place.country ?? '',
              'display': place.locality ?? 'Location detected',
            };
          }
        } catch (e) {
          print('LocationService: Fallback geocoding failed: $e');
        }
      }
      
      // Final fallback
      return {
        'formatted': 'Location detected',
        'area': '',
        'city': 'Location detected',
        'state': '',
        'pincode': '',
        'country': '',
        'display': 'Location detected',
      };
    } catch (e) {
      print('LocationService: Error getting address: $e');
      return null;
    }
  }

  // Update user's location in Firestore with detailed address
  Future<bool> updateUserLocation({Position? position}) async {
    try {
      print('LocationService: updateUserLocation called');
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('LocationService: No authenticated user');
        return false;
      }

      Position? currentPosition = position ?? await getCurrentLocation();
      
      if (currentPosition != null) {
        // Get detailed address from coordinates
        final addressData = await getCityFromCoordinates(
          currentPosition.latitude,
          currentPosition.longitude,
        );
        
        if (addressData != null) {
          print('LocationService: Updating user location with detailed address: ${addressData['display']}');

          Map<String, dynamic> locationData = {
            'latitude': currentPosition.latitude,
            'longitude': currentPosition.longitude,
            'location': addressData['formatted'] ?? addressData['display'] ?? 'Location detected',
            'city': addressData['city'] ?? addressData['display'] ?? 'Location detected',
            'area': addressData['area'] ?? '',
            'state': addressData['state'] ?? '',
            'pincode': addressData['pincode'] ?? '',
            'country': addressData['country'] ?? '',
            'displayLocation': addressData['display'] ?? 'Location detected',
            'locationUpdatedAt': FieldValue.serverTimestamp(),
          };

          // Update user document - use set with merge to ensure document exists
          await _firestore.collection('users').doc(userId).set(
            locationData,
            SetOptions(merge: true),
          );
          
          print('LocationService: Location updated successfully with area: ${addressData['area']}, city: ${addressData['city']}');
          return true;
        } else {
          print('LocationService: Could not get address data');
          return false;
        }
      } else {
        print('LocationService: Could not get current position');
        return false;
      }
    } catch (e) {
      print('LocationService: Error updating user location: $e');
      // Try to create/update with just a default location
      try {
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          await _firestore.collection('users').doc(userId).set({
            'city': 'Location unavailable',
            'location': 'Location unavailable',
            'displayLocation': 'Location unavailable',
          }, SetOptions(merge: true));
        }
      } catch (fallbackError) {
        print('LocationService: Fallback update also failed: $fallbackError');
      }
      return false;
    }
  }

  // Initialize location on app start
  Future<void> initializeLocation() async {
    try {
      // Check if we have permission already
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        // We have permission, update location
        await updateUserLocation();
      } else if (permission == LocationPermission.denied) {
        // Check if this is first time
        final hasRequested = await hasRequestedPermissionBefore();
        
        if (!hasRequested) {
          // First time, request permission
          permission = await Geolocator.requestPermission();
          await markPermissionRequested();
          
          if (permission == LocationPermission.whileInUse || 
              permission == LocationPermission.always) {
            await updateUserLocation();
          }
        }
      }
    } catch (e) {
      print('Error initializing location: $e');
    }
  }

  // Request location permission manually (for settings)
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        // Permission granted, update location
        return await updateUserLocation();
      }
      
      return false;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  // Open app settings for location permission
  Future<void> openLocationSettings() async {
    await Geolocator.openAppSettings();
  }

  // Clear stored permission preference (for testing)
  Future<void> clearPermissionPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('location_permission_requested');
  }
}