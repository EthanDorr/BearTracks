import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bear_tracks/globals.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:turf/polyline.dart';

//import 'package:bear_tracks/map.dart';

// https://docs.mapbox.com/api/navigation/directions/

const String baseDirectionsWalkingURI = 'https://api.mapbox.com/directions/v5/mapbox/walking';
const String baseGeocodingURI = 'https://api.mapbox.com/geocoding/v5/mapbox.places';
const String baseTileQueryURI = 'https://api.mapbox.com/v4/{tileset_id}/tilequery/';

// Gets the user's position from the Mapbox indicator layer. GOOD.
extension PuckPosition on StyleManager {
  Future<Position?> getPuckPosition() async {
    final Layer? layer;
    try {
      layer = await getLayer(Platform.isAndroid? 'mapbox-location-indicator-layer' : 'puck');
    } catch (e, stackTrace) {
      log('Error occured when fetching mapbox puck layer. Has only happened when hot restarting.\n$e\n$stackTrace');
      return null;
    }
    final List<double?>? location = (layer as LocationIndicatorLayer).location;
    if (location == null) return null;
    return Future.value(Position(location[1]!, location[0]!));
  }
}

extension PuckDirection on StyleManager {
  Future<double?> getPuckDirection() async {
    final Layer? layer;
    try {
      layer = await getLayer(Platform.isAndroid? 'mapbox-location-indicator-layer' : 'puck');
    } catch (e, stackTrace) {
      log('Error occured when fetching mapbox puck layer. Has only happened when hot restarting.\n$e\n$stackTrace');
      return null;
    }
    final double? direction = (layer as LocationIndicatorLayer).bearing;
    return Future.value(direction);
  }
}

// ALMOST GOOD.
// Returns the raw response of a geocoding request.
Future<Map<String, dynamic>?> reverseGeocode(ScreenCoordinate coordinate) async {
  final Uri request = Uri.parse(
    '$baseGeocodingURI/${coordinate.y},${coordinate.x}.json?access_token=${const String.fromEnvironment('PUBLIC_ACCESS_TOKEN')}'
  );
  log('REVERSE GEOCODING!');
  final http.Response response = await http.get(request);
  if (response.statusCode != 200) {
    printSnackBar('An error was encountered while fetching the desired location information.');
    return null;
  }
  return jsonDecode(response.body);
}

// Future<Map<String, dynamic>> tileQuery(ScreenCoordinate coordinate) async {
//   final Uri request = Uri.parse(

//   )
// }


// NEEDS WORK
// Should just return a route and save that under the map
// Unless I want to make a navigator widget
Future<List<Position>?> fetchRouteCoordinates(Position start, Position end) async {
  final http.Response response = await fetchDirectionsWalking(start, end);
  // BAD HTTP RESPONSE
  if (response.statusCode != 200) {
    printSnackBar('An error was encountered while fetching the desired route.');
    return null;
  }
  final Map<String, dynamic> route = jsonDecode(response.body);
  // BAD MAPBOX RESPONSE
  if (route['code'] != 'Ok') {
    printSnackBar('An error was encountered while fetching the desired route.');
    return null;
  }
  return Polyline.decode(route['routes'][0]['geometry']);
}

// ALMOST GOOD, EASY FIX.
// Needs URI tuning for more advanced features.
Future<http.Response> fetchDirectionsWalking(Position start, Position end) async {
  final Uri directions = Uri.parse(
    '$baseDirectionsWalkingURI/${start.lng},${start.lat};${end.lng},${end.lat}?overview=full&access_token=${const String.fromEnvironment('PUBLIC_ACCESS_TOKEN')}'
  );
  log('FETCHING DIRECTIONS');
  return http.get(directions);
}

// GOOD
// Converts a LatLng to a MAPBOX Position.
Position latlngToPosition(LatLng latlng) => Position(latlng.longitude, latlng.latitude);
