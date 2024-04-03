import 'dart:async';
// ignore: unused_import
import 'dart:developer';

// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bear_tracks/globals.dart';

// TODO: Implement openLocationSettings()

class GPS {
  LatLng? _latlng;
  Stream<ServiceStatus>? _serviceStatusStream;
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  Stream<Position>? _positionStream;
  StreamSubscription<Position>? _positionStreamSubscription;
  late SharedPreferences _prefs;
  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 1,
  );

  LatLng? get latlng => _latlng;
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

  // Check GEOLOCATOR for whether location services are enabled.
  Future<bool> isLocationServiceEnabledGL() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  // Checks whether the user has both location services and permissions enabled.
  // Adds the option to request permission if it is denied.
  Future<bool> isLocationServiceAndPermissionEnabledGL({bool request = false}) async {
    return await isLocationServiceEnabledGL() && (await (request? _requestLocationPermissionGL() : _isLocationPermissionEnabledGL()));
  }

  // Gets the initial LatLng that the map should center to upon loading for the first time.
  LatLng getInitialLatLng() {
    return _latlng ?? _loadLatLng() ?? mercerCenter;
  }

  /*
    PRIVATE METHODS
  */

  Future<void> _startServiceStream() async {
    _serviceStatusStream ??= Geolocator.getServiceStatusStream();
    _serviceStatusStreamSubscription ??= _serviceStatusStream
      ?.listen((ServiceStatus status) {
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

  Future<void> _startPositionStream() async {
    try {
      if (!await isLocationServiceAndPermissionEnabledGL(request: true)) return;

      _latlng = _toLatLng(await _getCurrentPositionGL());
      _positionStream ??= Geolocator.getPositionStream(
        locationSettings: _locationSettings
      ).asBroadcastStream();

      _positionStreamSubscription ??= _positionStream
        ?.listen((Position pos) {
          _latlng = _toLatLng(pos);
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

  // Should only be called when we are sure location services and permissions are enabled.
  Future<Position> _getCurrentPositionGL() => Geolocator.getCurrentPosition();

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
        _printSnackBar('Location permissions are not enabled for this instance. Please enable permissions and restart the app to use location features.');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // TODO: Verify that openAppSettings() works as expected
      return await Geolocator.openAppSettings()? await _isLocationPermissionEnabledGL() : false;
    }
    return true;
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

  /*
    HELPERS / UTILITY
  */

  // Converts a GEOLOCATOR Position to a LatLng
  LatLng _toLatLng(Position position) => LatLng(position.latitude, position.longitude);
  
  // Displays messages on the SnackBar.
  void _printSnackBar(String message) {
    scaffoldKey.currentState?.showSnackBar(
      SnackBar(content: Text(message))
    );
  }
}