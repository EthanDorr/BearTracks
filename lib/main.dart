import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bear_tracks/map.dart';

/*
  VERY IMPORTANT TODOS
  TODO: Include ALL licenses/attributions needed from all plugins, Mapbox, OSM, etc.
  TODO: Ensure use of Geolocator position stream only for saving location to disk/fetching initial location 
  TODO: HANDLE ERRORS ON HTTP REQUESTS
*/
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initBearTracks();
  runApp(const BearTracks());
}

void initBearTracks() {
  // Enable dark theme
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  // Hide the status bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom]);
  SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
    if (systemOverlaysAreVisible) {
      await Future.delayed(const Duration(seconds: 3), SystemChrome.restoreSystemUIOverlays);
    }
  });
  // TODO: Hopefully fix app to work in landscape mode. Main offender: location information display. For now, portrait only.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

class BearTracks extends StatelessWidget {
  const BearTracks({super.key});
  
  @override 
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'BearTracks', 
      home: MapScreen(),
      debugShowCheckedModeBanner: false,
    ); 
  }
}