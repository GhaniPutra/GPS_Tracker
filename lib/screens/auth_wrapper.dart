import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gps_tracker_app/providers/auth_provider.dart' as app_auth;
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<app_auth.AuthProvider>(context);

    // If still waiting for firebase stream we still can rely on local guest flag
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !auth.isGuest) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If guest mode is active, treat as authenticated
        if (auth.isGuest) return const HomeScreen();

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
