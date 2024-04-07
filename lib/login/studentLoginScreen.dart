import 'package:bear_tracks/globals.dart';
import 'package:bear_tracks/login/resetPassword.dart';
import 'package:bear_tracks/map.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'accontLogic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'verification.dart';

class studentLoginScreen extends StatefulWidget {
  const studentLoginScreen({super.key});

  @override
  _StudentLoginScreenState createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<studentLoginScreen> {

    TextEditingController loginController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    bool rememberMe = false;


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
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 30), // Adjust padding as needed
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: mercerMercerOrange, // Set background color of the box
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
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
                const SizedBox(height: 110),
                SizedBox(
                  width: 300, // Adjust the width as needed
                  child: TextField(
                    controller: loginController,
                    decoration: InputDecoration(
                      hintText: 'Enter Mercer ID',
                      hintStyle: const TextStyle(color: Colors.black),
                      filled: true,
                      fillColor: Colors.white, // Set background color to white
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none, // Hide the border
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Adjust the padding
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ), // Set text color to black
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 300, // Adjust the width as needed
                  child: TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Enter Password',
                      hintStyle: const TextStyle(color: Colors.black),
                      filled: true,
                      fillColor: Colors.white, // Set background color to white
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none, // Hide the border
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Adjust the padding
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ), // Set text color to black
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    
                    Navigator.push(context, MaterialPageRoute(builder: (context) =>  const passwordResetScreen()));
                  },
                  child: const Text(
                    'Reset Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      decoration: TextDecoration.underline, // Underline to indicate it's clickable
                      decorationColor: Colors.white, // Set underline color to white
                    ),
                  ),
                ),
                const SizedBox(height: 100),
                ElevatedButton(
                  onPressed: () async {

                    String email = '${loginController.text}@live.mercer.edu';
                    String password = passwordController.text;

                    print('Login pressed');
                    // Add your create account logic here
                    print(email);
                    print(password);
                    print('Remember Me Value: $rememberMe');

                    await loginWithEmailAndPassword(email, password);
                    
                    User? user = FirebaseAuth.instance.currentUser;

                    if (user != null) {
                      if(user.emailVerified)
                      {
                        return const MapScreen(accountType: true);
                      }
                      else{
                        //Display text saying "Email not Verified"
                        Navigator.push(context, MaterialPageRoute(builder: (context) =>  const verification(verificationType: 'email',)));
                      }

                    }
                    else {
                      //Say email or password is incorrect
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Email or password is incorrect',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18
                            )
                          ),
                          duration: const Duration(seconds: 10),
                          backgroundColor: mercerBlack,
                          ));
                    }
                  },
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32), // Adjust the padding as needed
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Remember Me',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Checkbox(
                      value: rememberMe,
                      onChanged: (value) {
                        setState( () {
                          rememberMe = value ?? false;
                          print('Remember Me: $rememberMe');
                        });
                      },
                      activeColor: Colors.white,
                      checkColor: Colors.black,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}