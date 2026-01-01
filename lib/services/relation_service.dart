import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Represents the status of a relation between two users
enum RelationStatus {
  pending('pending'),
  active('active'),
  revoked('revoked');

  final String value;
  const RelationStatus(this.value);

  factory RelationStatus.fromString(String value) {
    return values.firstWhere((e) => e.value == value);
  }
}

/// Data model for a user relation (bidirectional connection)
class Relation {
  final String relationId;
  final String userA;
  final String userB;
  final String userAName;
  final String userBName;
  final RelationStatus status;
  final DateTime createdAt;
  final DateTime? revokedAt;

  Relation({
    required this.relationId,
    required this.userA,
    required this.userB,
    required this.userAName,
    required this.userBName,
    required this.status,
    required this.createdAt,
    this.revokedAt,
  });

  /// Get the other user ID in the relation
  String getOtherUserId(String currentUserId) {
    return currentUserId == userA ? userB : userA;
  }

  /// Get the other user's name in the relation
  String getOtherUserName(String currentUserId) {
    return currentUserId == userA ? userBName : userAName;
  }

  /// Check if relation is active (not revoked)
  bool get isActive => status == RelationStatus.active;

  factory Relation.fromMap(String id, Map<String, dynamic> data) {
    return Relation(
      relationId: id,
      userA: data['userA'] as String,
      userB: data['userB'] as String,
      userAName: data['userAName'] as String? ?? 'User',
      userBName: data['userBName'] as String? ?? 'User',
      status: RelationStatus.fromString(data['status'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      revokedAt: data['revokedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['revokedAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'relationId': relationId,
      'userA': userA,
      'userB': userB,
      'userAName': userAName,
      'userBName': userBName,
      'status': status.value,
      'createdAt': createdAt.millisecondsSinceEpoch,
      if (revokedAt != null) 'revokedAt': revokedAt!.millisecondsSinceEpoch,
    };
  }
}

/// Result of relation operations
class RelationResult {
  final bool success;
  final String? errorMessage;
  final Relation? relation;

  RelationResult({required this.success, this.errorMessage, this.relation});

  factory RelationResult.success(Relation relation) =>
      RelationResult(success: true, relation: relation);

  factory RelationResult.error(String message) =>
      RelationResult(success: false, errorMessage: message);
}

/// Service for managing user-to-user relations (many-to-many connections)
class RelationService {
  static const String _relationsPath = 'relations';
  static const String _userRelationsPath = 'user_relations';

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generate a consistent relation ID from two user IDs
  String _generateRelationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Get all active relations for the current user
  Stream<List<Relation>> getActiveRelations() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _database
        .child('$_userRelationsPath/${user.uid}')
        .onValue
        .asyncMap((event) async {
      final data = event.snapshot.value as Map?;
      if (data == null) return [];

      final relations = <Relation>[];

      for (final entry in data.entries) {
        final relationInfo = Map<String, dynamic>.from(entry.value as Map);
        final relationId = relationInfo['relationId'] as String;

        final snapshot =
            await _database.child('$_relationsPath/$relationId').once();
        if (snapshot.snapshot.value == null) continue;

        final relationData =
            Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        final relation = Relation.fromMap(relationId, relationData);

        if (relation.isActive) {
          relations.add(relation);
        }
      }

      relations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return relations;
    });
  }

  /// Get active relations as a list (non-streaming)
  Future<List<Relation>> getActiveRelationsOnce() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot =
          await _database.child('$_userRelationsPath/${user.uid}').once();
      final data = snapshot.snapshot.value as Map?;
      if (data == null) return [];

      final relations = <Relation>[];

      for (final entry in data.entries) {
        final relationInfo = Map<String, dynamic>.from(entry.value as Map);
        final relationId = relationInfo['relationId'] as String;

        final relationSnapshot =
            await _database.child('$_relationsPath/$relationId').once();
        if (relationSnapshot.snapshot.value == null) continue;

        final relationData =
            Map<String, dynamic>.from(relationSnapshot.snapshot.value as Map);
        final relation = Relation.fromMap(relationId, relationData);

        if (relation.isActive) {
          relations.add(relation);
        }
      }

      relations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return relations;
    } catch (e) {
      return [];
    }
  }

