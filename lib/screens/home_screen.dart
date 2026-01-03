import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:gps_tracker_app/providers/auth_provider.dart';
import 'package:gps_tracker_app/services/auth_services.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/connection_provider.dart';
import '../widgets/device_bottom_sheet.dart';
import '../widgets/group_bottom_sheet.dart';
import '../widgets/profile_menu_dialog.dart';
import '../widgets/map_type_bottom_sheet.dart';
import '../utils/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final MapController _mapController;
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  static const LatLng _initialPosition = LatLng(-7.7956, 110.3695);
  static const double _initialZoom = 14.0;
  
  String _currentMapType = 'default';
  bool _is3DEnabled = false;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _bottomNavController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _determinePosition();
    
    // Initialize animations
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _bottomNavController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    _pulseController.dispose();
    _bottomNavController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(
        _currentPosition!,
        16.0,
      );
    }, onError: (error) {});
  }

  void _showGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GroupBottomSheet(),
    );
  }

  void _showDeviceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DeviceBottomSheet(),
    );
  }

  void _showProfileMenu() async {
    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => const ProfileMenuDialog(),
    );

    // Handle actions returned from the dialog immediately after it is dismissed.
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (result == 'settings') {
      Navigator.pushNamed(context, '/settings');
    } else if (result == 'logout') {
      if (auth.isGuest) {
        await auth.signOutGuest();
      } else {
        await AuthService().logout();
      }

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } else if (result == 'add_account') {
      // TODO: handle add account flow
    } else if (result == 'help') {
      // TODO: handle help flow
    }
  }

  void _showMapTypeSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MapTypeBottomSheet(
        currentMapType: _currentMapType,
        is3DEnabled: _is3DEnabled,
        onMapTypeChanged: (type) {},
        on3DChanged: (isEnabled) {
          setState(() {
            _is3DEnabled = isEnabled;
          });
        },
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _currentMapType = result;
      });
    }
  }

  String _getTileLayerUrl() {
    switch (_currentMapType) {
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'terrain':
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case 'default':
      default:
        return 'https://{s}.google.com/vt/lyrs=m,traffic&x={x}&y={y}&z={z}';
    }
  }

  List<String> _getTileLayerSubdomains() {
    switch (_currentMapType) {
      case 'satellite':
        return [];
      case 'terrain':
        return ['a', 'b', 'c'];
      case 'default':
      default:
        return ['mt0', 'mt1', 'mt2', 'mt3'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ===== MAIN MAP =====
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

              Consumer<BluetoothProvider>(builder: (context, bt, child) {
                final selected = bt.getSelectedDevice();
                if (selected != null && selected.lastPosition != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _mapController.move(selected.lastPosition!, 16.0);
                    bt.clearSelection();
                  });
                }

                final storedPos = bt.selectedKnownPosition;
                if (storedPos != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _mapController.move(storedPos, 16.0);
                    bt.clearSelectedKnownPosition();
                  });
                }

                final markers = <Marker>[];

                // User location marker dengan pulse animation
                if (_currentPosition != null) {
                  markers.add(Marker(
                    point: _currentPosition!,
                    width: 80,
                    height: 80,
                    child: _buildUserMarker(),
                  ));
                }

                // Connected devices markers
                for (final conn in bt.connectedDevices) {
                  if (conn.lastPosition != null) {
                    markers.add(Marker(
                      point: conn.lastPosition!,
                      width: 70,
                      height: 70,
                      child: _buildDeviceMarker(conn.name, true),
                    ));
                  }
                }

                // Known devices markers (offline)
                for (final sd in bt.knownDevices) {
                  if (sd.lastLat != null && sd.lastLon != null) {
                    final isConnected = bt.connectedDevices.any(
                      (c) => c.id == sd.id && c.lastPosition != null,
                    );
                    if (isConnected) continue;

                    markers.add(Marker(
                      point: LatLng(sd.lastLat!, sd.lastLon!),
                      width: 64,
                      height: 64,
                      child: _buildOfflineDeviceMarker(sd.name),
                    ));
                  }
                }

                if (markers.isEmpty) return const SizedBox.shrink();
                return MarkerLayer(markers: markers);
              }),

              // Connected users markers from ConnectionProvider
              Consumer<ConnectionProvider>(
                builder: (context, connectionProvider, child) {
                  final connectedUsers = connectionProvider.connectedUsers;
                  final markers = <Marker>[];

                  for (final user in connectedUsers) {
                    if (user.location != null) {
                      markers.add(Marker(
                        point: user.location!.toLatLng(),
                        width: 70,
                        height: 70,
                        child: _buildConnectedUserMarker(
                          user.name,
                          user.isOnline,
                          user.initials,
                        ),
                      ));
                    }
                  }

                  if (markers.isEmpty) return const SizedBox.shrink();
                  return MarkerLayer(markers: markers);
                },
              ),
            ],
          ),

          // ===== TOP STATUS BAR (Glassmorphism) =====
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopStatusBar(),
          ),

          // ===== MAP CONTROLS (Right Side) =====
          Positioned(
            top: 100,
            right: AppSpacing.md,
            child: _buildMapControls(),
          ),

          // ===== MY LOCATION BUTTON =====
          Positioned(
            bottom: 140,
            right: AppSpacing.md,
            child: _buildMyLocationButton(),
          ),

          // ===== BOTTOM NAVIGATION =====
          Positioned(
            bottom: AppSpacing.xl,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: _buildModernBottomNav(),
          ),
        ],
      ),
    );
  }

  // ===== MARKER WIDGETS =====
  
  Widget _buildUserMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + 0.3 * _pulseController.value;
        final opacity = 1.0 - _pulseController.value * 0.5;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse effect
            Container(
              width: 60 * scale,
              height: 60 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.markerUser.withOpacity(0.2 * opacity),
              ),
            ),
            // Main marker
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.markerUser,
                boxShadow: AppShadows.glowPrimary,
              ),
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceMarker(String name, bool isOnline) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Marker icon with subtle animation
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? AppColors.markerDevice : AppColors.markerDeviceOffline,
                boxShadow: isOnline ? AppShadows.glowPrimary : AppShadows.small,
              ),
              child: Icon(
                isOnline ? Icons.gps_fixed : Icons.gps_off,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            // Name tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                boxShadow: AppShadows.small,
              ),
              child: Text(
                name,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOfflineDeviceMarker(String name) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.markerDeviceOffline,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(
            Icons.location_off,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          ),
          child: Text(
            name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.brightness == Brightness.dark 
                  ? Colors.white70 
                  : Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build marker for connected users (via ConnectionProvider)
  Widget _buildConnectedUserMarker(String name, bool isOnline, String initials) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + 0.1 * _pulseController.value;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User avatar marker
            Transform.scale(
              scale: isOnline ? scale : 1.0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? AppColors.markerConnectedUser : AppColors.markerDeviceOffline,
                  boxShadow: isOnline ? AppShadows.glowSecondary : AppShadows.small,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Name tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                boxShadow: AppShadows.small,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Online indicator
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    name,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ===== TOP STATUS BAR =====

  Widget _buildTopStatusBar() {
    return const SizedBox.shrink();
  }



  // ===== MAP CONTROLS =====

  Widget _buildMapControls() {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(
            icon: Icons.add,
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom + 1,
              );
            },
          ),
          const Divider(height: 1, indent: 0, endIndent: 0),
          _buildControlButton(
            icon: Icons.remove,
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom - 1,
              );
            },
          ),
          const Divider(height: 1, indent: 0, endIndent: 0),
          _buildControlButton(
            icon: Icons.layers,
            onPressed: _showMapTypeSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.md),
          bottom: Radius.circular(AppBorderRadius.md),
        ),
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppBorderRadius.md),
              bottom: Radius.circular(AppBorderRadius.md),
            ),
          ),
          child: Icon(
            icon,
            size: 22,
            color: Theme.of(context).iconTheme.color,
          ),
        ),
      ),
    );
  }

  // ===== MY LOCATION BUTTON =====

  Widget _buildMyLocationButton() {
    final theme = Theme.of(context);
    
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
      color: theme.cardColor,
      child: InkWell(
        onTap: () {
          if (_currentPosition != null) {
            _mapController.move(_currentPosition!, 16.0);
          } else {
            _determinePosition();
          }
        },
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Icon(
            Icons.my_location,
            size: 22,
            color: _currentPosition != null ? AppColors.primary : AppColors.markerDeviceOffline,
          ),
        ),
      ),
    );
  }

  // ===== MODERN BOTTOM NAVIGATION =====

  Widget _buildModernBottomNav() {
    final theme = Theme.of(context);

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: (theme.cardColor).withOpacity(0.95),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(theme.brightness == Brightness.dark ? 30 : 20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: (theme.brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Group Button
          _buildNavButton(
            icon: Icons.group_outlined,
            activeIcon: Icons.group,
            label: 'Grup',
            onTap: _showGroupSheet,
          ),
          
          // Center - Profile Avatar
          _buildProfileButton(),
          
          // Device Button
          _buildNavButton(
            icon: Icons.devices_other_outlined,
            activeIcon: Icons.devices_other,
            label: 'Perangkat',
            onTap: _showDeviceSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 26,
                color: theme.iconTheme.color?.withOpacity(0.7),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.iconTheme.color?.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileButton() {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.isGuest ? null : auth.user;

    return GestureDetector(
      onTap: _showProfileMenu,
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(AppBorderRadius.full),
          boxShadow: AppShadows.glowPrimary,
        ),
        child: Center(
          child: user?.photoURL != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  child: Image.network(
                    user!.photoURL!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                )
              : Text(
                  (user?.displayName != null && user!.displayName!.isNotEmpty)
                      ? user.displayName!.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                      : (auth.isGuest ? 'G' : (user?.email != null ? user!.email![0].toUpperCase() : 'U')),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
        ),
      ),
    );
  }
}

