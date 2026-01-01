import 'dart:async';
import 'package:flutter/foundation.dart';
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
    if (user == null) {
      debugPrint('❌ Cannot start sharing: User not authenticated');
      return;
    }

    if (_isSharing) {
      debugPrint('⚠️ Location sharing already active');
      return;
    }
    
    debugPrint('🚀 Starting location sharing for user: ${user.uid}');
    _isSharing = true;

    // Get all active relations
    final relations = await RelationService().getActiveRelationsOnce();
    final sharedWith = relations.map((r) => r.getOtherUserId(user.uid)).toList();
    
    debugPrint('📡 Sharing location with ${sharedWith.length} users: $sharedWith');

    // Request location permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Location services are disabled');
      _isSharing = false;
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('📍 Current permission: $permission');
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      debugPrint('📍 Permission after request: $permission');
      if (permission == LocationPermission.denied) {
        debugPrint('❌ Location permission denied');
        _isSharing = false;
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Location permission permanently denied');
      _isSharing = false;
      throw Exception('Location permission permanently denied');
    }

    // Get initial position
    try {
      debugPrint('📍 Getting initial position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint('✅ Initial position: ${position.latitude}, ${position.longitude}');
      await _updateLocation(position.latitude, position.longitude, sharedWith);
    } catch (e) {
      debugPrint('⚠️ Failed to get initial position: $e');
    }

    // Start streaming updates
    debugPrint('🔄 Starting position stream...');
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: _minDistance.toInt(),
      ),
    ).listen((Position position) async {
      debugPrint('📍 Position update: ${position.latitude}, ${position.longitude}');
      final relations = await RelationService().getActiveRelationsOnce();
      final updatedSharedWith =
          relations.map((r) => r.getOtherUserId(user.uid)).toList();
      await _updateLocation(
          position.latitude, position.longitude, updatedSharedWith);
    }, onError: (error) {
      debugPrint('❌ Position stream error: $error');
    });
    
    debugPrint('✅ Location sharing started successfully');
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
    if (user == null) {
      debugPrint('❌ Cannot update location: User not authenticated');
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final locationData = {
      'lat': lat,
      'lng': lng,
      'lastUpdate': now,
    };

    debugPrint('📝 Updating location for ${user.uid}');
    debugPrint('   Coordinates: $lat, $lng');
    debugPrint('   Shared with: $sharedWith');

    try {
      // Update location
      await _database.child('$_locationsPath/${user.uid}').update(locationData);
      debugPrint('✅ Location updated in Firebase');

      // Update sharedWith list
      if (sharedWith.isNotEmpty) {
        final sharedWithMap = {for (final userId in sharedWith) userId: true};
        await _database
            .child('$_locationsPath/${user.uid}/sharedWith')
            .set(sharedWithMap);
        debugPrint('✅ SharedWith list updated: ${sharedWith.length} users');
      } else {
        debugPrint('⚠️ No users to share with');
      }
    } catch (e) {
      debugPrint('❌ Error updating location: $e');
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

  /// Stream locations from all active relations using Firebase Realtime Database
  /// This provides real-time updates instead of polling
  Stream<Map<String, UserLocation>> streamAllRelatedLocations() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ Cannot stream locations: User not authenticated');
      return Stream.value({});
    }

    debugPrint('🔄 Starting to stream locations for related users');

    // Get all active relations and create a combined stream
    return RelationService().getActiveRelations().asyncMap((relations) async {
      debugPrint('📡 Found ${relations.length} active relations');
      final userIds = relations.map((r) => r.getOtherUserId(user.uid)).toList();
      return userIds;
    }).asyncExpand((userIds) async* {
      if (userIds.isEmpty) {
        yield {};
        return;
      }

      debugPrint('🎯 Setting up Firebase listeners for ${userIds.length} users');

      // Create a stream that combines all user location streams
      final streams = userIds.map((userId) => streamUserLocation(userId)).toList();

      // Combine all streams into one
      final combinedStream = Stream<Map<String, UserLocation>>.multi((controller) {
        final locations = <String, UserLocation>{};
        final subscriptions = <StreamSubscription<dynamic>>[];

        for (int i = 0; i < userIds.length; i++) {
          final userId = userIds[i];
          subscriptions.add(streams[i].listen((location) {
            if (location != null) {
              locations[userId] = location;
              debugPrint('📍 Update for $userId: ${location.lat}, ${location.lng}');
            } else {
              locations.remove(userId);
              debugPrint('⚠️ Location removed for $userId');
            }
            // Emit a copy of locations
            controller.add(Map<String, UserLocation>.from(locations));
          }, onError: (error) {
            debugPrint('❌ Error streaming location for $userId: $error');
          }));
        }

        // Add initial empty map
        controller.add(locations);

        // Cleanup on cancel
        controller.onCancel = () {
          for (final sub in subscriptions) {
            sub.cancel();
          }
        };
      });

      yield* combinedStream;
    });
  }

  /// Alternative: Simple polling-based stream for fallback
  Stream<Map<String, UserLocation>> streamAllRelatedLocationsPolling() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ Cannot stream locations: User not authenticated');
      return Stream.value({});
    }

    debugPrint('🔄 Starting polling-based location stream');

    // Poll every 5 seconds as fallback
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      debugPrint('🔄 Polling locations...');
      final relations = await RelationService().getActiveRelationsOnce();
      final locations = <String, UserLocation>{};

      for (final relation in relations) {
        final otherUserId = relation.getOtherUserId(user.uid);
        final location = await getUserLocation(otherUserId);
        if (location.success && location.location != null) {
          locations[otherUserId] = location.location!;
        }
      }

      debugPrint('📊 Polled ${locations.length} locations');
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

