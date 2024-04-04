import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

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
    final location = (layer as LocationIndicatorLayer).location;
    if (location == null) return null;
    return Future.value(Position(location[1]!, location[0]!));
  }
}

// Converts a LatLng to a MAPBOX Position. GOOD
Position latlngToPosition(LatLng latlng) => Position(latlng.longitude, latlng.latitude);

// Returns the raw response of a geocoding request. ALMOST GOOD.
// TODO: Handle HTTP errors
Future<Map<String, dynamic>> reverseGeocode(ScreenCoordinate coordinate) async {
  final Uri request = Uri.parse(
    '$baseGeocodingURI/${coordinate.y},${coordinate.x}.json?access_token=${const String.fromEnvironment('PUBLIC_ACCESS_TOKEN')}'
  );
  log('REVERSE GEOCODING!');
  return jsonDecode((await http.get(request)).body);
}

// Future<Map<String, dynamic>> tileQuery(ScreenCoordinate coordinate) async {
//   final Uri request = Uri.parse(

//   )
// }


// NEEDS WORK
// Should just return a route and save that under the map
// Unless I want to make a navigator widget
// TODO: If walking directions are not available (too big of a route) we need to alert the user and not crash
Future<List<Position>> fetchRouteCoordinates(Position start, Position end) async {
  final http.Response response = await fetchDirectionsWalking(start, end);
  final Map<String, dynamic> route = jsonDecode(response.body);
  return Polyline.decode(route['routes'][0]['geometry']);
}

// NEEDS URI TUNING. ALMOST GOOD, EASY FIX.
Future<http.Response> fetchDirectionsWalking(Position start, Position end) async {
  final Uri directions = Uri.parse(
    '$baseDirectionsWalkingURI/${start.lng},${start.lat};${end.lng},${end.lat}?overview=full&access_token=${const String.fromEnvironment('PUBLIC_ACCESS_TOKEN')}'
  );
  log('FETCHING DIRECTIONS');
  return http.get(directions);
}
