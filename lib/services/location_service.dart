import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'relation_service.dart';

/// Represents a user's location data
class UserLocation {
  final String userId;
  final double lat;
  final double lng;
  final DateTime lastUpdate;
  final bool isOnline;

  UserLocation({
    required this.userId,
    required this.lat,
    required this.lng,
    required this.lastUpdate,
    this.isOnline = true,
  });

  factory UserLocation.fromMap(String userId, Map<String, dynamic> data) {
    return UserLocation(
      userId: userId,
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      lastUpdate: DateTime.fromMillisecondsSinceEpoch(data['lastUpdate'] as int),
      isOnline: _isRecentlyUpdated(data['lastUpdate'] as int),
    );
  }

  /// Check if location was updated within the last 5 minutes
  static bool _isRecentlyUpdated(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - timestamp < 5 * 60 * 1000; // 5 minutes
  }

  /// Get LatLng object
  LatLng toLatLng() => LatLng(lat, lng);

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'lastUpdate': lastUpdate.millisecondsSinceEpoch,
    };
  }
}

/// Result of location operations
class LocationResult {
  final bool success;
  final String? errorMessage;
  final UserLocation? location;

  LocationResult({required this.success, this.errorMessage, this.location});

  factory LocationResult.success(UserLocation location) =>
      LocationResult(success: true, location: location);

  factory LocationResult.error(String message) =>
      LocationResult(success: false, errorMessage: message);
}

/// Service for managing location sharing between connected users
class LocationService {
  static const String _locationsPath = 'user_locations';
  static const Duration _updateInterval = Duration(seconds: 10);
  static const double _minDistance = 10; // meters

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<Position>? _positionStream;
  bool _isSharing = false;

  /// Start sharing location with all active relations
  Future<void> startSharing() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_isSharing) return;
    _isSharing = true;

    // Get all active relations
    final relations = await RelationService().getActiveRelationsOnce();
    final sharedWith = relations.map((r) => r.getOtherUserId(user.uid)).toList();

    // Request location permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _isSharing = false;
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _isSharing = false;
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _isSharing = false;
      throw Exception('Location permission permanently denied');
    }

    // Get initial position
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _updateLocation(position.latitude, position.longitude, sharedWith);
    } catch (e) {
      // Silent fail for initial position
    }

    // Start streaming updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _minDistance.toInt(),
      ),
    ).listen((Position position) async {
      final relations = await RelationService().getActiveRelationsOnce();
      final updatedSharedWith =
          relations.map((r) => r.getOtherUserId(user.uid)).toList();
      await _updateLocation(
          position.latitude, position.longitude, updatedSharedWith);
    }, onError: (error) {
      // Silent fail for stream errors
    });
  }

  /// Stop sharing location
  void stopSharing() {
    _positionStream?.cancel();
    _positionStream = null;
    _isSharing = false;
  }

  /// Check if currently sharing location
  bool get isSharing => _isSharing;

  /// Update location in Firebase
  Future<void> _updateLocation(
    double lat,
    double lng,
    List<String> sharedWith,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final locationData = {
      'lat': lat,
      'lng': lng,
      'lastUpdate': now,
    };

    // Update location
    await _database.child('$_locationsPath/${user.uid}').update(locationData);

    // Update sharedWith list
    if (sharedWith.isNotEmpty) {
      final sharedWithMap = {for (final userId in sharedWith) userId: true};
      await _database
          .child('$_locationsPath/${user.uid}/sharedWith')
          .set(sharedWithMap);
    }
  }

  /// Get location of a specific user (if relation exists)
  Future<LocationResult> getUserLocation(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return LocationResult.error('User not authenticated');
      }

      // Verify relation exists
      final hasRelation = await RelationService().hasActiveRelation(userId);
      if (!hasRelation) {
        return LocationResult.error('No active relation with this user');
      }

      final snapshot =
          await _database.child('$_locationsPath/$userId').once();

      if (snapshot.snapshot.value == null) {
        return LocationResult.error('User has not shared their location');
      }

      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      final location = UserLocation.fromMap(userId, data);

      return LocationResult.success(location);
    } catch (e) {
      return LocationResult.error('Failed to get location: $e');
    }
  }

  /// Stream location updates from a specific user
  Stream<UserLocation?> streamUserLocation(String userId) {
    return _database
        .child('$_locationsPath/$userId')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return null;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      return UserLocation.fromMap(userId, data);
    });
  }

  /// Stream locations from all active relations
  Stream<Map<String, UserLocation>> streamAllRelatedLocations() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value({});

    return RelationService().getActiveRelations().asyncMap((relations) async {
      final locations = <String, UserLocation>{};

      for (final relation in relations) {
        final otherUserId = relation.getOtherUserId(user.uid);
        final location = await getUserLocation(otherUserId);
        if (location.success && location.location != null) {
          locations[otherUserId] = location.location!;
        }
      }

      return locations;
    });
  }

  /// Stop sharing location with a specific user
  Future<void> stopSharingWithUser(String userId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _database
        .child('$_locationsPath/${user.uid}/sharedWith/$userId')
        .remove();
  }

  /// Check if a user's location is available
  Future<bool> isUserLocationAvailable(String userId) async {
    try {
      final snapshot =
          await _database.child('$_locationsPath/$userId/lastUpdate').once();
      if (snapshot.snapshot.value == null) return false;

      final timestamp = snapshot.snapshot.value as int;
      return UserLocation._isRecentlyUpdated(timestamp);
    } catch (e) {
      return false;
    }
  }

  /// Get the current position once
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculate distance between two users
  double calculateDistance(LatLng pos1, LatLng pos2) {
    const distance = Distance();
    return distance(pos1, pos2);
  }

  /// Format distance for display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }
}

