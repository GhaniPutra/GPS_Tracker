import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Result of invite code operations
class InviteResult {
  final bool success;
  final String? inviteCode;
  final String? errorMessage;
  final String? recipientUserId;

  InviteResult({
    required this.success,
    this.inviteCode,
    this.errorMessage,
    this.recipientUserId,
  });

  factory InviteResult.success(String code) =>
      InviteResult(success: true, inviteCode: code);

  factory InviteResult.error(String message) =>
      InviteResult(success: false, errorMessage: message);

  factory InviteResult.accepted(String userId) =>
      InviteResult(success: true, recipientUserId: userId);
}

/// Invite code data from Firebase
class InviteData {
  final String creatorId;
  final String status;
  final int createdAt;
  final int expiresAt;
  final String? creatorName;

  InviteData({
    required this.creatorId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.creatorName,
  });

  factory InviteData.fromMap(Map<String, dynamic> data) {
    return InviteData(
      creatorId: data['creatorId'] as String,
      status: data['status'] as String,
      createdAt: data['createdAt'] as int,
      expiresAt: data['expiresAt'] as int,
      creatorName: data['creatorName'] as String?,
    );
  }

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isExpiredOrAccepted => isExpired || isAccepted;
}

/// Service for managing invite codes
class InviteService {
  static const String _invitesPath = 'invites';
  static const String _userInvitesPath = 'user_invites';
  static const int _codeLength = 6;
  static const int _expiryHours = 24;
  static const Duration _expiryDuration = Duration(hours: _expiryHours);

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generate a random 6-character alphanumeric invite code
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(
      _codeLength,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Create a new invite code for the current user
  Future<InviteResult> createInvite({String? creatorName}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ Create Invite Error: User not authenticated');
        return InviteResult.error('User not authenticated');
      }

      debugPrint('✅ User authenticated: ${user.uid}');

      // REMOVE LIMIT - Allow creating new codes anytime
      // Optional: Cleanup old unused codes first
      await _cleanupUserUnusedInvites(user.uid);

      // Generate unique code
      String code;
      bool isUnique = false;
      int attempts = 0;

      do {
        code = _generateCode();
        debugPrint('🔄 Attempting code: $code');
        
        try {
          final snapshot = await _database
              .child('$_invitesPath/$code')
              .once()
              .timeout(const Duration(seconds: 10));
          isUnique = snapshot.snapshot.value == null;
          debugPrint('✅ Code check complete. Is unique: $isUnique');
        } catch (e) {
          debugPrint('❌ Error checking code uniqueness: $e');
          return InviteResult.error('Failed to check code: $e');
        }
        
        attempts++;
      } while (!isUnique && attempts < 10);

      if (!isUnique) {
        debugPrint('❌ Failed to generate unique code after $attempts attempts');
        return InviteResult.error('Failed to generate unique code');
      }

      debugPrint('🎯 Generated unique code: $code');

      final now = DateTime.now();
      final expiresAt = now.add(_expiryDuration).millisecondsSinceEpoch;

      final inviteData = {
        'creatorId': user.uid,
        'creatorName': creatorName ?? user.displayName ?? user.email ?? 'User',
        'status': 'pending',
        'createdAt': now.millisecondsSinceEpoch,
        'expiresAt': expiresAt,
      };

      debugPrint('📝 Writing invite data to: $_invitesPath/$code');

      try {
        await _database
            .child('$_invitesPath/$code')
            .set(inviteData)
            .timeout(const Duration(seconds: 10));
        debugPrint('✅ Invite written successfully');
      } catch (e) {
        debugPrint('❌ Error writing invite: $e');
        return InviteResult.error('Failed to write invite: $e');
      }

      try {
        await _database
            .child('$_userInvitesPath/${user.uid}/sent/$code')
            .set({'createdAt': now.millisecondsSinceEpoch})
            .timeout(const Duration(seconds: 10));
        debugPrint('✅ Invite tracked in user_invites');
      } catch (e) {
        debugPrint('⚠️ Error tracking invite (non-critical): $e');
      }

      debugPrint('🎉 Invite created successfully: $code');
      return InviteResult.success(code);
    } catch (e, stackTrace) {
      debugPrint('❌ Create Invite Error: $e');
      debugPrint('Stack trace: $stackTrace');
      return InviteResult.error('Failed to create invite: $e');
    }
  }

  /// Accept an invite code and create bidirectional relation
  Future<InviteResult> acceptInvite(String code) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return InviteResult.error('User not authenticated');
      }

      // Normalize code (uppercase, remove spaces)
      final normalizedCode = code.toUpperCase().replaceAll(' ', '');

      if (normalizedCode.length != _codeLength) {
        return InviteResult.error('Invalid invite code format');
      }

      // Get invite data
      final inviteRef = _database.child('$_invitesPath/$normalizedCode');
      final snapshot = await inviteRef.once();

      if (snapshot.snapshot.value == null) {
        return InviteResult.error('Invite code not found');
      }

      final data = Map<String, dynamic>.from(
        snapshot.snapshot.value as Map,
      );
      final invite = InviteData.fromMap(data);

      // Check if invite is still valid
      if (invite.isExpired) {
        await inviteRef.update({'status': 'expired'});
        return InviteResult.error('Invite code has expired');
      }

      if (invite.isAccepted) {
        return InviteResult.error('Invite code has already been used');
      }

      // Check if user is trying to invite themselves
      if (invite.creatorId == user.uid) {
        return InviteResult.error('Cannot use your own invite code');
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      // Create bidirectional relation
      final relationId = _generateRelationId(user.uid, invite.creatorId);
      final relationData = {
        'userA': user.uid,
        'userB': invite.creatorId,
        'userAName': user.displayName ?? user.email ?? 'User',
        'userBName': invite.creatorName ?? 'User',
        'status': 'active',
        'createdAt': now,
      };

      // Write to relations node
      await _database.child('relations/$relationId').set(relationData);

      // Create per-user relation indices for fast lookup
      await _database
          .child('user_relations/${user.uid}/${invite.creatorId}')
          .set({'relationId': relationId, 'status': 'active', 'createdAt': now});

      await _database
          .child('user_relations/${invite.creatorId}/${user.uid}')
          .set({'relationId': relationId, 'status': 'active', 'createdAt': now});

      // Mark invite as accepted
      await inviteRef.update({'status': 'accepted'});

      // Track in user's received invites
      await _database
          .child('$_userInvitesPath/${user.uid}/received/$normalizedCode')
          .set({'createdAt': now});

      // Update user's profile in database if needed
      await _updateUserProfile(user);

      return InviteResult.accepted(invite.creatorId);
    } catch (e) {
      return InviteResult.error('Failed to accept invite: $e');
    }
  }

  /// Cleanup unused (pending) invites from this user
  Future<void> _cleanupUserUnusedInvites(String userId) async {
    try {
      final snapshot = await _database
          .child('$_userInvitesPath/$userId/sent')
          .once();
      
      if (snapshot.snapshot.value == null) return;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      final updates = <String, dynamic>{};
      int cleanedCount = 0;
      
      for (final code in data.keys) {
        final inviteSnapshot = await _database.child('$_invitesPath/$code').once();
        
        if (inviteSnapshot.snapshot.value != null) {
          final inviteData = Map<String, dynamic>.from(
            inviteSnapshot.snapshot.value as Map
          );
          
          // Delete old pending invites (older than 1 day)
          if (inviteData['status'] == 'pending' && 
              now - (inviteData['createdAt'] as int) > 24 * 60 * 60 * 1000) {
            updates['$_invitesPath/$code'] = null;
            updates['$_userInvitesPath/$userId/sent/$code'] = null;
            cleanedCount++;
          }
          
          // Delete expired or accepted invites
          if (inviteData['status'] == 'expired' || inviteData['status'] == 'accepted') {
            updates['$_invitesPath/$code'] = null;
            updates['$_userInvitesPath/$userId/sent/$code'] = null;
            cleanedCount++;
          }
        }
      }
      
      if (updates.isNotEmpty) {
        await _database.update(updates);
        debugPrint('🧹 Cleaned up $cleanedCount old invites');
      }
    } catch (e) {
      debugPrint('⚠️ Cleanup error (non-critical): $e');
    }
  }

  /// Generate a consistent relation ID from two user IDs
  String _generateRelationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Update user profile in database
  Future<void> _updateUserProfile(User user) async {
    final profileData = {
      'name': user.displayName,
      'email': user.email,
      'photoURL': user.photoURL,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    profileData.removeWhere((key, value) => value == null);

    if (profileData.isNotEmpty) {
      await _database.child('users/${user.uid}/profile').update(profileData);
    }
  }

  /// Get invite details by code
  Future<InviteData?> getInvite(String code) async {
    try {
      final normalizedCode = code.toUpperCase().replaceAll(' ', '');
      final snapshot =
          await _database.child('$_invitesPath/$normalizedCode').once();

      if (snapshot.snapshot.value == null) return null;

      final data = Map<String, dynamic>.from(
        snapshot.snapshot.value as Map,
      );
      return InviteData.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  /// Cancel an invite (only by creator)
  Future<bool> cancelInvite(String code) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final normalizedCode = code.toUpperCase().replaceAll(' ', '');
      final snapshot =
          await _database.child('$_invitesPath/$normalizedCode').once();

      if (snapshot.snapshot.value == null) return false;

      final data = Map<String, dynamic>.from(
        snapshot.snapshot.value as Map,
      );

      if (data['creatorId'] != user.uid) return false;
      if (data['status'] != 'pending') return false;

      await _database.child('$_invitesPath/$normalizedCode').update({
        'status': 'expired'
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clean up expired invites
  Future<void> cleanupExpiredInvites() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final snapshot = await _database.child(_invitesPath).once();

      if (snapshot.snapshot.value == null) return;

      final updates = <String, dynamic>{};
      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);

      for (final entry in data.entries) {
        final code = entry.key;
        final inviteData = Map<String, dynamic>.from(entry.value as Map);

        if (inviteData['status'] == 'pending' &&
            (inviteData['expiresAt'] as int) < now) {
          updates['$code/status'] = 'expired';
        }
      }

      if (updates.isNotEmpty) {
        await _database.child(_invitesPath).update(updates);
      }
    } catch (e) {
      // Silent fail for cleanup
    }
  }

  /// Get invites sent by current user
  Stream<List<Map<String, dynamic>>> getSentInvites() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _database
        .child('$_userInvitesPath/${user.uid}/sent')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return [];

      return data.entries.map((e) {
        final code = e.key;
        final inviteData = Map<String, dynamic>.from(e.value as Map);
        return {...inviteData, 'code': code};
      }).toList()
        ..sort((a, b) => (b['createdAt'] as int).compareTo(a['createdAt'] as int));
    });
  }

  /// Get invites received by current user
  Stream<List<Map<String, dynamic>>> getReceivedInvites() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _database
        .child('$_userInvitesPath/${user.uid}/received')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return [];

      return data.entries.map((e) {
        final code = e.key;
        final inviteData = Map<String, dynamic>.from(e.value as Map);
        return {...inviteData, 'code': code};
      }).toList()
        ..sort((a, b) => (b['createdAt'] as int).compareTo(a['createdAt'] as int));
    });
  }

  /// Clean up old invites (call periodically, e.g., on app start)
  Future<void> cleanupOldInvites() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000); // 7 days
      final thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000); // 30 days

      final snapshot = await _database.child(_invitesPath).once();

      if (snapshot.snapshot.value == null) return;

      final updates = <String, dynamic>{};
      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      int deletedCount = 0;

      for (final entry in data.entries) {
        final code = entry.key;
        final inviteData = Map<String, dynamic>.from(entry.value as Map);

        final status = inviteData['status'] as String;
        final createdAt = inviteData['createdAt'] as int;
        final expiresAt = inviteData['expiresAt'] as int;

        // Delete if:
        // - Expired for more than 7 days
        // - Accepted for more than 30 days
        bool shouldDelete = false;

        if (status == 'expired' && expiresAt < sevenDaysAgo) {
          shouldDelete = true;
        } else if (status == 'accepted' && createdAt < thirtyDaysAgo) {
          shouldDelete = true;
        }

        if (shouldDelete) {
          updates['$_invitesPath/$code'] = null;
          updates['$_userInvitesPath/${inviteData['creatorId']}/sent/$code'] = null;
          deletedCount++;
        }
      }

      if (updates.isNotEmpty) {
        await _database.update(updates);
        debugPrint('🧹 Cleaned up $deletedCount old invites');
      }
    } catch (e) {
      debugPrint('⚠️ Cleanup failed: $e');
      // Silent fail - cleanup is not critical
    }
  }
}
