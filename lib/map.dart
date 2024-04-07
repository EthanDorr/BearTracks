import 'dart:async' show StreamSubscription, Timer;
import 'dart:convert' show json;
// ignore: unused_import
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' show ServiceStatus;
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:bear_tracks/globals.dart';
import 'package:bear_tracks/gps.dart';
import 'package:bear_tracks/nav.dart';


class MapScreen extends StatefulWidget {
  final bool _isLoggedIn, _isLocationEnabled;
  final GPS _gps;

  const MapScreen(this._isLoggedIn, this._gps, this._isLocationEnabled, {super.key}); 

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late bool _isLocationEnabled;
  late GPS _gps = GPS();
  
  bool _trackLocation = false, _trackDirection = false, _displayingLocationInformation = false;
  late MapboxMap _mapboxMap;
  late PointAnnotationManager _pointAnnotationManager;
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  Timer? _locationTimer, _directionTimer;
  ScreenCoordinate? _lastPressedCoordinate;
  Map<String, dynamic>? _geocodingResponse;
  List<Position>? _route;
  Animation<double>? _routeAnimation;
  AnimationController? _routeAnimationController;

 
  @override
  void initState() {
    super.initState();
    _isLocationEnabled = widget._isLocationEnabled;
    _gps = widget._gps;
    _init();
  }

  void _init() { 
    // Initialize Mapbox
    MapboxOptions.setAccessToken(const String.fromEnvironment('PUBLIC_ACCESS_TOKEN'));
    _serviceStatusStreamSubscription = _gps.serviceStatusStream?.listen((serviceStatus) {
      setState(() {
        _isLocationEnabled = serviceStatus == ServiceStatus.enabled;
      });
      if (_isLocationEnabled) {
        _enableLocationPuck();
      }
      else {
        _disableLocationPuck(); _stopTrackLocation(); _stopTrackDirection();
      }
    });
  }

