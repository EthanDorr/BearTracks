import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart'; 
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:bear_tracks/location.dart';
import 'package:bear_tracks/globals.dart';

class MapScreen extends StatefulWidget { 
  const MapScreen({super.key}); 
  
  @override 
  State<MapScreen> createState() => _MapScreenState(); 
} 
  
class _MapScreenState extends State<MapScreen> { 
  final MapController controller = MapController();
  GeolocationService geolocator = GeolocationService();
  late Future<LatLng> initialLatLng;

  @override
  void initState() {
    super.initState();
    initialLatLng = _getInitialLatLng();
  }

  Future<LatLng> _getInitialLatLng() async {
    try {
      Position? initialPosition = await geolocator.getCurrentPosition();
      return initialPosition != null
          ? LatLng(initialPosition.latitude, initialPosition.longitude)
          : const LatLng(32.827, -83.648); // Default starting coordinate.
    } catch (e) {
      if (kDebugMode) {
        print("Error getting initial position: $e");
      }
      return const LatLng(32.827, -83.648); // Default starting coordinate on error.
    }
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<LatLng>(
        future: _getInitialLatLng(),
        builder: (context, snapshot) {
          // While the app is loading, display a loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            // TODO: Abstract into loading screen
            return const Center(child: CircularProgressIndicator(
                color: mercerOrange,
                backgroundColor: mercerDarkGray,
            ));
          // TODO: Maybe don't display debug output in production
          // If there was an error, present it (for now)
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          // If there was no data (somehow?), present it (for now)
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data'));
          }

          LatLng initialLatLng = snapshot.data!;

          return FlutterMap( 
            mapController: controller, 
            options: MapOptions(
              initialCenter: initialLatLng, 
              minZoom: 16,
              maxZoom: 19,
              initialZoom: 18,
            ), 
            children: [
              TileLayer(
                urlTemplate: const String.fromEnvironment('PUBLIC_API_KEY'),
              ),
              CurrentLocationLayer(),
            ],
          );
        },
      ),
      backgroundColor: Colors.black,
    );
  }
} 