  /// Revoke a relation (stop sharing location with this user)
  Future<RelationResult> revokeRelation(String otherUserId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return RelationResult.error('User not authenticated');
      }

      final relationId = _generateRelationId(user.uid, otherUserId);
      final now = DateTime.now().millisecondsSinceEpoch;

      // Update main relation
      await _database.child('$_relationsPath/$relationId').update({
        'status': RelationStatus.revoked.value,
        'revokedAt': now,
      });

      // Update per-user indices
      await _database
          .child('$_userRelationsPath/${user.uid}/$otherUserId')
          .update({'status': RelationStatus.revoked.value, 'revokedAt': now});

      await _database
          .child('$_userRelationsPath/$otherUserId/${user.uid}')
          .update({'status': RelationStatus.revoked.value, 'revokedAt': now});

      // Optionally remove from sharedWith in location
      await _database
          .child('user_locations/${user.uid}/sharedWith/$otherUserId')
          .remove();
      await _database
          .child('user_locations/$otherUserId/sharedWith/${user.uid}')
          .remove();

      return RelationResult.success(
          Relation(relationId: relationId, userA: user.uid, userB: otherUserId, userAName: '', userBName: '', status: RelationStatus.revoked, createdAt: DateTime.now(), revokedAt: DateTime.now()));
    } catch (e) {
      return RelationResult.error('Failed to revoke relation: $e');
    }
  }

  /// Check if a relation exists between current user and another user
  Future<bool> hasActiveRelation(String otherUserId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final relationId = _generateRelationId(user.uid, otherUserId);
      final snapshot =
          await _database.child('$_relationsPath/$relationId').once();

      if (snapshot.snapshot.value == null) return false;

      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      return data['status'] == RelationStatus.active.value;
    } catch (e) {
      return false;
    }
  }

  /// Get a specific relation by ID
  Future<Relation?> getRelation(String relationId) async {
    try {
      final snapshot =
          await _database.child('$_relationsPath/$relationId').once();

      if (snapshot.snapshot.value == null) return null;

      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      return Relation.fromMap(relationId, data);
    } catch (e) {
      return null;
    }
  }

  /// Get relation with a specific user
  Future<Relation?> getRelationWithUser(String otherUserId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final relationId = _generateRelationId(user.uid, otherUserId);
      return await getRelation(relationId);
    } catch (e) {
      return null;
    }
  }

  /// Get user info for a related user
  Future<UserModel?> getRelatedUserInfo(String userId) async {
    try {
      final snapshot = await _database.child('users/$userId/profile').once();

      if (snapshot.snapshot.value == null) {
        // Return minimal user info
        return UserModel(id: userId, name: 'User');
      }

      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      return UserModel(
        id: userId,
        name: data['name'] as String?,
        email: data['email'] as String?,
        photoUrl: data['photoURL'] as String?,
      );
    } catch (e) {
      return UserModel(id: userId);
    }
  }

  /// Get all revoked relations for history
  Stream<List<Relation>> getRevokedRelations() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _database
        .child('$_userRelationsPath/${user.uid}')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return [];

      final relations = <Relation>[];

      for (final entry in data.entries) {
        final relationInfo = Map<String, dynamic>.from(entry.value as Map);
        final relationId = relationInfo['relationId'] as String;
        final status = RelationStatus.fromString(relationInfo['status'] as String);

        if (status == RelationStatus.revoked) {
          // We need to get more details from the main relations node
          relations.add(Relation(
            relationId: relationId,
            userA: '',
            userB: entry.key,
            userAName: '',
            userBName: '',
            status: status,
            createdAt: DateTime.now(),
            revokedAt: DateTime.now(),
          ));
        }
      }

      return relations;
    });
  }

  /// Block a user (prevent future relations)
  Future<bool> blockUser(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      await _database
          .child('blocked_users/${currentUser.uid}/$userId')
          .set({'blockedAt': DateTime.now().millisecondsSinceEpoch});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final snapshot =
          await _database.child('blocked_users/${currentUser.uid}/$userId').once();
      return snapshot.snapshot.value != null;
    } catch (e) {
      return false;
    }
  }
}

