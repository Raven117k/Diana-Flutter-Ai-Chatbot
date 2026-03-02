import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:diana/pages/chat_screen.dart';
import 'package:diana/auth/login.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          print('✅ Logged in as ${snapshot.data!.email}');
          return const ChatScreen();
        } else {
          print('🔐 No user found. Going to Login.');
          return const LoginPage();
        }
      },
    );
  }
}
