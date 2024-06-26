import 'dart:developer' show log;

import 'package:bear_tracks/login/create_account.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bear_tracks/globals.dart';
import 'package:bear_tracks/gps.dart';
import 'package:bear_tracks/login/account_logic.dart';
import 'package:bear_tracks/login/verification.dart';
import 'package:bear_tracks/login/reset_password.dart';
import 'package:bear_tracks/map.dart';

class StudentLoginScreen extends StatefulWidget {
  final bool _isLocationEnabled;
  final GPS _gps;
  const StudentLoginScreen(this._gps, this._isLocationEnabled, {super.key});

  @override
  StudentLoginScreenState createState() => StudentLoginScreenState();
}

class StudentLoginScreenState extends State<StudentLoginScreen> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    widget._gps.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: mercerBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: screenSize.height * 0.1,
              ),
              Container(
                width: screenSize.width * 0.9,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: mercerMercerOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Student Login',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenSize.height * 0.15),
              SizedBox(
                width: screenSize.width * 0.8,
                child: TextField(
                  controller: _loginController,
                  decoration: InputDecoration(
                    hintText: 'MUID',
                    hintStyle: const TextStyle(color: Colors.black),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(height: screenSize.height * 0.02),
              SizedBox(
                width: screenSize.width * 0.8,
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.black),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(height: screenSize.height * 0.01),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateAccount(widget._gps, widget._isLocationEnabled))),
                child: RichText(
                  text: const TextSpan(
                    text: 'New User? ',
                    style: TextStyle(
                      color: mercerWhite,
                      fontSize: 18,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Create An Account',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenSize.height * 0.02),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PasswordResetScreen(widget._gps, widget._isLocationEnabled))),
                child: const Text(
                  'Forgot Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: screenSize.height * 0.1),
              ElevatedButton(
                onPressed: () async {
                  final String email = '${_loginController.text}@live.mercer.edu';
                  final String password = _passwordController.text;

                  log('Login pressed');
                  log(email);
                  log(password);

                  await loginWithEmailAndPassword(email, password);

                  final User? user = FirebaseAuth.instance.currentUser;

                  if (user != null && context.mounted) {
                    Navigator.push(
                      context, MaterialPageRoute(
                        builder: (BuildContext context) {
                          return user.emailVerified
                              ? MapScreen(true, widget._gps, widget._isLocationEnabled)
                              : Verification(widget._gps, widget._isLocationEnabled, verificationType: 'email');
                        },
                      ),
                    );
                  } else {
                    //Say email or password is incorrect
                    printSnackBar(
                      'MUID or password is incorrect.',
                      duration: const Duration(seconds: 10),
                    );
                  }
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
                  'Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