  @override
  void dispose() {
    _serviceStatusStreamSubscription?.cancel();
    _gps.dispose();
    _pointAnnotationManager.deleteAll();
    _routeAnimationController?.dispose();
    _locationTimer?.cancel();
    _directionTimer?.cancel();
    _mapboxMap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    log('building!');
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: Container(),
          actions: const <Widget>[Text('test')], // Hide the hamburger bar for the end drawer
        ),
        body: MapWidget(
          key: const ValueKey('mapWidget'),
          cameraOptions: CameraOptions(
            zoom: zoomLevelClose,
          ),
          styleUri: widget._isLoggedIn? const String.fromEnvironment('STYLE_URI') : const String.fromEnvironment('BLANK_STYLE_URI'),
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoaded,
          onTapListener: _onTap,
          onLongTapListener: _onLongTap,
          onScrollListener: _onScroll,
        ),
        // Button that recenters the camera to the user's location.
        // Icon automatically adjusts for to accomodate the status of location services.
        floatingActionButton: MapButton(
          _trackDirection,
          _trackLocation,
          _isLocationEnabled,
          () {_stopTrackDirection(); _orientUserDirectionNorth();},
          () {_orientUserDirectionHeading(); _startTrackDirection();},
          () {_centerCameraOnUser(); _startTrackLocation();}
        ),
        // Bottom sheet displays basic location information and gives buttons for directions and routes
        bottomSheet: Container(
          color: mercerBlack,
          child: AnimatedSize(
            curve: Curves.easeOut,
            duration: Duration(milliseconds: _displayingLocationInformation? 500 : 300),
            child: LocationInformation(_geocodingResponse, _directUser, _navigateUser, _displayingLocationInformation? 150 : 0),
          )
        ),
        endDrawer: const ScheduleDisplay(),
        extendBodyBehindAppBar: true,
      ),
      onPopInvoked: (bool didPop) {
        if (scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
          scaffoldKey.currentState?.closeEndDrawer();
        }
        else {
          setState(() => _displayingLocationInformation = false);
        }
      }
    );
  }

  // GOOD
  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    // Interface for accessing most mapbox features.
    _mapboxMap = mapboxMap;
    // Create annotation manager for navigation.
    _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
  }

  // GOOD
  void _onStyleLoaded(StyleLoadedEventData data) {
    // Remove the scale bar.
    _mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    // Adjust the compass.
    _mapboxMap.compass.updateSettings(
      CompassSettings(
        marginTop: 25,
        marginRight: 25,
        clickable: false, // Can creating a confusing experience when navigating
      )
    );
    // Enable the location puck by default
    _enableLocationPuck();
    // Center the camera on whatever the user's initial position is.
    final LatLng initialLatLng = _gps.getInitialLatLng();
    _centerCameraOnLatLng(initialLatLng.latitude, initialLatLng.longitude);
    // Start tracking the user's location by default
    _startTrackLocation();
  }

  // GOOD
  // There are three use cases for tapping:
  // The first is to dismiss the location information bottom sheet.
  // The second is to pull back up an existing map marker's location information page.
  // The third is to perform the following:
  //    Center camera on the location
  //    Reverse geolocate the tapped location
  //    Place a map marker on that location
  //    Display location information
  void _onTap(ScreenCoordinate coordinate) async {
    log('tap');
    // If we are already showing information, close the bottom sheet.
    if (_displayingLocationInformation) {
      return setState(() => _displayingLocationInformation = false);
    }
    // Not displaying information - need to show something
    // Last pressed coordinate is not null -> need to calculate distance
    if (_lastPressedCoordinate != null) {
      // Calculate distance in pixels between the marker and new tap position independent of zoom level
      if (await distanceFromLastCoordinateInPixels(coordinate) < 30) {
        // If the distance is small enough (user clicked on the map marker) then display the information again.
        return setState(() => _displayingLocationInformation = true);
      }
    }
    // Clicking on the map for the first time or on a new location
    // Need to geolocate and place a marker
    _lastPressedCoordinate = coordinate;
    _centerCameraOnScreenCoordinate(coordinate);
    await _reverseGeocodeAndDisplayMarker(coordinate);
    return setState(() => _displayingLocationInformation = true);
  } // _onTap

  // GOOD
  // There are two use cases for long tapping:
  // The first, is to clear any existing map marker. This is done by long tapping on the map marker.
  // The second, is to immediately generate directions to the tapped location, if not on an existing map marker.
  // This includes the following:
  //    Reverse geocoding to gather location information
  //    Placing a marker on the location
  //    Animating the route
  //    Centering the camera on the route
  //    Displaying location information
  Future<void> _onLongTap(ScreenCoordinate coordinate) async {
    log('taaaap');
    if (_lastPressedCoordinate != null) {
      // Calculate distance in meters between the marker and new tap position. This is for clearing the map.
      if (await distanceFromLastCoordinateInPixels(coordinate) < 30) {
        // Clear any existing route.
        _routeAnimationController?.reset();
        // Remove any existing points
        _pointAnnotationManager.deleteAll();
        // Stop displaying location information (if doing so)
        if (_displayingLocationInformation) {
          setState(() => _displayingLocationInformation = false);
        }
        _lastPressedCoordinate = null;
        return;
      }
    }
    if (!await isLocationPermissionAndServiceEnabledGL(request: true)) return;
    _lastPressedCoordinate = coordinate;
    _route = await _getRoute();
    if (_route == null) return; // Getting route failed
    _centerCameraOnRoute();
    await _reverseGeocodeAndDisplayMarker(_lastPressedCoordinate!);
    await _drawRoute(_route!);
    setState(() => _displayingLocationInformation = true);
  } // _onLongTap

  // GOOD
  // Scrolling's only job is to stop tracking location and/or direction.
  void _onScroll(ScreenCoordinate coordinate) {
    log('scroll');
    _stopTrackLocation();
    _stopTrackDirection();
  }

  // GOOD
  // This function is called when the user hits the 'Directions' button
  // The precondition for this is that a map marker and location information is displayed, meaning a route may or may not be shown.
  // If a route is shown, it can be because the user long-tapped and then asked for directions (redundant).
  // If a route is not shown, it can only be because the user tapped on a location on the map. In this case, we should make the route.
  // In all cases, we should center on the route.
  Future<void> _directUser([Position? routeStart]) async {
    if (!await isLocationPermissionAndServiceEnabledGL(request: true)) return;
    if (!_isRouteDrawn()) {
      _route = await _getRoute(routeStart);
      if (_route == null) return; // Getting route failed
      _drawRoute(_route!);
    }
    _centerCameraOnRoute(routeStart);
  }

  // GOOD
  // Navigating the user means the user pressed the 'Start' button in the location information bottom sheet.
  // When this happens, a map marker has been placed, but a route may or may not exist already.
  // If the route is already drawn, do not draw it again.
  // Either way, we should center the camera on and track the user, orient their direction to be consistent with device heading,
  // and start tracking the user's device heading and periodically updating direction.
  // Additionally, get rid of the bottom sheet.
  Future<void> _navigateUser([Position? routeStart]) async {
    if (!await isLocationPermissionAndServiceEnabledGL(request: true)) return;
    setState(() => _displayingLocationInformation = false);
    if (!_isRouteDrawn()) {
      _route = await _getRoute(routeStart);
      if (_route == null) return;
      _drawRoute(_route!);
      _centerCameraOnRoute(routeStart);
      await Future.delayed(const Duration(seconds: 4));
    }
    _centerCameraOnUser(bearing: await _mapboxMap.style.getPuckDirection());
    _startTrackLocation();
    _startTrackDirection();
  }

  // GOOD
  Future<void> _reverseGeocodeAndDisplayMarker(ScreenCoordinate coordinate) async {
    // Reverse geocode
    final Map<String, dynamic>? response = await reverseGeocode(coordinate);
    if (response == null) return;
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
    setState(() => _geocodingResponse = response);
  }

  // GOOD
  Future<List<Position>?> _getRoute([Position? routeStart]) async {
    routeStart ??= await _mapboxMap.style.getPuckPosition();
    if (routeStart == null || _lastPressedCoordinate == null) return null;
    return await fetchRouteCoordinates(routeStart, latlngToPosition(screenCoordinateToLatLng(_lastPressedCoordinate!)));
  }

  // GOOD
  Future<void> _drawRoute(List<Position> polyline) async {
    final line = LineString(coordinates: polyline);
    _mapboxMap.style.styleSourceExists('source').then((bool exists) async {
      if (exists) {
        // If the source already exists, just update it
        final source = await _mapboxMap.style.getSource('source');
        (source as GeoJsonSource).updateGeoJSON(json.encode(line));
      } else {
        // Add the layer which holds the line data
        await _mapboxMap.style.addSource(GeoJsonSource(
          id: 'source',
          data: json.encode(line),
          lineMetrics: true
        ));
        // Add the layer on which the line will be drawn and customized
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
      _routeAnimationController?.stop();
      _routeAnimationController = AnimationController(
        duration: routeDrawingAnimationDuration,
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
  // A little weird logic but it is succint and works out
  bool _isRouteDrawn() {
    return !(_routeAnimationController?.isDismissed ?? true);
  }

  // GOOD
  Future<void> _startTrackLocation() async {
    if (!await isLocationPermissionAndServiceEnabledGL()) return;
    _locationTimer ??= Timer.periodic(trackLocationTimerDuration, (Timer timer) async {
      if (!await _mapboxMap.isUserAnimationInProgress()) _centerCameraOnUser();
    });
    if (!_trackLocation) {
      setState(() => _trackLocation = true);
    }
  }
  // GOOD
  void _stopTrackLocation() {
    _locationTimer?.cancel();
    _locationTimer = null;
    if (_trackLocation) {
      setState(() => _trackLocation = false);
    }
  }

  // GOOD
  Future<void> _startTrackDirection() async {
    if (!await isLocationPermissionAndServiceEnabledGL()) return;
    _directionTimer ??= Timer.periodic(trackDirectionTimerDuration, (Timer timer) async {
      _orientUserDirectionHeading();
    });
    if (!_trackDirection) {
      setState(() => _trackDirection = true);
    }
  }
  // GOOD
  void _stopTrackDirection() {
    _directionTimer?.cancel();
    _directionTimer = null;
    if (_trackDirection) {
      setState(() => _trackDirection = false);
    }
  }

  // GOOD
  Future<Uint8List> loadImageAsUint8List(String image) async {
    final ByteData bytes = await rootBundle.load('assets/$image');
    return bytes.buffer.asUint8List();
  }

  // GOOD
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
    await _mapboxMap.flyTo(
      CameraOptions(bearing: 0),
      MapAnimationOptions(duration: orientUserAnimationDuration.inMilliseconds)
    );
  }

  // GOOD
  Future<void> _orientUserDirectionHeading() async {
    await _mapboxMap.flyTo(
      CameraOptions(bearing: await _mapboxMap.style.getPuckDirection()),
      MapAnimationOptions(duration: orientUserAnimationDuration.inMilliseconds)
    );
  }

  // GOOD
  // Center the camera on the provided latitude and longitude.
  Future<void> _centerCameraOnLatLng(num? latitude, num? longitude, {double? zoom, double? bearing}) async {
    if (latitude == null || longitude == null) return;
    await _mapboxMap.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(longitude, latitude)).toJson(),
        zoom: zoom,
        bearing: bearing,
      ),
      MapAnimationOptions(
        duration: centerCameraAnimationDuration.inMilliseconds,
      ),
    );
  }

  // GOOD
  // Center the camera on the user's current location based on the positon of the location puck.
  Future<void> _centerCameraOnUser({double? zoom = zoomLevelClose, double? bearing}) async {
    if (!await isLocationPermissionAndServiceEnabledGL()) return;
    final Position? puckPosition = await _mapboxMap.style.getPuckPosition();
    if (puckPosition == null) return;
    _centerCameraOnLatLng(puckPosition.lat, puckPosition.lng, zoom: zoom, bearing: bearing);
  }

  // GOOD
  Future<void> _centerCameraOnScreenCoordinate(ScreenCoordinate coordinate, {double? zoom, double? bearing}) async {
    _stopTrackLocation();
    _stopTrackDirection();
    _centerCameraOnLatLng(coordinate.x, coordinate.y, zoom: zoom, bearing: bearing);
  }

  // GOOD
  Future<void> _centerCameraOnRoute([Position? routeStart]) async {
    routeStart ??= await _mapboxMap.style.getPuckPosition();
    if (routeStart == null || _route == null) return;
    _stopTrackLocation();
    _stopTrackDirection();
    final CameraOptions camera = await _mapboxMap.cameraForCoordinates(
      [Point(coordinates: routeStart).toJson(), ..._route!.map((e) => Point(coordinates: e).toJson()), Point(coordinates: latlngToPosition(screenCoordinateToLatLng(_lastPressedCoordinate!))).toJson()],
      MbxEdgeInsets(top: 200, left: 30, bottom: 200, right: 30),
      null,
      null
    );
    await _mapboxMap.easeTo(camera, MapAnimationOptions(duration: centerCameraAnimationDuration.inMilliseconds));
  }

  // GOOD
  Future<double> distanceFromLastCoordinateInPixels(ScreenCoordinate coordinate) async {
    return distanceBetweenGL(
      screenCoordinateToLatLng(_lastPressedCoordinate!),
      screenCoordinateToLatLng(coordinate)
    ) / await _mapboxMap.projection.getMetersPerPixelAtLatitude(
      _lastPressedCoordinate!.x,
      (await _mapboxMap.getCameraState()).zoom
    );
  }
}

