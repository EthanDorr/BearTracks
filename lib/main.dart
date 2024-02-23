import 'package:bear_tracks/globals.dart';
import 'package:bear_tracks/map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await initHive();
  runApp(const BearTracks());
}

Future<void> initHive() async {
  await Hive.initFlutter();
  await Hive.openBox('lastKnownLocation');
}

class BearTracks extends StatelessWidget {
  const BearTracks({super.key});
  
  @override 
  Widget build(BuildContext context) {
    // Hide the status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive, overlays: [SystemUiOverlay.bottom]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return MaterialApp(
      title: 'Bear Tracks', 
      home: const MapScreen(),
      scaffoldMessengerKey: scaffoldKey,
    ); 
  } 
}