import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'map.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate loading data or performing tasks
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 3));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()), 
    );
  }

    Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(34, 34, 34, 1), // Set background color to gray
      body: Center(
        child: Transform.translate(
          offset: const Offset(0, -20), // Move both the image and the text upwards by adjusting the vertical offset
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/Spirit-mercer-block-m.png',
                width: 300,
                height: 300,
              ),
              const SizedBox(height: 15), // Add some spacing
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
              const CircularProgressIndicator(
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF76800)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
