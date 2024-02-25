import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';

import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';

import 'package:bear_tracks/globals.dart';

class GPS {
  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.best,
    distanceFilter: 1,
  );

  LatLng? _latlng;
  Position? _position;
  ServiceStatus? _serviceStatus;
  Stream<ServiceStatus>? _serviceStatusStream;
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  Stream<Position>? _positionStream;
  StreamSubscription<Position>? _positionStreamSubscription;

  LatLng? get latlng => _latlng;
  ServiceStatus get serviceStatus => _serviceStatus ?? ServiceStatus.disabled;
  Stream<ServiceStatus>? get serviceStatusStream => _serviceStatusStream;
  StreamSubscription<ServiceStatus>? get serviceStatusStreamSubscription => _serviceStatusStreamSubscription;
  Stream<Position>? get positionStream => _positionStream;
  StreamSubscription<Position>? get positionStreamSubscription => _positionStreamSubscription;  
  Future<LatLng?> get currentLatLng async => toLatLng(await getCurrentPositionGL());
  Future<LatLng?> get lastKnownLatLng async => toLatLng(await getLastKnownPositionGL());

  // Initialize the GPS
  // First manually check if location services are enabled. This is so the map can build correctly as soon as possible.
  // Then, only if location permissions are given, do we start the service and position streams.
  // This is because the service stream controls the position stream, i.e., turns it on/off with location.
  Future<void> init() async {
    if (await requestLocationPermissionGL()) {
      await startServiceStream();
      startPositionStream();
    }
  }

  // Save the current location, then stop both the service and position streams.
  void dispose() {
    _savePosition(_position);
    stopServiceStream();
    stopPositionStream();
  }

  void debug() {
    log('LatLng: $_latlng\n'
        'Position: $_position\n'
        'ServiceStatus: $_serviceStatus\n'
        'ServiceStream: ${serviceStatusStreamSubscription != null}\n'
        'PositionStream: ${_positionStreamSubscription != null}\n'
    );
  }

  Future<void> startServiceStream() async {
    _serviceStatus = await Geolocator.isLocationServiceEnabled()? ServiceStatus.enabled : ServiceStatus.disabled;
    _serviceStatusStream ??= Geolocator.getServiceStatusStream();
    _serviceStatusStreamSubscription ??= _serviceStatusStream
      ?.listen((ServiceStatus status) {
        _serviceStatus = status;
        (_serviceStatus == ServiceStatus.enabled)
          ? startPositionStream()
          : stopPositionStream();        
      }, onError: (e, stackTrace) {
        log('Error during service stream: $e\n$stackTrace');
        stopServiceStream();
      });
  }

  void stopServiceStream() {
    _serviceStatusStreamSubscription?.cancel();
    _serviceStatusStreamSubscription = null;
  }

  Future<void> startPositionStream() async {
    try {
      if (!await isServiceStatusAndPermissionsEnabledGL()) return;

      // Initialize position and latlng
      _position = await Geolocator.getCurrentPosition();
      _latlng = toLatLng(_position);

      _positionStream ??= Geolocator.getPositionStream(
        locationSettings: _locationSettings
      // TODO: Is this needed?
      ).asBroadcastStream();

      _positionStreamSubscription ??= _positionStream
        ?.listen((Position pos) {
          _position = pos;
          _latlng = toLatLng(pos);
          _savePosition(pos);
        }, onError: (e, stackTrace) {
          log('Error during position stream: $e\n$stackTrace');
          stopPositionStream();
        },
        cancelOnError: true);
    } catch (e, stackTrace) {
      log('Error starting position stream! (The user was probably fiddling with location.)\n'
          '$e\n$stackTrace');
      stopPositionStream();
    }
  }

  void stopPositionStream() {
    positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _position = null;
    _latlng = null;
  }

  LatLng getInitialLatLng() {
    LatLng initialLatLng = _latlng ?? _loadLatLng() ?? mercerCenter;
    _latlng = initialLatLng;
    return initialLatLng;  
  }

  Future<Position?> getCurrentPositionGL() async {
    return await isServiceStatusAndPermissionsEnabledGL(request: true)
      ? await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          forceAndroidLocationManager: true,
        )
      : null;
  }

  Future<Position?> getLastKnownPositionGL() async {
    return await isServiceStatusAndPermissionsEnabledGL(request: true)
      ? await Geolocator.getLastKnownPosition(
          forceAndroidLocationManager: true,
        )
      : null;
  }

  Future<bool> isLocationServicesAndPermissionsEnabledGL({bool request = false}) async {
    return await isLocationServicesEnabledGL() && (request
      ? await requestLocationPermissionGL()
      : await isLocationPermissionEnabledGL()
    );
  }

  // Evaluates whether the user has enabled location services on their device.
  Future<bool> isLocationServicesEnabledGL() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Evaluates whether the user has both location services and permissions enabled.
  Future<bool> isServiceStatusAndPermissionsEnabledGL({bool request = false}) async {
    return isServiceStatusEnabled() && (
      request? await requestLocationPermissionGL() : await isLocationPermissionEnabledGL()
    );
  }

  bool isServiceStatusEnabled() {
    return _serviceStatus == ServiceStatus.enabled;
  }

  bool evaluateServiceStatus(ServiceStatus? status) {
    return status == ServiceStatus.enabled;
  }

  // Checks that the user has enabled location permissions.
  Future<bool> isLocationPermissionEnabledGL() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return (permission == LocationPermission.always || permission == LocationPermission.whileInUse);
  }

  // Requests location permissions from the user.
  // TODO: Verify that openAppSettings does what I want it to (I can almost guarantee it doesn't)
  Future<bool> requestLocationPermissionGL() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _printSnackBar('Location permissions are not enabled for this instance. Please enable permissions and restart the app to use location features.');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      bool settingsOpened = await Geolocator.openAppSettings();
      if (!settingsOpened) return false;
      return isLocationPermissionEnabledGL();
    }
    return true;
  }

  // Load the user's saved position from disk.
  LatLng? _loadLatLng() {
    // Fetch saved location from disk
    Box box = Hive.box('lastKnownLocation');
    String? latitudeStr = box.get('latitude'), longitudeStr = box.get('longitude');
    // Parse strings ensuring nulls are not present. This is only needed for first time setup.
    if (latitudeStr == null || longitudeStr == null) return null;
    double latitude = double.parse(latitudeStr), longitude = double.parse(longitudeStr);
    // Construct as LatLng (no way or reason to construct as Position)
    return LatLng(latitude, longitude);
  }

  // Saves the user's position on disk so that it can be retrieved on next startup.
  void _savePosition(Position? position) {
    // Do not save null positions to disk.
    if (position == null) return;
    // Save latitude/longitude to disk (only need these)
    Box box = Hive.box('lastKnownLocation');
    box.put('latitude', '${position.latitude}');
    box.put('longitude', '${position.longitude}');
  }

  // Helper function for converting a Position to a LatLng
  LatLng? toLatLng(Position? position) {
    return (position != null)
      ? LatLng(position.latitude, position.longitude)
      : null;
  }

  // Helper function for displaying messages on the SnackBar.
  void _printSnackBar(String message) {
    scaffoldKey.currentState?.showSnackBar(
      SnackBar(content: Text(message))
    );
  }
}


class CurrentLocationMarker extends StatefulWidget {
  final bool isLocationEnabled;
  final Stream<Position?>? positionStream;

  const CurrentLocationMarker({
    super.key, 
    required this.isLocationEnabled,
    required this.positionStream,
  });

  @override
  State<CurrentLocationMarker> createState() => _CurrentLocationMarkerState();
}

class _CurrentLocationMarkerState extends State<CurrentLocationMarker> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const factory = LocationMarkerDataStreamFactory();
    return widget.isLocationEnabled
      ? CurrentLocationLayer(
          positionStream: factory.fromGeolocatorPositionStream(
            stream: widget.positionStream,
          ),
          alignPositionOnUpdate: AlignOnUpdate.never,
        )
      : const SizedBox.shrink();
  }
}
