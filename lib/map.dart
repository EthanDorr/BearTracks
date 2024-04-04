import 'dart:async';
import 'dart:convert';
// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' show ServiceStatus;
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:bear_tracks/globals.dart';
import 'package:bear_tracks/gps.dart';
import 'package:bear_tracks/nav.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key}); 

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  bool _isLocationEnabled = false, _trackLocation = true, _displayingLocationInformation = false;
  late final Future<bool> _isMapReady;
  late MapboxMap _mapboxMap;
  late PointAnnotationManager _pointAnnotationManager;
  final GPS _gps = GPS();
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  Timer? _timer;
  ScreenCoordinate? _lastPressedCoordinate;
  Map<String, dynamic>? _response;
  Animation<double>? _routeAnimation;
  AnimationController? _routeAnimationController;

 
  @override
  void initState() {
    super.initState();
    _isMapReady = _init();
  }
  Future<bool> _init() async {
    // Initialize Mapbox
    MapboxOptions.setAccessToken(const String.fromEnvironment('PUBLIC_ACCESS_TOKEN'));

    // Initialize GPS
    await _gps.init();
    _serviceStatusStreamSubscription = _gps.serviceStatusStream?.listen((serviceStatus) {
      setState(() {
        _isLocationEnabled = serviceStatus == ServiceStatus.enabled;
      });
      _isLocationEnabled? _enableLocationPuck() : _disableLocationPuck();
    });
    _isLocationEnabled = await isLocationServiceEnabledGL();

    // Done initializing - therefore the map is ready to be loaded.
    return true;
  }

  @override
  void dispose() {
    _serviceStatusStreamSubscription?.cancel();
    _gps.dispose();
    _pointAnnotationManager.deleteAll();
    _routeAnimationController?.dispose();
    _timer?.cancel();
    _mapboxMap.dispose();
    super.dispose();
  }

  void rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    log('building!!!');
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
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
          ),
          body: Stack(
            children: [
              MapWidget(
                key: const ValueKey('mapWidget'),
                cameraOptions: CameraOptions(
                  zoom: zoomLevelClose,
                ),
                styleUri: const String.fromEnvironment('STYLE_URI'),
                onMapCreated: _onMapCreated,
                onStyleLoadedListener: _onStyleLoaded,
                onTapListener: _onTap,
                onLongTapListener: _onLongTap,
                onScrollListener: _onScroll,
              ),
            ],
          ),
          // Button that recenters the camera to the user's location.
          // Icon automatically adjusts for to accomodate the status of location services.
          floatingActionButton: FloatingActionButton(
            foregroundColor: mercerMercerOrange,
            backgroundColor: mercerDarkGray,
            heroTag: null,
            shape: const CircleBorder(side: BorderSide(
              color: mercerMercerOrange,
              width: 2
            )),
            onPressed: _trackLocation? _orientUserDirectionNorth : () {_centerCameraOnUser(); _startTrackLocation();},
            child: Icon(
              _trackLocation? Icons.my_location : _isLocationEnabled? Icons.location_searching : Icons.location_disabled
            )
          ),
          // Bottom sheet displays basic location information and gives buttons for directions and routes
          bottomSheet: _displayLocationInformation(),
          extendBodyBehindAppBar: true,
        );
      }
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    // Interface for accessing most mapbox features.
    _mapboxMap = mapboxMap;
    // Create annotation manager for navigation.
    _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
  }

  void _onStyleLoaded(StyleLoadedEventData data) {
    // Remove the scale bar.
    _mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    //_mapboxMap.compass.updateSettings(CompassSettings())
    // Enable the location puck
    _enableLocationPuck();
    // Center the camera on whatever the user's initial position is.
    final LatLng initialLatLng = _gps.getInitialLatLng();
    _centerCameraOnLatLng(initialLatLng.latitude, initialLatLng.longitude);
    // Start tracking the user's location by default
    _startTrackLocation();
  }

  // This sucks but I think it's sound
  void _onTap(ScreenCoordinate coordinate) async {
    log('tap');
    // If we are already showing information, close the bottom sheet.
    if (_displayingLocationInformation) return setState(() => _displayingLocationInformation = false);
  
    // Not displaying information - need to show something
    // Last pressed coordinate is not null -> need to calculate distance
    if (_lastPressedCoordinate != null) {
      if (
        // Calculate distance in pixels between the marker and new tap position independent of zoom level
        distanceBetweenGL(screenCoordinateToLatLng(_lastPressedCoordinate!), screenCoordinateToLatLng(coordinate)) /
        await _mapboxMap.projection.getMetersPerPixelAtLatitude(_lastPressedCoordinate!.x, (await _mapboxMap.getCameraState()).zoom) < 30
      ) {
        // If the distance is small enough (user clicked on the map marker) then display the information again.
        return setState(() => _displayingLocationInformation = true);
      }
    }
    // Clicking on the map for the first time or on a new location
    // Need to geolocate and place a marker
    _lastPressedCoordinate = coordinate;
    _centerCameraOnMarker(coordinate);
    await _reverseGeocodeAndDisplayMarker(coordinate);
    setState(() => _displayingLocationInformation = true);
  }
  Future<void> _onLongTap(ScreenCoordinate coordinate) async {
    log('taaaap');
    if (!await isLocationServiceAndPermissionEnabledGL(request: true)) return;

    final Position? routeStart = (await _mapboxMap.style.getPuckPosition());
    if (routeStart == null) return;
    final List<Position> coordinates = await fetchRouteCoordinates(routeStart, latlngToPosition(screenCoordinateToLatLng(coordinate)));
    await _reverseGeocodeAndDisplayMarker(coordinate);
    await _centerCameraOnRoute(coordinates, routeStart);
    setState(() => _displayingLocationInformation = true);
    _drawRoute(coordinates);
  }
  void _onScroll(ScreenCoordinate coordinate) {
    log('scroll');
    _stopTrackLocation();
  }

  Future<void> _reverseGeocodeAndDisplayMarker(ScreenCoordinate coordinate) async {
    // Clear any existing route.
    _routeAnimationController?.reset();
    // Remove any existing points
    _pointAnnotationManager.deleteAll();
    // Create a new point on the tapped location
    _pointAnnotationManager.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: latlngToPosition(screenCoordinateToLatLng(coordinate))).toJson(),
        image: await loadImageAsUint8List('map-marker.png'),
        iconAnchor: IconAnchor.BOTTOM,
        iconSize: 0.5,
      )
    );
    // Reverse geocode
    final Map<String, dynamic> response = await reverseGeocode(coordinate);
    setState(() => _response = response);
  }
  

  // Probably not the correct way to handle this
  Widget _displayLocationInformation() {
    if (_response == null || !_displayingLocationInformation) return const SizedBox.shrink(); 
    final Map<String, dynamic> location = _response!['features'][0];
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      color: mercerBlack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(location['text'], style: const TextStyle(color: mercerWhite, fontSize: 20)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(location['place_name'], style: const TextStyle(color: mercerLightGray, fontSize: 16))
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.directions_walk),
                  label: const Text('Directions', style: TextStyle(color: mercerBlack)),
                  style: const ButtonStyle(
                    iconColor: MaterialStatePropertyAll(mercerBlack),
                    backgroundColor: MaterialStatePropertyAll(mercerMercerOrange)
                  ),
                  onPressed: (() {})
                ),
                const SizedBox(width: 50),
                ElevatedButton.icon(
                  icon: const Icon(Icons.navigation),
                  label: const Text('Start', style: TextStyle(color: mercerMercerOrange)),
                  style: const ButtonStyle(
                    iconColor: MaterialStatePropertyAll(mercerMercerOrange),
                    backgroundColor: MaterialStatePropertyAll(mercerBlack),
                    side: MaterialStatePropertyAll(BorderSide(color: mercerLightGray))
                  ),
                  onPressed: (() {})
                )
              ]
            ),
          )
        ]
      ),
    );
  }

  Future<void> _drawRoute(List<Position> polyline) async {
    final line = LineString(coordinates: polyline);

    _mapboxMap.style.styleSourceExists('source').then((exists) async {
      if (exists) {
        // If the source already exists, just update
        final source = await _mapboxMap.style.getSource('source');
        (source as GeoJsonSource).updateGeoJSON(json.encode(line));
      } else {
        // Add the layer which holds the line data
        await _mapboxMap.style.addSource(GeoJsonSource(
          id: 'source',
          data: json.encode(line),
          lineMetrics: true
        ));
        // Add layer on which the line will be drawn and customized
        await _mapboxMap.style.addLayer(LineLayer(
          id: 'layer',
          sourceId: 'source',
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
          lineWidth: 3,
        ));
      }
      final lineLayer = await _mapboxMap.style.getLayer('layer') as LineLayer;
      _mapboxMap.style.setStyleLayerProperty('layer', 'line-color', '["rgb",247,104,0]');
      // Animate route
      _routeAnimationController?.stop();
      _routeAnimationController = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this
      );
      _routeAnimation = Tween<double>(begin: 0, end: 1.0).animate(_routeAnimationController!)
        ..addListener(() async {
          // Increment the length of the path
          lineLayer.lineTrimOffset = [_routeAnimation?.value, 1.0];
          _mapboxMap.style.updateLayer(lineLayer);
        });
      _routeAnimationController?.forward();
    });
  }

  // GOOD
  Future<void> _startTrackLocation() async {
    if (!await isLocationServiceAndPermissionEnabledGL(request: true)) return;
    _timer ??= Timer.periodic(const Duration(milliseconds: 2000), (Timer timer) async {
      if (!await _mapboxMap.isUserAnimationInProgress()) _centerCameraOnUser();
    });
    if (!_trackLocation) {
      setState(() => _trackLocation = true);
    }
  }
  // GOOD
  void _stopTrackLocation() {
    _timer?.cancel();
    _timer = null;
    if (_trackLocation) {
      setState(() => _trackLocation = false);
    }
  }

  // GOOD
  Future<Uint8List> loadImageAsUint8List(String image) async {
    final ByteData bytes = await rootBundle.load('assets/$image');
    return bytes.buffer.asUint8List();
  }

  // Enables the location puck. GOOD
  Future<void> _enableLocationPuck() async {
    _mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingColor: mercerLightGrayLowOpacity.value,
        showAccuracyRing: true,
        accuracyRingColor: mercerLighterGrayLowOpacity.value,
        accuracyRingBorderColor: mercerLighterGray.value,
        puckBearingEnabled: true,
        puckBearing: PuckBearing.HEADING,
        locationPuck: LocationPuck(
          locationPuck2D: DefaultLocationPuck2D(
            topImage: await loadImageAsUint8List('puck-top-image.png'),
            bearingImage: await loadImageAsUint8List('puck-bearing-image.png'),
            shadowImage: await loadImageAsUint8List('puck-shadow-image.png'),
          )
        )
      )
    );
  }
  // GOOD
  void _disableLocationPuck() => _mapboxMap.location.updateSettings(LocationComponentSettings(enabled: false));

  // GOOD
  Future<void> _orientUserDirectionNorth() async {
    await _mapboxMap.flyTo(CameraOptions(bearing: 0), MapAnimationOptions(duration: 500, startDelay: 100));
  }

  // Center the camera on the provided latitude and longitude. GOOD
  Future<void> _centerCameraOnLatLng(num? latitude, num? longitude, [double? zoom]) async {
    if (latitude == null || longitude == null) return;
    _mapboxMap.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(longitude, latitude)).toJson(),
        zoom: zoom,
      ),
      MapAnimationOptions(
        duration: 1500,
      ),
    );
  }

  // Center the camera on the user's current location based on the positon of the location puck. GOOD
  Future<void> _centerCameraOnUser() async {
    if (!await isLocationServiceAndPermissionEnabledGL(request: true)) return;
    final Position? puckPosition = await _mapboxMap.style.getPuckPosition();
    if (puckPosition == null) return;
    _centerCameraOnLatLng(puckPosition.lat, puckPosition.lng, zoomLevelClose);
  }
  // GOOD
  Future<void> _centerCameraOnMarker(ScreenCoordinate coordinate) async {
    _stopTrackLocation();
    _centerCameraOnLatLng(coordinate.x, coordinate.y);
  }
  // GOOD
  Future<void> _centerCameraOnRoute(List<Position> coordinates, Position routeStart) async {
    _stopTrackLocation();
    final CameraOptions camera = await _mapboxMap.cameraForCoordinates(
      [...coordinates.map((e) => Point(coordinates: e).toJson()), Point(coordinates: routeStart).toJson()],
      MbxEdgeInsets(top: 200, left: 20, bottom: 200, right: 20),
      null,
      null
    );
    _mapboxMap.easeTo(camera, MapAnimationOptions(duration: 1500));
  }
}
// GOOD
LatLng screenCoordinateToLatLng(ScreenCoordinate coordinate) => LatLng(coordinate.x, coordinate.y);
