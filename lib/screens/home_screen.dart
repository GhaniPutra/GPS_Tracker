import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async'; // Tambahkan ini

// Menggunakan import relatif
import '../widgets/device_bottom_sheet.dart';
import '../widgets/group_bottom_sheet.dart';
import '../widgets/profile_menu_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition; // Variabel untuk menyimpan posisi saat ini
  StreamSubscription<Position>? _positionStreamSubscription; // Tambahkan ini
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-7.7956, 110.3695), // Koordinat Yogyakarta (placeholder)
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel(); // Batalkan langganan saat widget dibuang
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied, we cannot request permissions.');
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Permissions are granted, start listening to position updates.
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      // Animate camera to current position if map controller is available
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition!,
            zoom: 16.0,
          ),
        ),
      );
    }, onError: (error) {
      print("Error in position stream: $error");
    });
  }

  // Fungsi untuk menampilkan bottom sheet "Group"
  void _showGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GroupBottomSheet(),
    );
  }

  // Fungsi untuk menampilkan bottom sheet "Device"
  void _showDeviceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DeviceBottomSheet(),
    );
  }

  // Fungsi untuk menampilkan menu "Profile"
  void _showProfileMenu() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierColor: theme.brightness == Brightness.dark
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.1),
      builder: (context) => const ProfileMenuDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cek apakah platform saat ini adalah Linux
    final bool isDesktop = defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows;

    if (isDesktop) {
      // Jika di Desktop (Linux/Windows), tampilkan pesan placeholder namun tetap fungsional
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Spacer(),
              const Icon(Icons.map_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              Text(
                'Peta tidak didukung di ${defaultTargetPlatform.name}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Fungsionalitas lain tetap tersedia di bawah.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 30.0, left: 20, right: 20),
                child: _buildCustomBottomNav(), // Tampilkan navigasi bawah
              ),
            ],
          ),
        ),
      );
    }

    // Jika bukan di Linux, tampilkan UI peta seperti biasa
    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map (Widget utama)
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: _currentPosition!,
                      zoom: 16.0,
                    ),
                  ),
                );
              }
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _currentPosition == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('currentLocation'),
                      position: _currentPosition!,
                      infoWindow: const InfoWindow(title: 'Lokasi Saya'),
                    ),
                  },
          ),

          // 2. Tombol Kontrol Peta (Kanan Atas)
          Positioned(
            top: 50,
            right: 15,
            child: SafeArea(
              child: Column(
                children: [
                  _buildMapControlButton(
                      icon: Icons.add, onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomIn());
                  }),
                  const SizedBox(height: 8),
                  _buildMapControlButton(
                      icon: Icons.remove, onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomOut());
                  }),
                  const SizedBox(height: 8),
                  _buildMapControlButton(
                      icon: Icons.navigation_outlined, onPressed: () {}),
                ],
              ),
            ),
          ),

          // 3. Tombol Lokasi Saya (Kanan Bawah)
          Positioned(
            bottom: 120,
            right: 15,
            child: _buildMapControlButton(
              icon: Icons.my_location,
              onPressed: () {
                if (_currentPosition != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: _currentPosition!,
                        zoom: 16.0,
                      ),
                    ),
                  );
                } else {
                  // Optionally, re-request location if not available
                  _determinePosition();
                }
              },
            ),
          ),

          // 4. Navigasi Bawah Kustom
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildCustomBottomNav(),
          ),
        ],
      ),
    );
  }

  // Widget helper untuk navigasi bawah kustom
  Widget _buildCustomBottomNav() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Tombol Group
          IconButton(
            icon: Icon(Icons.group, color: theme.iconTheme.color?.withOpacity(0.7)),
            iconSize: 28,
            onPressed: _showGroupSheet,
          ),
          // Tombol Profile (Tengah)
          GestureDetector(
            onTap: _showProfileMenu,
            child: const CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(
                  'https://placehold.co/100x100/E0E0E0/000000?text=User'),
            ),
          ),
          // Tombol Device
          IconButton(
            icon: Icon(Icons.devices_other, color: theme.iconTheme.color?.withOpacity(0.7)),
            iconSize: 28,
            onPressed: _showDeviceSheet,
          ),
        ],
      ),
    );
  }

  // Widget helper untuk tombol kontrol peta
  Widget _buildMapControlButton(
      {required IconData icon, required VoidCallback onPressed}) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4.0,
      shape: const CircleBorder(),
      color: theme.cardColor,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 45,
          height: 45,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Icon(icon, color: theme.iconTheme.color),
        ),
      ),
    );
  }
}
