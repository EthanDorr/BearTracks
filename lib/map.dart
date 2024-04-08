import 'dart:async' show StreamSubscription, Timer;
import 'dart:convert' show json;
// ignore: unused_import
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' show ServiceStatus;
import 'package:google_fonts/google_fonts.dart';
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

  late List<ScheduleEntry> schedule;


  @override
  void initState() {
    super.initState();
    _isLocationEnabled = widget._isLocationEnabled;
    _gps = widget._gps;
    schedule = _loadSchedule() ?? [];
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
      onPopInvoked: (bool didPop) {
        if (scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
          scaffoldKey.currentState?.closeEndDrawer();
        } else { setState(() => _displayingLocationInformation = false); }
      },
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: Container(),
          actions: <Widget>[Container()], // Hide the hamburger bar for the end drawer
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
        floatingActionButton: FittedBox(
          child: AnimatedSwitcher(
            duration: locationInfoTransitionInDuration,
            reverseDuration: locationInfoTransitionOutDuration,
            transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(scale: animation, child: child),
            child: Flex(
              key: ValueKey(_displayingLocationInformation),
              direction: _displayingLocationInformation? Axis.horizontal : Axis.vertical,
              children: <Widget>[
                if (widget._isLoggedIn) const ScheduleButton(),
                const SizedBox.square(dimension: 10),
                // Button that recenters the camera to the user's location.
                // Icon automatically adjusts to accomodate the status of location services.
                MapButton(
                  _trackDirection,
                  _trackLocation,
                  _isLocationEnabled,
                  () {_stopTrackDirection(); _orientUserDirectionNorth();},
                  () {_orientUserDirectionHeading(); _startTrackDirection();},
                  () {_centerCameraOnUser(); _startTrackLocation();}
                ),
              ]
            ),
          )
        ),
        // Bottom sheet displays basic location information and gives buttons for directions and routes
        bottomSheet: Container(
          color: mercerBlack,
          child: AnimatedSize(
            curve: Curves.easeOut,
            duration: _displayingLocationInformation? locationInfoTransitionInDuration : locationInfoTransitionOutDuration,
            child: LocationInformation(_geocodingResponse, _directUser, _navigateUser, _displayingLocationInformation? 150 : 0),
          )
        ),
        endDrawer: widget._isLoggedIn? ScheduleDisplay(schedule, _onUpdateEntry) : null,
        onEndDrawerChanged: (bool isOpened) {
          if (!isOpened) _saveSchedule();
        },
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
      ),
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
    // Adjust the attribution.
    _mapboxMap.attribution.updateSettings(
      AttributionSettings(
        marginBottom: 15,
        marginLeft: 100,
      )
    );
    // Adjust the logo.
    _mapboxMap.logo.updateSettings(
      LogoSettings(
        marginBottom: 15,
        marginLeft: 15,
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
      if (await _distanceFromLastCoordinateInPixels(coordinate) < 30) {
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
      if (await _distanceFromLastCoordinateInPixels(coordinate) < 30) {
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
  Future<double> _distanceFromLastCoordinateInPixels(ScreenCoordinate coordinate) async {
    return distanceBetweenGL(
      screenCoordinateToLatLng(_lastPressedCoordinate!),
      screenCoordinateToLatLng(coordinate)
    ) / await _mapboxMap.projection.getMetersPerPixelAtLatitude(
      _lastPressedCoordinate!.x,
      (await _mapboxMap.getCameraState()).zoom
    );
  }

  // GOOD (tentatively)
  void _saveSchedule() async {
    // Already been initialized in splash screen - should be instant
    prefs.setString('schedule', json.encode([...schedule.map((entry) => entry.toJson())]));
  }

  // GOOD (tentatively)
  List<ScheduleEntry>? _loadSchedule() {
    // Already been initialized in splash screen - should be instant
    final String? scheduleString = prefs.getString('schedule');
    if (scheduleString == null) return null;
    final List<dynamic> loadedSchedule = json.decode(scheduleString);
    return loadedSchedule.map((entry) => ScheduleEntry.fromJson((){}, entry)).toList();
  }

  // GOOD (tentatively)
  void _onUpdateEntry(List<ScheduleEntry> newSchedule) {
    schedule.sort((a,b) => timeOfDayInMinutes(a.startTime) - timeOfDayInMinutes(b.startTime));
    setState(() => schedule = newSchedule);
    _saveSchedule();
  }

  // GOOD
  int timeOfDayInMinutes(TimeOfDay? time) {
    if (time == null) return 1440; // Should be the limit
    return 60 * time.hour + time.minute;
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
      heroTag: null,
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
class ScheduleButton extends StatelessWidget {
  const ScheduleButton({super.key,});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: null,
      foregroundColor: mercerMercerOrange,
      backgroundColor: mercerBlack,
      shape: const CircleBorder(
        side: BorderSide(
          color: mercerDarkGray,
          width: 4
        )
      ),
      child: const Icon(Icons.book),
      onPressed: () => scaffoldKey.currentState?.openEndDrawer()
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
      // TODO: Fix this Band-Aid
      text = locations[0]['text'].replaceAll('Willett', 'Willet');
      placeName = locations[0]['place_name'].replaceAll('Willett', 'Willet');
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


class ScheduleDisplay extends StatefulWidget {
  final Function(List<ScheduleEntry>) onUpdate;
  final List<ScheduleEntry>? initialSchedule;

  const ScheduleDisplay(this.initialSchedule, this.onUpdate, {super.key});

  @override
  ScheduleDisplayState createState() => ScheduleDisplayState();
}

class ScheduleDisplayState extends State<ScheduleDisplay> {
  late List<ScheduleEntry> schedule;

  @override
  void initState() {
    super.initState();
    schedule = widget.initialSchedule ?? [];
    for (ScheduleEntry entry in schedule) {
      entry.onUpdate = _updateEntry;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * .9,
      backgroundColor: mercerDarkGray,
      shape: const RoundedRectangleBorder(
        side: BorderSide(
          color: mercerBlack,
          width: 3,
        ),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: mercerBlack,
            ),
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Schedule',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: mercerMercerOrange,
                    fontWeight: FontWeight.bold,
                  )
                ),
              ),
            ),
          ),
          ...schedule.map(
            (entry) => Dismissible(
              key: ObjectKey(entry),
              child: entry.build(context),
              onDismissed: (direction) {
                final objectKey = ObjectKey(entry);
                final index = schedule.indexWhere((entry) => ObjectKey(entry) == objectKey);
                schedule.removeAt(index);
                _updateEntry();
              }
            )
          ),
          Center(
            child: IconButton(
              color: mercerMercerOrange,
              iconSize: MediaQuery.of(context).size.width * 0.1,
              onPressed: () {
                final ScheduleEntry newEntry = ScheduleEntry(_updateEntry, null, null, null);
                schedule.add(newEntry);
                _updateEntry();
              },
              style: const ButtonStyle(
                iconColor: MaterialStatePropertyAll(mercerMercerOrange),
                backgroundColor: MaterialStatePropertyAll(mercerBlack),
                shape: MaterialStatePropertyAll(CircleBorder()),
              ),
              icon: const Icon(Icons.add)
            ),
          )
        ],
      )
    );
  }

  void _updateEntry() {
    widget.onUpdate(schedule);
  }
}

