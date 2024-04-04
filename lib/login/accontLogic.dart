import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

//////////////////////////////
/// Remember Me Logic
//////////////////////////////

const String _rememberMeKey = 'rememberMe';
const String _emailKey = 'email';
const String _passwordKey = 'password';
late final SharedPreferences prefs;

Future<void>init() async {
  prefs = await SharedPreferences.getInstance();

}

Future<bool> getRememberMeStatus(bool value) async {
  //final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_rememberMeKey) ?? false;
}

Future<void> setRememberMeStatus(bool value) async {
  //final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_rememberMeKey, value);
}

Future<void> saveUserCredentials(String email, String password) async {
  //final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(_emailKey, email);
  await prefs.setString(_passwordKey, password);
}

Future<Map<String, String>> getUserCredentials() async {
  //final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? email = prefs.getString(_emailKey);
  final String? password = prefs.getString(_passwordKey);
  return {
    'email': email ?? '',
    'password': password ?? '',
  };
}

Future<void> clearuserCredentials() async {
  //final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove(_emailKey);
  await prefs.remove(_passwordKey);
}


//Logic on startup
// ON Splash Screen must last atleast 1s
// 1. Check if loged in
// 2. Check for RememberMe, if yes log them in
// If no send them to login/create/guest page
//