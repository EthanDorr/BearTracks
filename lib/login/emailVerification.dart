import 'package:bear_tracks/login/accontLogic.dart';
import 'package:bear_tracks/login/studentLoginScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class emailVerification extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check Your Email'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Please check your email for a verification link. This may take a few minutes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18.0),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                    User? user = FirebaseAuth.instance.currentUser;
                    print('User is Signed in: ${user?.uid}');
                    sendVerification();
                },
                child: Text('Resend Verification Email'),
              ),
              SizedBox(height: 10.0), // Add spacing between buttons
              ElevatedButton(
                onPressed: () {
                  // Navigate back to sign in screen or any other desired action
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const studentLoginScreen()));
                },
                child: Text('Continue to Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
