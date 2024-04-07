// ignore_for_file: unused_import

import 'dart:developer' show log;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:bear_tracks/globals.dart';
import 'package:bear_tracks/gps.dart';
import 'package:bear_tracks/login/account_logic.dart';
import 'package:bear_tracks/login/student_login_screen.dart';

class Verification extends StatelessWidget {
  final bool _isLocationEnabled;
  final GPS _gps;
  final String verificationType;
  final String email;
  const Verification(
    this._gps,
    this._isLocationEnabled,
    {
      super.key,
      required this.verificationType,
      this.email = ''
    }
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mercerBlack, // Set background color to gray
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Set app bar background color to transparent
        elevation: 0, // Remove app bar elevation
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 30,
            ),
          onPressed: () {
            log('Back button pressed');
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/mercer-spirit-block.png',
                width: 250,
                height: 250,
              ),

              const SizedBox(height: 80.0),

              const Text(
                'Please check your email for a verification link. This may take a few minutes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.white),
                
              ),

              const SizedBox(height: 60.0),

              ElevatedButton(
                onPressed: () {
                    //User? user = FirebaseAuth.instance.currentUser;

                    if(verificationType == 'email')
                    {
                      sendVerification();
                    }
                    else if (verificationType == 'password') {
                      resetPassword(email);
                    }
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(mercerMercerOrange),
                ),
                child: const Text(
                  'Resend Verification',
                  style: TextStyle(
                    color: mercerBlack
                  ),
                  ),
              ),

              const SizedBox(height: 10.0), // Add spacing between buttons

              ElevatedButton(
                onPressed: () {
                  // Navigate back to sign in screen or any other desired action
                  Navigator.push(context, MaterialPageRoute(builder: (context) => StudentLoginScreen(_gps, _isLocationEnabled)));
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(mercerMercerOrange),
                ),
                child: const Text(
                  'Continue to Sign In',
                  style: TextStyle(
                    color: mercerBlack
                  ),
                  ),
              ),
              const SizedBox(height: 120.0),
            ],
          ),
        ),
      ),
    );
  }
}
