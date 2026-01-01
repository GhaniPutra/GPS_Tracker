import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_services.dart';

class AuthProvider extends ChangeNotifier {
  static const _guestKey = 'is_guest';
  static const _storage = FlutterSecureStorage();

  bool _isGuest = false;
  bool _isWelcomeSeen = false;
  User? _user;

  bool get isGuest => _isGuest;
  bool get isWelcomeSeen => _isWelcomeSeen;
  User? get user => _user;
  bool get isAuthenticated => _isGuest || _user != null;

  Future<void> markWelcomeSeen() async {
    _isWelcomeSeen = true;
    await _storage.write(key: _welcomeKey, value: 'true');
    notifyListeners();
  }
  AuthProvider() {
    // Start listening to Firebase auth changes
    FirebaseAuth.instance.authStateChanges().listen((u) {
      _user = u;
      // If a firebase user signs-in, ensure guest is turned off
      if (u != null && _isGuest) {
        _isGuest = false;
        _storage.delete(key: _guestKey);
      }
      notifyListeners();
    });
  }

  static const _welcomeKey = 'is_welcome_seen';

  Future<void> init() async {
    final guestVal = await _storage.read(key: _guestKey);
    _isGuest = guestVal == 'true';
    final welcomeVal = await _storage.read(key: _welcomeKey);
    _isWelcomeSeen = welcomeVal == 'true';
    notifyListeners();
  }

  Future<void> signInGuest() async {
    _isGuest = true;
    await _storage.write(key: _guestKey, value: 'true');
    // Make sure no firebase user is present for guest mode
    // Do NOT call any Firebase auth methods here
    notifyListeners();
  }

  Future<void> signOutGuest() async {
    _isGuest = false;
    await _storage.delete(key: _guestKey);
    notifyListeners();
  }

  Future<void> signOut() async {
    _isGuest = false;
    await _storage.delete(key: _guestKey);
    await AuthService().logout();
    notifyListeners();
  }
}
