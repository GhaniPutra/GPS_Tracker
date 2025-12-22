import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Import flutter_map
import 'package:latlong2/latlong.dart'; // Import latlong2 for LatLng
import 'package:geolocator/geolocator.dart';
import 'dart:async'; // Tambahkan ini

// Menggunakan import relatif
import '../widgets/device_bottom_sheet.dart';
import '../widgets/group_bottom_sheet.dart';
import '../widgets/profile_menu_dialog.dart';
import '../widgets/map_type_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MapController _mapController; // Initialize MapController directly
  LatLng? _currentPosition; // Variabel untuk menyimpan posisi saat ini
  StreamSubscription<Position>? _positionStreamSubscription; // Tambahkan ini
  static const LatLng _initialPosition = LatLng(-7.7956, 110.3695); // Koordinat Yogyakarta (placeholder)
  static const double _initialZoom = 14.0;

  // State untuk tipe dan detail peta
  String _currentMapType = 'Default';

  bool _is3DEnabled = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _determinePosition();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel(); // Batalkan langganan saat widget dibuang
    _mapController.dispose(); // Dispose the map controller
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
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
      _mapController.move(
        _currentPosition!,
        16.0,
      );
    }, onError: (error) {
      // Re-throwing the error or handling it in a way that is visible to the user is better than just printing it.
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
          ? Colors.white.withAlpha(26)
          : Colors.black.withAlpha(26),
      builder: (context) => const ProfileMenuDialog(),
    );
  }

  // Fungsi untuk menampilkan bottom sheet tipe peta
  void _showMapTypeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MapTypeBottomSheet(
        currentMapType: _currentMapType,
        is3DEnabled: _is3DEnabled,
        onMapTypeChanged: (type) {
          setState(() {
            _currentMapType = type;
          });
          Navigator.pop(context); // Tutup bottom sheet setelah memilih
        },
        on3DChanged: (isEnabled) {
          setState(() {
            _is3DEnabled = isEnabled;
            // Catatan: flutter_map tidak mendukung 3D secara default.
            // Toggle ini hanya untuk UI dan state management.
          });
        },
      ),
    );
  }

  String _getTileLayerUrl() {
    switch (_currentMapType) {
      case 'Satelit':
        // ArcGIS World Imagery
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'Medan':
        // OpenTopoMap
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case 'Default':
      default:
        return 'https://{s}.google.com/vt/lyrs=m,traffic&x={x}&y={y}&z={z}';
    }
  }

  List<String> _getTileLayerSubdomains() {
    switch (_currentMapType) {
      case 'Satelit':
        return [];
      case 'Medan':
        return ['a', 'b', 'c'];
      case 'Default':
      default:
        return ['mt0', 'mt1', 'mt2', 'mt3'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Flutter Map (Widget utama)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: _initialZoom,
              onMapReady: () {
                if (_currentPosition != null) {
                  _mapController.move(_currentPosition!, 16.0);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _getTileLayerUrl(),
                subdomains: _getTileLayerSubdomains(),
              ),

              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40.0,
                      ),
                    ),
                  ],
                ),
            ],
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
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  }),
                  const SizedBox(height: 8),
                  _buildMapControlButton(
                      icon: Icons.remove, onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  }),
                  const SizedBox(height: 8),
                  _buildMapControlButton(
                      icon: Icons.layers, onPressed: _showMapTypeSheet),
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
                  _mapController.move(
                    _currentPosition!,
                    16.0,
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
            color: isDarkMode ? Colors.black.withAlpha(128) : Colors.grey.withAlpha(77),
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
            icon: Icon(Icons.group, color: theme.iconTheme.color?.withAlpha(179)),
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
            icon: Icon(Icons.devices_other, color: theme.iconTheme.color?.withAlpha(179)),
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
