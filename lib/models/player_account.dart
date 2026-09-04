import 'package:flutter/material.dart';

class PlayerAccount {
  const PlayerAccount({
    required this.id,
    required this.displayName,
    required this.username,
    required this.avatarColorValue,
    required this.createdAt,
    this.isGuest = false,
  });

  final String id;
  final String displayName;
  final String username;
  final int avatarColorValue;
  final DateTime createdAt;
  final bool isGuest;

  Color get avatarColor => Color(avatarColorValue);
  String get identityLabel =>
      isGuest ? 'Guest · saved on this device' : '@$username';
  String get localProfileLabel =>
      isGuest ? identityLabel : 'Local profile · @$username';

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'username': username,
    'avatarColorValue': avatarColorValue,
    'createdAt': createdAt.toIso8601String(),
    'isGuest': isGuest,
  };

  factory PlayerAccount.fromJson(Map<String, dynamic> json) {
    return PlayerAccount(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      username: json['username'] as String,
      avatarColorValue: json['avatarColorValue'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isGuest: json['isGuest'] as bool? ?? false,
    );
  }
}
