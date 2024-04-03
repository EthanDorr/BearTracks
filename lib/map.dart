import 'dart:async';
// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' show ServiceStatus;
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:bear_tracks/globals.dart';
import 'package:bear_tracks/gps.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key}); 

  @override
  State<MapScreen> createState() => _MapScreenState();
}


class _MapScreenState extends State<MapScreen> {
  bool _isLocationEnabled = false;
  Future<bool>? _isMapReady;
  late MapboxMap _mapboxMap;
  final GPS _gps = GPS();
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;

  /*
    CONSTRUCTION / DESTRUCTION
  */
  @override
  void initState() {
    super.initState();
    _init();
  }
  void _init() async {
    // Initialize Mapbox
    MapboxOptions.setAccessToken(const String.fromEnvironment('PRIVATE_ACCESS_TOKEN'));

    // Initialize GPS
    await _gps.init();
    bool isLocationEnabled = await _gps.isLocationServiceEnabledGL();
    _serviceStatusStreamSubscription = _gps.serviceStatusStream?.listen((serviceStatus) {
      setState(() {
        _isLocationEnabled = serviceStatus == ServiceStatus.enabled;
      });
      _isLocationEnabled? _enableLocationPuck() : _disableLocationPuck();
    });
    setState(() { // Initialize on first run
      _isLocationEnabled = isLocationEnabled;
    });

    // Done initializing - therefore the map is ready to be loaded.
    _isMapReady = Future.value(true);
  }

  @override
  void dispose() {
    _serviceStatusStreamSubscription?.cancel();
    _gps.dispose();
    _mapboxMap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _isMapReady,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || snapshot.connectionState == ConnectionState.none) {
          return const Center(
            child: CircularProgressIndicator(
              color: mercerMercerOrange,
              backgroundColor: mercerDarkGray,
            ),
          );
        }
        return SafeArea(
          child: Scaffold(
            body: MapWidget(
              key: const ValueKey('mapWidget'),
              cameraOptions: CameraOptions(
                zoom: 18.0,
              ),
              styleUri: const String.fromEnvironment('STYLE_URI'),
              onMapCreated: _onMapCreated,
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                _centerUserOnMap();
              },
              child: Icon(_isLocationEnabled? Icons.my_location_sharp : Icons.location_disabled)
            ),
          )
        );
      }
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    // Interface for accessing most mapbox features.
    _mapboxMap = mapboxMap;
    // Center the camera on whatever the user's initial position is.
    _centerCameraOnLatLng(_gps.getInitialLatLng());
    // Enable the location puck
    await _enableLocationPuck();
  }

  // Enables the location puck.
  // Checks user permissions and requests permissions if disabled.
  Future<void> _enableLocationPuck() async {
    if (!await _gps.isLocationServiceAndPermissionEnabledGL()) return;
    _mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        showAccuracyRing: true,
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
      )
    );
  }
  void _disableLocationPuck() async {
    _mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: false
      )
    );
  }

  // Center the camera on the user's current location.
  void _centerUserOnMap() async {
    if (await _gps.isLocationServiceAndPermissionEnabledGL(request: true)) {
      _centerCameraOnLatLng(_gps.latlng);
    }
  }
  // Center the camera on the provided position.
  void _centerCameraOnLatLng(LatLng? latlng) {
    if (latlng == null) return;
    _mapboxMap.setCamera(
      CameraOptions(
        center: Point(coordinates: _toPosition(latlng)).toJson()
      )
    );
  }
}

// Converts a LatLng to a MAPBOX Position.
Position _toPosition(LatLng latlng) => Position(latlng.longitude, latlng.latitude);