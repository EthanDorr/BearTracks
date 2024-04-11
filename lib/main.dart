import 'package:flutter/material.dart';

import 'package:bear_tracks/globals.dart';
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
      theme: ThemeData(
        textSelectionTheme: const TextSelectionThemeData(
          selectionHandleColor: mercerMercerOrange,
        ),
        timePickerTheme: const TimePickerThemeData(
          backgroundColor: mercerBlack,
          dayPeriodColor: mercerLightGray,
          dayPeriodTextColor: mercerWhite,
          dialBackgroundColor: mercerLightGray,
          cancelButtonStyle: ButtonStyle(
            foregroundColor: MaterialStatePropertyAll(mercerMercerOrange)
          ),
          confirmButtonStyle: ButtonStyle(
            foregroundColor: MaterialStatePropertyAll(mercerMercerOrange)
          ),
          dialHandColor: mercerMercerOrange,
          dialTextColor: mercerBlack,
          hourMinuteColor: mercerLightGray,
          hourMinuteTextColor: mercerWhite,
          entryModeIconColor: mercerMercerOrange,
        )
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    ); 
  }
}