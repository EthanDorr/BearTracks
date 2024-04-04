import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// TODO: Refactor to remove. Currently only used by permissions manager in GPS
final GlobalKey<ScaffoldMessengerState> scaffoldKey = GlobalKey<ScaffoldMessengerState>();


// Mercer Orange
const Color mercerMercerOrange = Color.fromARGB(255, 247, 104, 000);

// Blacks and Grays
const Color mercerBlack = Color.fromARGB(255, 34, 34, 34);
const Color mercerDarkGray = Color.fromARGB(255, 63, 63, 65);
const Color mercerGray = Color.fromARGB(255, 103, 103, 103);
const Color mercerLightGray = Color.fromARGB(255, 153, 153, 153);
const Color mercerLighterGray = Color.fromARGB(255, 245, 245, 245);
const Color mercerWhite = Color.fromARGB(255, 255, 255, 255);

const Color mercerLightGrayLowOpacity = Color.fromARGB(100, 153, 153, 153);
const Color mercerLighterGrayLowOpacity = Color.fromARGB(100, 245, 245, 245);

// Secondary
const Color mercerRed = Color.fromARGB(255, 249, 49, 74);
const Color mercerBlue = Color.fromARGB(255, 34, 151, 208);
const Color mercerMustard = Color.fromARGB(255, 203, 192, 44);
const Color mercerPurple = Color.fromARGB(255, 136, 80, 248);
const Color mercerTeal = Color.fromARGB(255, 20, 130, 104);
const Color mercerMoss = Color.fromARGB(255, 176, 160, 23);
const Color mercerRoyal = Color.fromARGB(255, 40, 56, 131);
const Color mercerGreen = Color.fromARGB(255, 109, 182, 68);
const Color mercerBeige = Color.fromARGB(255, 235, 220, 182);


// Notable Coordinates
const LatLng mercerCenter = LatLng(32.8285, -83.6497);


// Map Stuff
const double zoomLevelClose = 16.5;