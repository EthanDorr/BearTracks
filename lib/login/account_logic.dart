// ignore_for_file: unused_import

import 'dart:developer' show log;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:bear_tracks/firebase_options.dart';

Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
  try {
    final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential;
  } catch (e) {
    log(e.toString());
    return null;
  }
}


Future<void> sendVerification() async {
    FirebaseAuth.instance.currentUser?.sendEmailVerification();
}


Future<UserCredential?> loginWithEmailAndPassword(String email, String password) async {
  try {
    final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email, 
      password: password
      );
    return userCredential;
  } catch (e) {
    log(e.toString());
    return null;
  }
}


void resetPassword(String email) async {
  try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
      email: email);
  } catch (e) {
    log('Failed to send password reset email: $e');
  }
}


void deleteAccount() async {
  try {
    await FirebaseAuth.instance.currentUser?.delete();
  } catch (e) {
    log('Failed to delete user account: $e');
  }
}


void logout() async {
  await FirebaseAuth.instance.signOut();
}
