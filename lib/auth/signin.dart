import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfarmer/auth/signup.dart';
import 'package:smartfarmer/provider/lang_provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize language provider
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    languageProvider.init(languageProvider.currentLanguage);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        print(
          'Making login request to: https://smartfarmer-iogu.onrender.com/login',
        );
        print('Email: $email');
        print('Password: $password');

        final uri = Uri.parse(
          'https://smartfarmer-iogu.onrender.com/login',
        ).replace(queryParameters: {'email': email, 'password': password});

        final response = await http.post(uri);
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        final decodedResponse = json.decode(response.body);
        final responseData =
            decodedResponse is String
                ? json.decode(decodedResponse)
                : decodedResponse;

        if (response.statusCode == 200) {
          final success = responseData['success'] ?? false;

          if (success) {
            print('Login successful ✅');

            // Extract user data
            final user = responseData['user'];
            final userId = user['userId'];
            final fullName = user['full_name'];
            final country = user['country'];
            final email = user['email'];

            print(
              'User: $fullName, Email: $email, Country: $country, ID: $userId',
            );

            // ✅ Save user data to SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('userId', userId);
            await prefs.setString('email', email);
            await prefs.setString('fullName', fullName);
            await prefs.setString('country', country);
            await prefs.setBool(
              'isLoggedIn',
              true,
            ); // To check if user is logged in

            print('User data saved to SharedPreferences ✅');

            // Navigate to home screen
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            final message = responseData['message'] ?? 'Login failed';
            print('Login failed ❌: $message');
            _showErrorSnackBar(message);
          }
        } else {
          final fallbackMsg =
              responseData['message'] ?? 'Something went wrong. Try again.';
          print('Server error 🛑: $fallbackMsg');
          _showErrorSnackBar(fallbackMsg);
        }
      } catch (e) {
        print('Exception during login: $e');
        _showErrorSnackBar('Please Try Again');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );

    setState(() {
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final double headerVisualHeight = screenHeight * 0.30;
    const double cardTopRadius = 30.0;

    return Scaffold(
      backgroundColor: const Color(0xFF365C38),
      body: Stack(
        children: [
          // Green Header Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerVisualHeight + cardTopRadius,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF365C38), Color(0xFF5D8254)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Header Content
          Positioned(
            top: statusBarHeight + 20,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 30),
                ),
                const SizedBox(height: 20),
                Text(
                  languageProvider.getText('welcome_back'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  languageProvider.getText('sign_in_subtitle'),
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Language Toggle Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'English',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Switch(
                      value: languageProvider.currentLanguage == 'hi',
                      onChanged: (value) {
                        languageProvider.changeLanguage(value ? 'hi' : 'en');
                      },
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green.shade300,
                    ),
                    const Text(
                      'हिंदी',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // White Form Area
          Positioned.fill(
            top: headerVisualHeight,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(cardTopRadius),
                  topRight: Radius.circular(cardTopRadius),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24.0,
                  cardTopRadius + 10.0,
                  24.0,
                  30.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.getText('email_label'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3A6B35),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: languageProvider.getText('email_hint'),
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.green.shade600,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageProvider.getText(
                              'email_empty_error',
                            );
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return languageProvider.getText(
                              'email_invalid_error',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        languageProvider.getText('password_label'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3A6B35),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: languageProvider.getText('password_hint'),
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.green.shade600,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey.shade500,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageProvider.getText(
                              'password_empty_error',
                            );
                          }
                          if (value.length < 6) {
                            return languageProvider.getText(
                              'password_short_error',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF66BB6A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                  : Text(
                                    languageProvider.getText('sign_in_button'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: languageProvider.getText(
                                  'no_account_text',
                                ),
                              ),
                              TextSpan(
                                text: languageProvider.getText(
                                  'create_account_link',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const SignUpScreen(),
                                          ),
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
