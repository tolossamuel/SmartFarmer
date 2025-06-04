import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const String _userKey = 'user_data';

Future<void> saveUser(Map<String, dynamic> userData) async {
    try {
      // 1. Validate input data
      if (userData.isEmpty) {
        throw ArgumentError('User data cannot be empty');
      }

      // 2. Prepare required fields
      const requiredFields = ['id', 'email', 'token'];
      for (final field in requiredFields) {
        if (userData[field] == null || userData[field]!.toString().isEmpty) {
          throw ArgumentError('Missing required field: $field');
        }
      }

      // 3. Sanitize data
      final sanitizedData = {
        'id': userData['id'].toString(),
        'name': userData['name']?.toString() ?? '',
        'email': userData['email'].toString(),
        'country': userData['country']?.toString() ?? '',
        'token': userData['token'].toString(),
        // Add other fields as needed
        'saved_at': DateTime.now().toIso8601String(),
      };

      // 4. Convert to JSON
      final jsonString = json.encode(sanitizedData);
      if (jsonString.isEmpty) {
        throw FormatException('Failed to encode user data');
      }

      // 5. Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(_userKey, jsonString);

      if (!saved) {
        throw Exception('Failed to save user data to storage');
      }

      // 6. Debug output
      print('✅ User data saved successfully');
      print('📊 Saved data: ${sanitizedData.toString()}');
      print('📝 JSON string: $jsonString');

      // 7. Verify saved data
      await _verifySavedData(prefs);
    } catch (e, stackTrace) {
      print('❌ Error saving user data: $e');
      print('📜 Stack trace: $stackTrace');
      rethrow; // Or handle error as needed
    }
    
    
  }

   Future<void> _verifySavedData(SharedPreferences prefs) async {
    final savedData = prefs.getString(_userKey);
    if (savedData == null) {
      throw Exception('Verification failed: No data found in storage');
    }

    try {
      final decoded = json.decode(savedData) as Map<String, dynamic>;
      print('🔍 Verified saved data:');
      print('ID: ${decoded['id']}');
      print('Email: ${decoded['email']}');
      print(
        'Token: ${decoded['token']?.substring(0, 5)}...',
      ); // Don't log full token
      print('Saved at: ${decoded['saved_at']}');
    } catch (e) {
      throw FormatException('Verification failed: Corrupted data format');
    }
  }

  Future<Map<String, dynamic>?> getUser() async {
    print(_userKey);
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(_userKey);

    if (userString != null) {
      return json.decode(userString);
    }
    return null;
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<void> printSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      print("🧠 Saved User JSON:");
      print(userJson);

      final decoded = json.decode(userJson);
      print("🧑‍💻 Decoded User Map:");
      print(decoded);
    } else {
      print("🚫 No user data found in SharedPreferences.");
    }
  }

  init() {}
}
