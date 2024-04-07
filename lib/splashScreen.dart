import 'dart:async'; // Import Timer

import 'package:bear_tracks/login/loginscreen.dart';
import 'package:bear_tracks/map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bear_tracks/globals.dart';

class SplashScreenWidget extends StatefulWidget {
  @override
  _SplashScreenWidgetState createState() => _SplashScreenWidgetState();
}

class _SplashScreenWidgetState extends State<SplashScreenWidget> {
  bool _loadingComplete = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(Duration(seconds: 5), _loadData);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _loadingComplete = true;
    });
    
    

    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => MapScreen(accountType: true)));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(34, 34, 34, 1), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/Spirit-mercer-block-m.png',
              width: 300,
              height: 300,
            ),
            const SizedBox(height: 15),
            Text(
              'Bear Tracks',
              style: GoogleFonts.caveat(
                textStyle: const TextStyle(
                  fontSize: 72,
                  color: Color(0xFFF76800),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!_loadingComplete)
              CircularProgressIndicator(
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(mercerMercerOrange),
              )
          ],
        ),
      ),
    );
  }
}
