import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';

import 'package:bear_tracks/globals.dart';

class GeolocationService {
  Future<Position?>? getCurrentPosition() async {
    try {
      final locationEnabled = await _locationServicesEnabled();
      if (!locationEnabled) return null;

      final hasPermission = await _locationPermissionEnabled();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current location: $e');
      }
      printSnackBar('An error was encountered while fetching current location.');
      return null;
    }
  }

  Future<bool> _locationServicesEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    
    if (!serviceEnabled) {
      printSnackBar('Location services are disabled. Enable the services to use location features.');
    }
    return serviceEnabled;
  }

  // Checks that the user has enabled location permissions.
  Future<bool> _locationPermissionEnabled() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    try {
      // Location permissions denied once before.
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        // Location permissions denied once again.
        if (permission == LocationPermission.denied) {   
          printSnackBar('Location permissions are not enabled for this instance. Enable permissions to use location features.');
          return false;
        }
      }
      // Location permissions always denied.
      if (permission == LocationPermission.deniedForever) {
        printSnackBar('Location permissions are not enabled. Enable permissions to use location features.');
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location permissions: $e');
      }
      printSnackBar('An error was encountered while fetching location permissions.');
    }

    return true;
  }

  // Helper function for displaying messages on the SnackBar.
  void printSnackBar(String message) {
    final SnackBar snackBar = SnackBar(content: Text(message));
    scaffoldKey.currentState?.showSnackBar(snackBar);
  }
}
