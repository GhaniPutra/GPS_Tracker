import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/invite_service.dart';
import '../services/relation_service.dart';
import '../services/location_service.dart';
import 'package:latlong2/latlong.dart';

/// Represents a connected user with their location
class ConnectedUser {
  final String userId;
  final String name;
  final String? photoUrl;
  final UserLocation? location;
  final bool isOnline;
  final DateTime connectedAt;

  ConnectedUser({
    required this.userId,
    required this.name,
    this.photoUrl,
    this.location,
    this.isOnline = false,
    required this.connectedAt,
  });

  /// Check if location is available and recent
  bool get hasRecentLocation => location != null && isOnline;

  /// Get display name
  String get displayName => name;

  /// Get initials for avatar
  String get initials {
    if (name.isEmpty) return '??';
    
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    
    if (parts.isEmpty) return '??';
    
    if (parts.length == 1) {
      // Jika hanya 1 kata, ambil 2 huruf pertama (atau 1 jika hanya 1 huruf)
      final word = parts[0];
      if (word.length >= 2) {
        return word.substring(0, 2).toUpperCase();
      } else {
        return word[0].toUpperCase();
      }
    } else {
      // Jika lebih dari 1 kata, ambil huruf pertama dari 2 kata pertama
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
  }

  factory ConnectedUser.fromRelation(Relation relation, String currentUserId) {
    return ConnectedUser(
      userId: relation.getOtherUserId(currentUserId),
      name: relation.getOtherUserName(currentUserId),
      photoUrl: null,
      location: null,
      connectedAt: relation.createdAt,
    );
  }
}

/// Status for connection operations
enum ConnectionStatus {
  idle,
  loading,
  error,
  success,
}

/// Provider for managing user connections and location sharing
class ConnectionProvider with ChangeNotifier {
  final InviteService _inviteService = InviteService();
  final RelationService _relationService = RelationService();
  final LocationService _locationService = LocationService();

  List<ConnectedUser> _connectedUsers = [];
  String? _currentInviteCode;
  ConnectionStatus _state = ConnectionStatus.idle;
  String? _errorMessage;

  // Connection state getters
  List<ConnectedUser> get connectedUsers => List.unmodifiable(_connectedUsers);
  String? get currentInviteCode => _currentInviteCode;
  ConnectionStatus get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isSharingLocation => _locationService.isSharing;

  /// Stream of active relations
  Stream<List<Relation>> get relationsStream =>
      _relationService.getActiveRelations();

  /// Stream of locations from connected users
  Stream<Map<String, UserLocation>> get locationsStream =>
      _locationService.streamAllRelatedLocations();

