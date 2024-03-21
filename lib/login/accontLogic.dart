import 'package:firebase_auth/firebase_auth.dart';

// Create a new user account with email and password
Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential;
  } catch (e) {
    // Handle account creation errors
    print(e.toString());
    return null;
  }
}
