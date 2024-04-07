import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import "package:bear_tracks/firebase_options.dart";

//Create new Account wiht Email & Password
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

//Send email verification
Future<void> sendVerification() async {

    FirebaseAuth.instance.currentUser?.sendEmailVerification();

}


//Sign in with Email & Password
Future<UserCredential?> loginWithEmailAndPassword(String email, String password) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email, 
      password: password
      );
      return userCredential;
  } catch (e) {
    print(e.toString());
    return null;
  }
}

//Reset Password
void resetPassword(String email) async {
  try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
      email: email);
  } catch (e) {
    print('Failed to send password reset email: $e');
  }
}

//Check Password Strength


//Delete Account
void deleteAccount() async {
  try {
    await FirebaseAuth.instance.currentUser?.delete();
  } catch (e) {
    print('Failed to delete user account: $e');
  }
}

//Logout
void logout() async {
  await FirebaseAuth.instance.signOut();
}