  /// Initialize the connection provider
  void initialize() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _startListeningToRelations();
    }
  }

  /// Start listening to relation changes
  void _startListeningToRelations() {
    _relationService.getActiveRelations().listen((relations) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final users = <ConnectedUser>[];

      for (final relation in relations) {
        final otherUserId = relation.getOtherUserId(user.uid);
        final userInfo = await _relationService.getRelatedUserInfo(otherUserId);

        users.add(ConnectedUser(
          userId: otherUserId,
          name: userInfo?.displayName ?? relation.getOtherUserName(user.uid),
          photoUrl: userInfo?.photoUrl,
          location: null,
          connectedAt: relation.createdAt,
        ));
      }

      _connectedUsers = users;
      notifyListeners();
    });
  }

  /// Create a new invite code
  Future<void> createInvite() async {
    _setState(ConnectionStatus.loading, null);

    final result = await _inviteService.createInvite();

    if (result.success && result.inviteCode != null) {
      _currentInviteCode = result.inviteCode;
      _setState(ConnectionStatus.success, null);
    } else {
      _setState(ConnectionStatus.error, result.errorMessage);
    }
  }

  /// Accept an invite code
  Future<bool> acceptInvite(String code) async {
    _setState(ConnectionStatus.loading, null);

    final result = await _inviteService.acceptInvite(code);

    if (result.success) {
      _setState(ConnectionStatus.success, null);
      return true;
    } else {
      _setState(ConnectionStatus.error, result.errorMessage);
      return false;
    }
  }

  /// Revoke a connection with a user
  Future<bool> revokeConnection(String userId) async {
    _setState(ConnectionStatus.loading, null);

    final result = await _relationService.revokeRelation(userId);

    if (result.success) {
      // Stop location sharing with this user
      await _locationService.stopSharingWithUser(userId);
      _setState(ConnectionStatus.success, null);
      return true;
    } else {
      _setState(ConnectionStatus.error, result.errorMessage);
      return false;
    }
  }

  /// Start sharing location with all connected users
  Future<void> startLocationSharing() async {
    try {
      await _locationService.startSharing();
      notifyListeners();
    } catch (e) {
      _setState(ConnectionStatus.error, 'Failed to start location sharing: $e');
    }
  }

  /// Stop sharing location
  void stopLocationSharing() {
    _locationService.stopSharing();
    notifyListeners();
  }

  /// Toggle location sharing
  Future<void> toggleLocationSharing() async {
    if (_locationService.isSharing) {
      stopLocationSharing();
    } else {
      await startLocationSharing();
    }
  }

  /// Get location of a specific connected user
  Future<UserLocation?> getUserLocation(String userId) async {
    final result = await _locationService.getUserLocation(userId);
    return result.location;
  }

  /// Stream location of a specific user
  Stream<UserLocation?> streamUserLocation(String userId) {
    return _locationService.streamUserLocation(userId);
  }

  /// Update a connected user's location
  void updateUserLocation(String userId, UserLocation location) {
    final index = _connectedUsers.indexWhere((u) => u.userId == userId);
    if (index != -1) {
      final user = _connectedUsers[index];
      _connectedUsers[index] = ConnectedUser(
        userId: user.userId,
        name: user.name,
        photoUrl: user.photoUrl,
        location: location,
        connectedAt: user.connectedAt,
      );
      notifyListeners();
    }
  }

  /// Update all connected users' locations
  void updateAllLocations(Map<String, UserLocation> locations) {
    for (final entry in locations.entries) {
      updateUserLocation(entry.key, entry.value);
    }
  }

  /// Check if connected to a specific user
  bool isConnectedTo(String userId) {
    return _connectedUsers.any((u) => u.userId == userId);
  }

  /// Get connected user by ID
  ConnectedUser? getConnectedUser(String userId) {
    try {
      return _connectedUsers.firstWhere((u) => u.userId == userId);
    } catch (_) {
      return null;
    }
  }

  /// Clear the current invite code
  void clearInviteCode() {
    _currentInviteCode = null;
    notifyListeners();
  }

  /// Reset state to idle
  void resetState() {
    _setState(ConnectionStatus.idle, null);
  }

  /// Set state and notify listeners
  void _setState(ConnectionStatus newState, String? error) {
    _state = newState;
    _errorMessage = error;
    notifyListeners();
  }

  /// Format invite code for display (ABC 123)
  String formatInviteCode(String code) {
    if (code.length == 6) {
      return '${code.substring(0, 3)} ${code.substring(3, 6)}';
    }
    return code;
  }

  /// Copy invite code to clipboard
  Future<void> copyInviteCode(BuildContext context) async {
    if (_currentInviteCode != null) {
      await Clipboard.setData(ClipboardData(text: _currentInviteCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode invite disalin ke clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Calculate distance to a user
  String getDistanceTo(String userId, LatLng currentPosition) {
    final user = getConnectedUser(userId);
    if (user?.location == null) return 'Lokasi tidak tersedia';

    final distance = _locationService.calculateDistance(
      currentPosition,
      user!.location!.toLatLng(),
    );
    return _locationService.formatDistance(distance);
  }

  /// Check if location sharing is enabled
  bool get locationSharingEnabled => _locationService.isSharing;

  /// Get the number of connected users
  int get connectedCount => _connectedUsers.length;

  /// Get online users count
  int get onlineCount =>
      _connectedUsers.where((u) => u.hasRecentLocation).length;

  /// Dispose
  @override
  void dispose() {
    _locationService.stopSharing();
    super.dispose();
  }
}

