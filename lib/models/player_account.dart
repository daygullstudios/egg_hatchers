import 'package:flutter/material.dart';

class PlayerAccount {
  const PlayerAccount({
    required this.id,
    required this.displayName,
    required this.username,
    required this.avatarColorValue,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String username;
  final int avatarColorValue;
  final DateTime createdAt;

  Color get avatarColor => Color(avatarColorValue);

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'username': username,
    'avatarColorValue': avatarColorValue,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PlayerAccount.fromJson(Map<String, dynamic> json) {
    return PlayerAccount(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      username: json['username'] as String,
      avatarColorValue: json['avatarColorValue'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
