import 'dart:async' show Timer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bear_tracks/firebase_options.dart';
import 'package:bear_tracks/gps.dart';
import 'package:bear_tracks/globals.dart';
import 'package:bear_tracks/login/login_screen.dart';
import 'package:bear_tracks/map.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  bool? _isLocationEnabled;
  Future<bool>? _isAppReady;
  final GPS _gps = GPS();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _initBearTracks();
    await _initMapScreen();
    _timer = Timer(const Duration(seconds: 3), () {
      setState(() { _isAppReady = Future.sync(() => Future.value(true)); });
    });
  }

  Future<void> _initBearTracks() async {
    // Enable dark theme
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    // Hide the status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
      if (systemOverlaysAreVisible) {
        await Future.delayed(const Duration(seconds: 3), SystemChrome.restoreSystemUIOverlays);
      }
    });
    // Hopefully fix app to work in landscape mode. Main offender: location information display. For now, portrait only.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // Initialize shared preferences
    await initSharedPreferences();
    // Initialize firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ); 
  }

  Future<void> _initMapScreen() async {
    // Initialize GPS
    await _gps.init();
    // Initialize whether user has location services turned on - will affect icons when app is initially built
    _isLocationEnabled = await isLocationServiceEnabledGL();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _isAppReady,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || snapshot.connectionState == ConnectionState.none) {
          return const SplashImage();
        }
        //return MapScreen(true, _gps, _isLocationEnabled!);
        return (FirebaseAuth.instance.currentUser != null)? MapScreen(true, _gps, _isLocationEnabled!) : LoginScreen(_gps, _isLocationEnabled!);
      }
    );
  }
}

class SplashImage extends StatelessWidget {
  const SplashImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mercerBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            
            Image.asset(
              'assets/mercer-spirit-block.png',
              width: 300,
              height: 336,
            ),
        
            Text(
              'BearTracks',
              style: GoogleFonts.caveat(
                textStyle: const TextStyle(
                  fontSize: 72,
                  color: mercerMercerOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
