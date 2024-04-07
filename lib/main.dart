import 'package:bear_tracks/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:bear_tracks/globals.dart' show rootScaffoldKey;
import 'package:bear_tracks/splash_screen.dart';

/*
  VERY IMPORTANT TODOS
  TODO: Include ALL licenses/attributions needed from all plugins, Mapbox, OSM, etc.
*/
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 
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