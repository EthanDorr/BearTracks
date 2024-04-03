import 'package:flutter/material.dart'; 
import 'package:flutter/services.dart';

import 'package:bear_tracks/map.dart';
import 'login/loginscreen.dart'; // Import the LoginScreen class

//firebase 
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/*
  VERY IMPORTANT TODOS
  TODO: Include ALL licenses/attributions needed from all plugins, Mapbox, OSM, etc.
  TODO: Figure out why each user is being double-counted
*/

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 
  initBearTracks();
  runApp(const BearTracks());
}


/*
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initBearTracks();
  runApp(const BearTracks());
} */

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
} 


class BearTracks extends StatelessWidget {
  const BearTracks({super.key});
  
  @override 
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'BearTracks', 
      home: LoginScreen(),
    ); 

  }
}