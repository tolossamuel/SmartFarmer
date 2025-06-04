import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://smartfarmer-iogu.onrender.com';

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String country,
  }) async {
    final url = Uri.parse('$baseUrl/register').replace(
      queryParameters: {
        'email': email,
        'password': password,
        'name': name,
        'country': country,
      },
    );

    print('🌐 Making request to: $url');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    print('🔄 Response status: ${response.statusCode}');
    print('📄 Response body: ${response.body}');

    // Handle potential double-encoded JSON
    dynamic responseData;
    try {
      responseData = json.decode(response.body);
      if (responseData is String) {
        responseData = json.decode(responseData);
      }
    } catch (e) {
      throw FormatException('Failed to decode API response: ${e.toString()}');
    }

    if (response.statusCode == 200) {
      print('response is passing ');
      print(responseData);
      print('----------------------------------');
      return responseData as Map<String, dynamic>;
    } else {

      print('❌ Error: ${responseData['message'] ?? 'Unknown error'}');
      return {
        'success': false,
        'message': responseData['message'] ?? 'An error occurred',
      };
    }
  }

  // Add login method later
}
