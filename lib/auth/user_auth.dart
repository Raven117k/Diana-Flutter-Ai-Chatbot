import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<User?> createUserWithEmailAndPassword(
  String emailAddress,
  String password,
) async {
  try {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: emailAddress,
          password: password,
        );

    final user = credential.user; // ✅ Use this directly

    if (user != null) {
      print('✅ User created: ${user.email} (${user.uid})');

      await FirebaseFirestore.instance.collection('admins').doc(user.uid).set({
        'email': user.email,
        'createdAt': DateTime.now(),
      });

      print('📦 Firestore entry added.');
      return user;
    }

    return null;
  } catch (e) {
    print('❌ Signup error: $e');
    return null;
  }

}

Future<void> signInWithEmailAndPassword(
  String emailAddress,
  String password,
  BuildContext context,
) async {
  try {
    final credential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailAddress,
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      print('✅ Login successful: ${user.email}');
      // DO NOT navigate
      // AuthGate will handle it
    }
  } on FirebaseAuthException catch (e) {
    String message;

    switch (e.code) {
      case 'user-not-found':
        message = 'No user found for that email.';
        break;
      case 'wrong-password':
        message = 'Wrong password.';
        break;
      case 'invalid-email':
        message = 'Invalid email address.';
        break;
      default:
        message = e.message ?? 'Login failed';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );

    print('❌ FirebaseAuthException: ${e.code}');
    rethrow;
  }
}