// GOOD
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: mercerMercerOrange,
        backgroundColor: mercerDarkGray,
      ),
    );
  }
}

// FUNCTIONAL
// Some of the worst code I think I have written this entire project
class MapButton extends StatelessWidget {
  final bool locationEnabled, trackLocation, trackDirection;
  final VoidCallback onDirection, onLocation, onNone;

  const MapButton(
    this.trackDirection,
    this.trackLocation,
    this.locationEnabled,
    this.onDirection,
    this.onLocation,
    this.onNone,
    {super.key}
  );

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      foregroundColor: mercerMercerOrange,
      backgroundColor: mercerBlack,
      shape: const CircleBorder(
        side: BorderSide(
          color: mercerDarkGray,
          width: 4
        )
      ),
      onPressed: () {
        if (!locationEnabled) {
          isLocationPermissionAndServiceEnabledGL(request: true);
          return;
        }
        if (trackLocation) {
          trackDirection? onDirection() : onLocation();
        }
        else {
          onNone();
        }
      },
      // I do not apologize
      child: Icon(
        trackLocation ? trackDirection ? Icons.navigation : Icons.my_location : locationEnabled ? Icons.location_searching : Icons.location_disabled
      )
    );
  }
}

// GOOD
class LocationInformation extends StatelessWidget {
  final Map<String, dynamic>? response;
  final VoidCallback onDirections, onStart;
  final double height;

