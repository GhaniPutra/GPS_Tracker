import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gps_tracker_app/providers/theme_provider.dart';
import 'package:gps_tracker_app/providers/bluetooth_provider.dart';
import 'package:gps_tracker_app/providers/auth_provider.dart';
import 'package:gps_tracker_app/providers/connection_provider.dart';
import 'package:gps_tracker_app/utils/theme.dart';
import 'package:gps_tracker_app/screens/quest_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/startup_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gps_tracker_app/firebase_options.dart';

import 'services/key_manager.dart';
import 'services/bluetooth_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Fetch HMAC key from remote or secure storage and configure BluetoothManager
  try {
    final remoteBytes = await KeyManager().fetchFromRemote();
    final keyBytes = remoteBytes ?? await KeyManager().getKeyBytes();
    if (keyBytes != null && keyBytes.isNotEmpty) {
      BluetoothManager().setHmacKey(keyBytes);
      debugPrint('HMAC key loaded (${keyBytes.length} bytes)');
    } else {
      debugPrint('No HMAC key found in remote or storage');
    }
  } catch (e) {
    debugPrint('Failed to load HMAC key: $e');
  }

  // Create and initialize AuthProvider before runApp so the guest flag is known early
  final authProvider = AuthProvider();
  await authProvider.init();

  final connectionProvider = ConnectionProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => BluetoothProvider()),
        ChangeNotifierProvider.value(value: connectionProvider),
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: const MyApp(),
    ),
  );

    if (authProvider.isAuthenticated) {
    connectionProvider.initialize();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'GPS Tracker',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          home: const StartupScreen(),
          routes: {
            '/welcome': (context) => const WelcomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/quest': (context) => const QuestScreen(),
          },
        );
      },
    );
  }
}
