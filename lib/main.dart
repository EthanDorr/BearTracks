import 'package:flutter/material.dart';
 
import 'package:bear_tracks/globals.dart';
import 'package:bear_tracks/map.dart';

void main() => runApp(const MyApp()); 

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override 
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Bear Tracks", 
      debugShowCheckedModeBanner: false, 
      home: const MapScreen(),
      scaffoldMessengerKey: scaffoldKey,
    ); 
  } 
}
