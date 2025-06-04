import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:smartfarmer/provider/lang_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isCurrentPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  String? _statusMessage;
  Color _statusColor = Colors.transparent;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword(BuildContext context) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _statusColor = Colors.transparent;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      debugPrint('Attempting password change for user: $userId');

      final response = await http
          .put(
            Uri.parse(
              'https://smartfarmer-iogu.onrender.com/updatePassword',
            ).replace(
              queryParameters: {
                'userId': userId,
                'old_password': _currentPasswordController.text,
                'new_password': _newPasswordController.text,
              },
            ),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      dynamic responseData;
      try {
        responseData = json.decode(response.body);
        if (responseData is String) {
          responseData = json.decode(responseData);
        }
      } catch (e) {
        debugPrint('JSON decode error: $e');
        throw langProvider.getText('invalid_response');
      }

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          _showStatusMessage(
            langProvider.getText('password_changed_success'),
            Colors.green,
          );
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.of(context).pop();
        } else {
          throw responseData['message'] ??
              langProvider.getText('failed_to_change_password');
        }
      } else {
        throw responseData['message'] ??
            '${langProvider.getText('server_error')} (${response.statusCode})';
      }
    } on http.ClientException catch (e) {
      _showStatusMessage(langProvider.getText('network_error'), Colors.red);
      debugPrint('Network exception: ${e.message}');
    } on TimeoutException {
      _showStatusMessage(langProvider.getText('request_timeout'), Colors.red);
      debugPrint('Request timeout');
    } catch (e) {
      _showStatusMessage(e.toString(), Colors.red);
      debugPrint('Error changing password: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showStatusMessage(String message, Color color) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
        _statusColor = color;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_statusMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _statusColor == Colors.green
                            ? Icons.check_circle
                            : Icons.error,
                        color: _statusColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(color: _statusColor),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                langProvider.getText('create_new_password'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                langProvider.getText('password_must_be_different'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _isCurrentPasswordObscured,
                decoration: InputDecoration(
                  labelText: langProvider.getText('current_password'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isCurrentPasswordObscured
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isCurrentPasswordObscured =
                            !_isCurrentPasswordObscured;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return langProvider.getText('enter_current_password');
                  }
                  if (value.length < 6) {
                    return langProvider.getText('password_min_length');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _isNewPasswordObscured,
                decoration: InputDecoration(
                  labelText: langProvider.getText('new_password'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_person_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordObscured
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPasswordObscured = !_isNewPasswordObscured;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return langProvider.getText('enter_new_password');
                  }
                  if (value.length < 6) {
                    return langProvider.getText('password_min_length');
                  }
                  if (value == _currentPasswordController.text) {
                    return langProvider.getText('new_password_different');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _isConfirmPasswordObscured,
                decoration: InputDecoration(
                  labelText: langProvider.getText('confirm_new_password'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_person_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordObscured
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordObscured =
                            !_isConfirmPasswordObscured;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return langProvider.getText('confirm_password');
                  }
                  if (value != _newPasswordController.text) {
                    return langProvider.getText('passwords_do_not_match');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed:
                    _isLoading ? null : () => _handleChangePassword(context),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Text(
                          langProvider.getText('update_password'),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
