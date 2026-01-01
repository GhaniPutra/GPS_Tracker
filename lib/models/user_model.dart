import 'package:flutter/material.dart';

/// Data model representing a user in the GPS Tracker app
class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? photoUrl;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    this.name,
    this.email,
    this.photoUrl,
    this.createdAt,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] as String?,
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (createdAt != null) 'createdAt': createdAt!.millisecondsSinceEpoch,
    };
  }

  /// Get display name, fallback to email or "User"
  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (email != null && email!.isNotEmpty) return email!.split('@')[0];
    return 'User';
  }

  /// Get initials for avatar
  String get initials {
    final namePart = name ?? email ?? 'User';
    return namePart
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase()
        .substring(0, 2);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Extension for user status colors
extension UserStatusColor on UserModel {
  Color getStatusColor(bool isOnline) {
    if (!isOnline) return const Color(0xFF94A3B8); // Gray for offline
    return const Color(0xFF22C55E); // Green for online
  }
}

