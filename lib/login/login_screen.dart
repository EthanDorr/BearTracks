import 'dart:developer';


import 'package:bear_tracks/login/student_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


import 'package:bear_tracks/globals.dart';
import 'package:bear_tracks/gps.dart';
import 'package:bear_tracks/map.dart';


class LoginScreen extends StatelessWidget {
  final bool _isLocationEnabled;
  final GPS _gps;


  const LoginScreen(this._gps, this._isLocationEnabled, {super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mercerBlack,
      body: Center(
        child: Transform.translate(
          offset: const Offset(0, -20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/mercer-spirit-block.png',
                width: 300,
                height: 300,
              ),
              const SizedBox(height: 15),
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
              const SizedBox(height: 45),
              ElevatedButton(
                onPressed: () {
                  log('Student Login pressed');
                  Navigator.push(context, MaterialPageRoute(builder: (context) => StudentLoginScreen(_gps, _isLocationEnabled)));
                },
                style: ButtonStyle(
                  padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  ),
                  backgroundColor: MaterialStateProperty.all<Color>(mercerMercerOrange),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                child: const Text(
                  'Student Login',
                  style: TextStyle(
                    color: mercerWhite,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 10), // Add some spacing between the button and "Continue as guest" text
              GestureDetector(
                onTap: () {
                  log('Continue as guest pressed');
                  Navigator.push(context, MaterialPageRoute(builder: (context) =>  MapScreen(false, _gps, _isLocationEnabled)));
                },
                child: const Text(
                  'Continue as guest',
                  style: TextStyle(
                    color: mercerWhite,
                    fontSize: 14,
                    decoration: TextDecoration.underline, // Underline to indicate it's clickable
                    decorationColor: mercerWhite, // Set underline color to white
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