  const LocationInformation(this.response, this.onDirections, this.onStart, this.height, {super.key});

  @override
  Widget build(BuildContext context) {
    late String text, placeName;
    final List<dynamic>? locations = response?['features'];

    if (locations == null || locations.isEmpty) {
      text = placeName = 'Not Available';
    } else {
      text = locations[0]['text'];
      placeName = locations[0]['place_name'];
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      color: mercerBlack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, style: const TextStyle(color: mercerWhite, fontSize: 20)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(placeName, style: const TextStyle(color: mercerLightGray, fontSize: 16))
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
                  onPressed: onDirections,
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
                  onPressed: onStart,
                ),
              ]
            ),
          )
        ]
      ),
    );
  }
}

class ScheduleDisplay extends StatelessWidget {

  const ScheduleDisplay({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: mercerBlack,
      shape: const RoundedRectangleBorder(
        side: BorderSide(
          color: mercerDarkGray,
          width: 3,
        ),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(25), bottomLeft: Radius.circular(25)),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: const [
          DrawerHeader(
            decoration: BoxDecoration(
              color: mercerDarkGray,
            ),
            child: Center(
              child: Text(
                'My Schedule',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mercerMercerOrange,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                )
              ),
            ),
          ),
          ListTile(
            title: Text('1')
          ),
          ListTile(
            title: Text('2')
          )
        ]
      )
    );
  }
}

// GOOD
LatLng screenCoordinateToLatLng(ScreenCoordinate coordinate) => LatLng(coordinate.x, coordinate.y);
