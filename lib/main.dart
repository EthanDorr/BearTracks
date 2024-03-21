import 'package:flutter/material.dart'; 
import 'login/loginscreen.dart'; // Import the LoginScreen class

//firebase 
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget { 
  const MyApp({Key? key}) : super(key: key); // Add a key parameter

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(), // Set LoginScreen as the default screen
      routes: {
        '/login': (context) => const LoginScreen(), // Add route to LoginScreen
      },
    );
  }
}
