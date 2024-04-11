// ignore_for_file: unused_import

import 'dart:developer' show log;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bear_tracks/globals.dart';
import 'package:bear_tracks/gps.dart';
import 'package:bear_tracks/login/account_logic.dart';
import 'package:bear_tracks/login/verification.dart';

class PasswordResetScreen extends StatelessWidget {
  final bool _isLocationEnabled;
  final GPS _gps;

  const PasswordResetScreen(this._gps, this._isLocationEnabled, {super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    return Scaffold(
      backgroundColor: mercerBlack, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: mercerWhite,
            size: 30,
            ),
          onPressed: () {
            log('Back button pressed');
            Navigator.pop(context); 
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 30), 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: mercerMercerOrange, 
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Reset Password',
                      style: GoogleFonts.poppins(
                        color: mercerWhite,
                        fontSize: 35,
                        fontWeight: FontWeight.bold,

                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 110),
                SizedBox(
                  width: 300, 
                  child: TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: 'Enter Mercer ID',
                      hintStyle: const TextStyle(color: mercerBlack),
                      filled: true,
                      fillColor: mercerWhite, 
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none, 
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
                    ),
                    style: const TextStyle(
                      color: mercerBlack,
                      fontSize: 16,
                    ), 
                  ),
                ),
                const SizedBox(height: 100),
                ElevatedButton(
                  onPressed: () async {
                    
                    final String email = '${emailController.text}@live.mercer.edu';

                    resetPassword(email);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Verification(_gps, _isLocationEnabled, verificationType: 'password', email: email)));

                    

                  },
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32), 
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFFF76800)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Send Verification',
                    style: TextStyle(
                      color: mercerWhite,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
