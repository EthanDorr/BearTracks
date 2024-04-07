import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'accontLogic.dart';
import "verification.dart";

class passwordResetScreen extends StatelessWidget {

  const passwordResetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController emailController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color.fromRGBO(34, 34, 34, 1), // Set background color to gray
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
                    color: const Color(0xFFF76800), // Set background color of the box
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Reset Password',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 35,
                        fontWeight: FontWeight.bold,

                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 110),
                SizedBox(
                  width: 300, // Adjust the width as needed
                  child: TextField(
                    controller: emailController,
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
                const SizedBox(height: 100),
                ElevatedButton(
                  onPressed: () async {
                    
                    String email = '${emailController.text}@live.mercer.edu';

                    resetPassword(email);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => verification(verificationType: 'password', email: email)));

                    

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
                    'Send Verification',
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
      ),
    );
  }
}
