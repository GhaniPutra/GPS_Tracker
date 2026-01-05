import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';

class HardwareProvider with ChangeNotifier {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  LatLng? _hardwarePosition;
  bool _isConnected = false;

  LatLng? get hardwarePosition => _hardwarePosition;
  bool get isConnected => _isConnected;

  HardwareProvider() {
    _listenToHardwareData();
  }

  void _listenToHardwareData() {
    _databaseRef.child('gps').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;
        if (lat != null && lng != null) {
          _hardwarePosition = LatLng(lat, lng);
          _isConnected = true;
          notifyListeners();
        }
      }
    }, onError: (error) {
      _isConnected = false;
      notifyListeners();
    });
  }

  void disconnect() {
    _isConnected = false;
    _hardwarePosition = null;
    notifyListeners();
  }
}