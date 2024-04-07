import 'dart:async';
// ignore: unused_import
import 'dart:developer';

// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bear_tracks/globals.dart';

class GPS {
  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 1,
  );
  
  LatLng? _latlng;
  Stream<ServiceStatus>? _serviceStatusStream;
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  StreamSubscription<Position>? _positionStreamSubscription;
  late SharedPreferences _prefs;

  Stream<ServiceStatus>? get serviceStatusStream => _serviceStatusStream;

  /*
    INITIALIZATION METHODS
  */

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _startServiceStream();
    await _startPositionStream();
  }
  void dispose() {
    _stopPositionStream();
    _stopServiceStream();
  }

  /*
    PUBLIC METHODS
  */

  // Gets the initial LatLng that the map should center to upon loading for the first time.
  LatLng getInitialLatLng() {
    return _latlng ?? _loadLatLng() ?? mercerCenter;
  }

  /*
    PRIVATE METHODS
  */

  // The service stream is responsible for sending updates whenever the status of the user's location services updates.
  Future<void> _startServiceStream() async {
    _serviceStatusStream ??= Geolocator.getServiceStatusStream();
    _serviceStatusStreamSubscription ??= _serviceStatusStream
      ?.listen((ServiceStatus status) {
        // Enable/disable the position stream based on the status of location services.
        status == ServiceStatus.enabled? _startPositionStream() : _stopPositionStream();        
      }, onError: (e, stackTrace) {
        log('Error during service stream: $e\n$stackTrace');
        _stopServiceStream();
      });
  }
  void _stopServiceStream() {
    _serviceStatusStreamSubscription?.cancel();
    _serviceStatusStreamSubscription = null;
  }

  // The position stream is responsible for sending updates whenever the user's location changes.
  Future<void> _startPositionStream() async {
    try {
      if (!await isLocationPermissionEnabledGL(request: true)) return;
      _latlng = toLatLng(await Geolocator.getCurrentPosition());
      _positionStreamSubscription ??= Geolocator.getPositionStream(
        locationSettings: _locationSettings
      ).listen((Position pos) {
        _latlng = toLatLng(pos);
        _saveLatLng(_latlng);
      }, onError: (e, stackTrace) {
        log('Error during position stream: $e\n$stackTrace');
        _stopPositionStream();
      },
      cancelOnError: true);
    } catch (e, stackTrace) {
      log('Error starting position stream (the user was probably fiddling with location): $e\n$stackTrace');
      _stopPositionStream();
    }
  }
  void _stopPositionStream() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _latlng = null;
  }

  /*
    IO
  */

  // Saves the user's LatLng to disk so that it can be retrieved on next startup.
  void _saveLatLng(LatLng? latlng) {
    if (latlng == null) return;
    _prefs.setDouble('latitude', latlng.latitude);
    _prefs.setDouble('longitude', latlng.longitude);
  }
  // Load the user's saved LatLng from disk.
  LatLng? _loadLatLng() {
    final double? latitude = _prefs.getDouble('latitude'), longitude = _prefs.getDouble('longitude');
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude, longitude);
  }  
}


// Check GEOLOCATOR for whether location permissions are enabled and request permission if it is denied.
Future<bool> isLocationPermissionEnabledGL({bool request = false}) async {
  return request? await _requestLocationPermissionGL() : await _isLocationPermissionEnabledGL();
}
// Check GEOLOCATOR for whether location services are enabled.
Future<bool> isLocationServiceEnabledGL({bool request = false}) async {
  final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (serviceEnabled) return true;
  try {
    if (request) await Geolocator.openLocationSettings();
  } catch (e, stackTrace) {
    log('Error requesting location services (user probably just denied pop-up): $e\n$stackTrace');
    return false;
  }
  return await Geolocator.isLocationServiceEnabled();
}
// Checks whether the user has both location services and permissions enabled.
// Adds the option to request permission if it is denied.
Future<bool> isLocationPermissionAndServiceEnabledGL({bool request = false}) async {
  return await isLocationPermissionEnabledGL(request: request) && await isLocationServiceEnabledGL(request: request);
}

// Check GEOLOCATOR for whether location permissions are enabled.
Future<bool> _isLocationPermissionEnabledGL() async {
  return await Geolocator.checkPermission() == LocationPermission.whileInUse;
}
// Use GEOLOCATOR to request location permissions from the user.
Future<bool> _requestLocationPermissionGL() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    // Hacky way to check whether the user enables location after the prompt.
    if (permission == LocationPermission.denied) {
      printSnackBar('Location permissions are not enabled for this instance. Please enable permissions to use location features.');
      return false;
    }
  }
  if (permission == LocationPermission.deniedForever) {
    printSnackBar('Location permissions have been permanently denied. Please enable permissions to use location features.');
    Timer(const Duration(seconds: 5), () async => await Geolocator.openAppSettings()? await _isLocationPermissionEnabledGL() : false);
  }
  return true;
}

/*
  HELPERS / UTILITY
*/

// Converts a GEOLOCATOR Position to a LatLng
LatLng toLatLng(Position position) => LatLng(position.latitude, position.longitude);

double distanceBetweenGL(LatLng start, LatLng end) {
  return Geolocator.distanceBetween(start.latitude, start.longitude, end.latitude, end.longitude);
}