class ScheduleEntry {
  String? description;
  BuildingCode? buildingCode;
  TimeOfDay? startTime;
  VoidCallback? onUpdate;
  final TextEditingController _buildingDescriptionController = TextEditingController();
  final TextEditingController _buildingCodeController = TextEditingController();

  ScheduleEntry(this.onUpdate, this.description, this.buildingCode, this.startTime);

  ScheduleEntry.fromJson(this.onUpdate, Map<String, dynamic> m) {
    ScheduleEntry(
      onUpdate = onUpdate,
      description = m['description'],
      buildingCode = (m['code'] != null)? BuildingCode.values.byName(m['code'].toString().toLowerCase()) : null,
      startTime = (m['hour'] != null && m['minute'] != null)? TimeOfDay(hour: m['hour'], minute: m['minute']) : null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'code': buildingCode?.code,
      'hour': startTime?.hour,
      'minute': startTime?.minute
    };
  }

  @override
  String toString({DiagnosticLevel? minLevel}) {
    return '$description\n${buildingCode?.code}\n${startTime.toString()}';
  }

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: mercerBlack,
          borderRadius: BorderRadius.all(Radius.circular(25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.13,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                TextField(
                  controller: _buildingDescriptionController,
                  decoration: InputDecoration(
                    hintText: description ?? 'Description',
                    hintStyle: const TextStyle(color: mercerBlack),
                    filled: true,
                    fillColor: mercerWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none, 
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    description = value;
                    onUpdate!();
                  },
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.01),

                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.05,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      FittedBox(
                        child: DropdownMenu<BuildingCode>(
                          width: MediaQuery.of(context).size.width * 0.45,
                          controller: _buildingCodeController,
                          hintText: buildingCode?.code,
                          inputDecorationTheme: const InputDecorationTheme(
                            hintStyle: TextStyle(
                              color: mercerMercerOrange,
                            ),
                          ),
                          onSelected: (BuildingCode? building) {
                            buildingCode = building;
                            onUpdate!();
                          },
                          textStyle: const TextStyle(
                            color: mercerMercerOrange,
                          ),
                          trailingIcon: const Icon(
                            Icons.arrow_drop_down,
                            color: mercerMercerOrange),
                          menuHeight: MediaQuery.of(context).size.height * 0.4,
                          dropdownMenuEntries: BuildingCode.values
                            .map<DropdownMenuEntry<BuildingCode>>(
                              (BuildingCode building) {
                                return DropdownMenuEntry<BuildingCode>(
                                  value: building,
                                  label: '${building.code} - ${building.name}',
                                );
                              }).toList(),
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.access_time,
                          color: mercerMercerOrange
                        ),
                        label: Text(
                          startTime?.format(context) ?? 'Select Time',
                          style: const TextStyle(
                            color: mercerMercerOrange,
                          )
                        ),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(mercerBlack),
                        ),
                        onPressed: () async {
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: startTime ?? TimeOfDay.now(),
                            initialEntryMode: TimePickerEntryMode.dial,
                          );
                          if (time != null) startTime = time;
                          onUpdate!();
                        },
                      )
                    ],
                  ),
                ),
              ]
            ),
          ),
        ),
      ),
    );
  }
}

