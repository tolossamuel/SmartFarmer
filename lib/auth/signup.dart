import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfarmer/auth/signin.dart';
import 'package:smartfarmer/provider/lang_provider.dart';
import 'package:smartfarmer/screens/homescreen.dart';
import 'package:smartfarmer/service/dropdown.dart';
 // Adjust import path

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _countryController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize language provider with saved language
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    SharedPreferences.getInstance().then((prefs) {
      final savedLang = prefs.getString('language') ?? 'en';
      print('Loading saved language: $savedLang');
      languageProvider.init(savedLang);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveUserDataToPrefs(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', user.name);
    await prefs.setString('userEmail', user.email);
    await prefs.setString('userCountry', user.country);
    await prefs.setBool('isLoggedIn', true);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage(
        languageProvider.getText('confirm_password_mismatch_error'),
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Construct URL with query parameters
      final url = Uri.parse(
        'https://smartfarmer-iogu.onrender.com/register',
      ).replace(
        queryParameters: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'name': _nameController.text.trim(),
          'country': _countryController.text.trim(),
        },
      );

      print('Sending registration request to: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Extract and save user data
        final prefs = await SharedPreferences.getInstance();

        // Try to get user data from different response structures
        final userData = responseData['user'] ?? responseData;
        final userId = userData['userId'] ?? userData['id'] ?? '';
        final email = userData['email'] ?? _emailController.text.trim();
        final name =
            userData['name'] ??
            userData['full_name'] ??
            _nameController.text.trim();
        final country = userData['country'] ?? _countryController.text.trim();

        // Save to SharedPreferences
        await prefs.setString('userId', userId);
        await prefs.setString('email', email);
        await prefs.setString('fullName', name);
        await prefs.setString('country', country);
        await prefs.setBool('isLoggedIn', true);

        // Print saved data
        print('Saved user data:');
        print('ID: $userId');
        print('Email: $email');
        print('Name: $name');
        print('Country: $country');

        _showMessage(
          responseData['message'] ??
              languageProvider.getText('registration_successful'),
          isError: false,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SignInScreen(),
            ),
          );
        }
      } else {
        // Handle different error response formats
        final errorMessage =
            responseData['message'] ??
            (responseData['detail'] is List
                ? responseData['detail'].map((e) => e['msg']).join(', ')
                : languageProvider.getText('registration_failed'));

        _showMessage(errorMessage, isError: true);
        print('Registration failed: $errorMessage');
      }
    } catch (e) {
      _showMessage(languageProvider.getText('network_error'), isError: true);
      print('Registration error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);

    final double headerVisualHeight = screenHeight * 0.28;
    const double cardTopRadius = 30.0;

    return Scaffold(
      backgroundColor: const Color(0xFFA0D468),
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
                  colors: [Color(0xFFA5D6A7), Color(0xFF66BB6A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Header Content
          Positioned(
            top: statusBarHeight + 15,
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
                  child: const Icon(
                    Icons.article_outlined,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  languageProvider.getText('join_farmassist'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  languageProvider.getText('signup_subtitle'),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Language Toggle Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      languageProvider.getText('english_label'),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Switch(
                      value: languageProvider.currentLanguage == 'hi',
                      onChanged: (value) {
                        languageProvider.changeLanguage(value ? 'hi' : 'en');
                      },
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green.shade300,
                    ),
                    Text(
                      languageProvider.getText('hindi_label'),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
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
                  cardTopRadius + 5.0,
                  24.0,
                  20.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextFieldLabel(
                        languageProvider.getText('full_name_label'),
                      ),
                      TextFormField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        style: const TextStyle(fontSize: 16),
                        decoration: _inputDecoration(
                          languageProvider.getText('full_name_hint'),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageProvider.getText(
                              'full_name_empty_error',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      _buildTextFieldLabel(
                        languageProvider.getText('email_label'),
                      ),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 16),
                        decoration: _inputDecoration(
                          languageProvider.getText('email_hint'),
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
                      const SizedBox(height: 18),

                      _buildTextFieldLabel(
                        languageProvider.getText('country_label'),
                      ),
                      CountryDropdown(
                        value:
                            _countryController.text.isNotEmpty
                                ? _countryController.text
                                : null,
                        onChanged: (value) {
                          _countryController.text = value ?? '';
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageProvider.getText(
                              'country_empty_error',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      _buildTextFieldLabel(
                        languageProvider.getText('password_label'),
                      ),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontSize: 16),
                        decoration: _inputDecoration(
                          languageProvider.getText('password_hint'),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey.shade500,
                            ),
                            onPressed:
                                () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
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
                      const SizedBox(height: 18),

                      _buildTextFieldLabel(
                        languageProvider.getText('confirm_password_label'),
                      ),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: const TextStyle(fontSize: 16),
                        decoration: _inputDecoration(
                          languageProvider.getText('confirm_password_hint'),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey.shade500,
                            ),
                            onPressed:
                                () => setState(
                                  () =>
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageProvider.getText(
                              'confirm_password_empty_error',
                            );
                          }
                          if (value != _passwordController.text) {
                            return languageProvider.getText(
                              'confirm_password_mismatch_error',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF66BB6A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                                    languageProvider.getText('create_account'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 20),

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
                                  'already_have_account',
                                ),
                              ),
                              TextSpan(
                                text: languageProvider.getText('sign_in'),
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
                                                    const SignInScreen(),
                                          ),
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: languageProvider.getText(
                                  'terms_and_privacy',
                                ),
                              ),
                              TextSpan(
                                text: languageProvider.getText(
                                  'terms_of_service',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF388E3C),
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () {
                                        debugPrint(
                                          'Navigate to Terms of Service',
                                        );
                                      },
                              ),
                              const TextSpan(text: " and \n"),
                              TextSpan(
                                text: languageProvider.getText(
                                  'privacy_policy',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF388E3C),
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () {
                                        debugPrint(
                                          'Navigate to Privacy Policy',
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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

  Widget _buildTextFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3A6B35),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
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
        borderSide: BorderSide(color: Colors.green.shade600, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
    );
  }
}

class UserModel {
  final String name;
  final String email;
  final String country;

  UserModel({required this.name, required this.email, required this.country});
}
