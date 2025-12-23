import 'package:flutter/material.dart';
import '../services/auth_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Helper widget untuk tombol sosial
  Widget _buildSocialButton(BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      icon: Icon(icon, color: theme.colorScheme.onSurface.withAlpha(204)),
      label: Text(text, style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(222))),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        side: BorderSide(color: theme.dividerColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Logo Aplikasi
              CircleAvatar(
                radius: 60,
                backgroundColor: theme.colorScheme.primary,
                child: Transform.rotate(
                  angle: -0.5, // Sedikit memutar ikon
                  child: Icon(
                    Icons.send_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ngetces',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4.0,
                      color: isDarkMode ? Colors.black54 : Colors.black26,
                      offset: const Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Tombol Sign up / Login
              ElevatedButton(
                onPressed: () {
                  // Navigasi ke halaman utama, ganti layar (agar tidak bisa kembali)
                  Navigator.pushReplacementNamed(context, '/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Sign up / Login',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              // Tombol Google
              _buildSocialButton(context,
                icon: Icons.mail_outline, // Placeholder, ganti dengan logo Google
                text: 'Continue with Google',
                onPressed: () async{ //sync auth google firebase
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await AuthService().loginGoogle();
                    navigator.pushReplacementNamed('/home');
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
              ),
              const SizedBox(height: 10),
              // Tombol Apple
              _buildSocialButton(context,
                icon: Icons.apple, // Placeholder, ganti dengan logo Apple
                text: 'Continue with Apple',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
