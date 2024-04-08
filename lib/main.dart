import 'package:flutter/material.dart';

import 'package:bear_tracks/globals.dart' show rootScaffoldKey;
import 'package:bear_tracks/splash_screen.dart';

/*
  VERY IMPORTANT TODOS
  TODO: Include ALL licenses/attributions needed from all plugins, Mapbox, OSM, etc.
  TODO: Fix all pixel values to be consistent with the size of the device.
  TODO: Fix title and splash image to not shift when switching to login page
*/
void main() async {
  runApp(const BearTracks());
}

class BearTracks extends StatelessWidget {
  const BearTracks({super.key});
  
  @override 
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldKey,
      title: 'BearTracks', 
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    ); 
  }
}