enum BuildingCode {
  arc('ARC', 'Academic Resource Center',            LatLng(32.83152980139905, -83.64926525788182)),
  ccj('CCJ', 'Center for Collaborative Journalism', LatLng(32.83293062158662, -83.65130895001977)),
  csc('CSC', 'Connell Student Center',              LatLng(32.83064005782506, -83.64888414995121)),
  egc('EGC', 'Engineering & Classroom Building',    LatLng(32.82722560722719, -83.64876435342445)),
  grv('GRV', 'Groover Hall',                        LatLng(32.83133473499917, -83.64893652668052)),
  gsc('GSC', 'Godsey Science Center',               LatLng(32.82879002171659, -83.64868700333554)),
  har('HAR', 'Hardman Hall',                        LatLng(32.831979004903324, -83.649556329766)),
  knt('KNT', 'Knight Hall',                         LatLng(32.83149387388999, -83.64785200025678)),
  lan('LAN', 'Langdale Building',                   LatLng(32.83129992104122, -83.64941040025674)),
  md( 'MD',  'Medical School Building',             LatLng(32.82783831553583, -83.64766060780819)),
  mic('MIC', 'Macon Innovation Center',             LatLng(32.82798094297596, -83.64981096223143)),
  mub('MUB', 'McCorkle Music Building',             LatLng(32.832367349734724, -83.65005181804787)),
  nwt('NWT', 'Newton Hall',                         LatLng(32.832340287489274, -83.64910406772253)),
  pen('PEN', 'Penfield Hall',                       LatLng(32.829808518623636, -83.64894291338351)),
  ryl('RYL', 'Ryals Building',                      LatLng(32.831527698416885, -83.64926490333576)),
  seb('SEB', 'Science and Engineering Building',    LatLng(32.827667444132636, -83.64949467450046)),
  stn('STN', 'Stetson Hall',                        LatLng(32.82964965696205, -83.65004877757303)),
  tca('TCA', 'Tattnall Square Center for the Arts', LatLng(32.83367487237864, -83.64412161068418)),
  tnc('TNC', 'Tennis Courts',                       LatLng(32.83347200926262, -83.64595088020833)),
  tvr('TVR', 'Tarver Library',                      LatLng(32.82908637478062, -83.64929317011982)),
  unc('UNC', 'University Center',                   LatLng(32.82946492358933, -83.6514626720755)),
  wae('WAE', 'Ware Hall',                           LatLng(32.83107970647383, -83.64849475980648)),
  wgs('WGS', 'Wiggs Hall',                          LatLng(32.830831759849524, -83.64795858555352)),
  whm('WHM', 'Willingham Chapel',                   LatLng(32.8320778811188, -83.64878926467448)),
  wsc('WSC', 'Willet Science Center',               LatLng(32.828486664390915, -83.6497638291515));

  const BuildingCode(this.code, this.name, this.latlng);
  final String code;
  final String name;
  final LatLng latlng;
}

// GOOD
LatLng screenCoordinateToLatLng(ScreenCoordinate coordinate) => LatLng(coordinate.x, coordinate.y);
