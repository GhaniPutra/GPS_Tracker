import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gps_tracker_app/providers/auth_provider.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideRoute());
  }

  void _decideRoute() {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // If authenticated (firebase user or guest), go to home
    if (auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    // Not authenticated: show welcome if not seen, otherwise login
    if (!auth.isWelcomeSeen) {
      Navigator.pushReplacementNamed(context, '/welcome');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Minimal placeholder while we decide route
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
