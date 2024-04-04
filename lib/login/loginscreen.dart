import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'studentLoginScreen.dart';
import 'createAccount.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
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
              const SizedBox(height: 45),
              ElevatedButton(
                onPressed: () {
                  print('Student Login pressed');
                  //Navigate to StudentLoginScreen
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const studentLoginScreen()));
                },
                style: ButtonStyle(
                  padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 32), // Adjust the padding as needed
                  ),
                  backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFFF76800)),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                child: const Text(
                  'Student Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  print('Student Login pressed');
                  //Navigate to StudentLoginScreen
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const createAccount()));
                },
                style: ButtonStyle(
                  padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 32), // Adjust the padding as needed
                  ),
                  backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFFF76800)),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 10), // Add some spacing between the button and "Continue as guest" text
              GestureDetector(
                onTap: () {
                  print('Continue as guest pressed');
                  // Add the action you want to perform when "Continue as guest" is pressed
                },
                child: const Text(
                  'Continue as guest',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    decoration: TextDecoration.underline, // Underline to indicate it's clickable
                    decorationColor: Colors.white, // Set underline color to white
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
