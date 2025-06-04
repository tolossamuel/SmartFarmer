// lib/model/user_model.dart
import 'dart:convert';

class UserModel {
  final String email;
  final String name;
  final String country;
  final String? userId;
  final String? token;

  UserModel({
    required this.email,
    required this.name,
    required this.country,

    required this.userId,
    this.token,
  });

  // Convert UserModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'country': country,
      'userId': userId,
      'token': token,
    };
  }

  // Create UserModel from a Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      country: map['country'] ?? '',
      userId: map['userId'],
      token: map['token'],
    );
  }

  // Convert to JSON string
  String toJson() => json.encode(toMap());

  // Create from JSON string
  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));
}
