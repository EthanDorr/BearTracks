import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bear_tracks/globals.dart';
import 'package:bear_tracks/map.dart';

void main() {
  runApp(const BearTracks());
}

class BearTracks extends StatelessWidget {
  const BearTracks({super.key});
  
  @override 
  Widget build(BuildContext context) {
    // Dark theme FTW
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    // Hide the status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom]);
    // I said hide it, dammit!
    SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
      if (systemOverlaysAreVisible) {
        await Future.delayed(const Duration(seconds: 3), SystemChrome.restoreSystemUIOverlays);
      }
    });

    return MaterialApp(
      title: 'BearTracks', 
      home: const MapScreen(),
      scaffoldMessengerKey: scaffoldKey,
    ); 
  } 
}
