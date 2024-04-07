import 'package:bear_tracks/globals.dart';
import 'package:bear_tracks/login/accontLogic.dart';
import 'package:bear_tracks/login/studentLoginScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class verification extends StatelessWidget {
  final String verificationType;
  final String email;
  const verification({
    super.key, 
    required this.verificationType,  
    this.email = ''});

  

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
            print('Back button pressed');
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
                'assets/images/Spirit-mercer-block-m.png',
                width: 250,
                height: 250,
              ),
              SizedBox(height: 80.0),
              Text(
                'Please check your email for a verification link. This may take a few minutes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.white),
                
              ),
              SizedBox(height: 60.0),
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
                child: Text(
                  'Resend Verification',
                  style: TextStyle(
                    color: mercerBlack
                  ),
                  ),
              ),
              SizedBox(height: 10.0), // Add spacing between buttons
              ElevatedButton(
                onPressed: () {
                  // Navigate back to sign in screen or any other desired action
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const studentLoginScreen()));
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(mercerMercerOrange),
                ),
                child: Text(
                  'Continue to Sign In',
                  style: TextStyle(
                    color: mercerBlack
                  ),
                  ),
              ),
              SizedBox(height: 120.0),
            ],
          ),
        ),
      ),
    );
  }
}
