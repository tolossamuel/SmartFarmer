import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfarmer/profile/models/edit_profile.dart';
import 'package:smartfarmer/provider/lang_provider.dart'; // Assuming UserProfile is defined here

// Mock UserProfile class if not available - for compilation purposes.
// Remove this if you have UserProfile defined in your project.
// class UserProfile {
//   final String id;
//   final String name;
//   final String email;
//   final String? phone;
//   final String? location;
//
//   UserProfile({
//     required this.id,
//     required this.name,
//     required this.email,
//     this.phone,
//     this.location,
//   });
// }

class EditProfileScreen extends StatefulWidget {
  final UserProfile currentUserProfile;

  const EditProfileScreen({super.key, required this.currentUserProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  late final TextEditingController _locationController;

  bool _isLoading = false;
  bool _showSuccess = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.currentUserProfile.name,
    );
    _emailController = TextEditingController(
      text: widget.currentUserProfile.email,
    );
   
    _locationController = TextEditingController(
      text: widget.currentUserProfile.location ?? '',
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
  
    _locationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.6)),
      prefixIcon: Icon(icon, color: theme.primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.primaryColor, width: 2.0),
      ),
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 18.0,
        horizontal: 15.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title:  Text(
          Provider.of<LanguageProvider>(
                    context,
                  ).getText('edit_profile'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        foregroundColor: theme.colorScheme.onSurface,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: mediaQuery.size.height * 0.02),
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.person_outline,
                          size: 50,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    SizedBox(height: mediaQuery.size.height * 0.04),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        Provider.of<LanguageProvider>(
                    context,
                  ).getText('full_name_label'),
                       Provider.of<LanguageProvider>(
                    context,
                  ).getText('full_name_label'),
                        Icons.person_rounded,
                      ),
                      enabled: !_isLoading,
                      validator:
                          (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Name cannot be empty'
                                  : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration(
                         Provider.of<LanguageProvider>(
                          context,
                        ).getText('email'),
                         Provider.of<LanguageProvider>(
                    context,
                  ).getText('email_label'),
                        Icons.email_rounded,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email cannot be empty';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                   
                    TextFormField(
                      controller: _locationController,
                      decoration: _inputDecoration(
                         Provider.of<LanguageProvider>(
                    context,
                  ).getText('location'),
                         Provider.of<LanguageProvider>(
                    context,
                  ).getText('location'),
                        Icons.location_on_rounded,
                      ),
                      enabled: !_isLoading,
                      validator:
                          (value) =>
                              (value == null || value.isEmpty)
                                  ? 'Location cannot be empty'
                                  : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    SizedBox(height: mediaQuery.size.height * 0.05),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save_alt_rounded),
                      label:  Text(
                        Provider.of<LanguageProvider>(
                    context,
                  ).getText('save_changes'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _isLoading ? null : _handleSaveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 5,
                      ),
                    ),
                    SizedBox(
                      height: mediaQuery.padding.bottom + 16,
                    ), // Space for FAB or bottom nav
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                        strokeWidth: 5,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Saving Profile...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_showSuccess)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 25,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.green.shade600,
                          size: 70,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Profile Updated!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your changes have been saved.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.8),
                          ),
                        ),
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

  void _handleSaveProfile() {
    if (_formKey.currentState!.validate()) {
      _saveProfile();
    } else {
      setState(() {
        _errorMessage = "Please correct the errors above.";
      });
      // Clear error message after some time
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // --- FUNCTIONALITY UNCHANGED ---
    try {
      // Validation is now handled by _formKey, but original check is kept for safety
      // though redundant if _handleSaveProfile is used.
      if (_nameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _locationController.text.isEmpty) {
        // This path should ideally not be hit if form validation is working.
        throw Exception('Name, email and location are required');
      }

      final updatedProfile = UserProfile(
        id: widget.currentUserProfile.id,
        name: _nameController.text,
        email: _emailController.text,
        location: _locationController.text,
        // phone: _phoneController.text.isNotEmpty ? _phoneController.text : null, // Still not including phone as per original
      );

      // Simulate network delay if you want to ensure loader visibility
      // await Future.delayed(const Duration(seconds: 2));

      final response = await http.put(
        Uri.parse('https://smartfarmer-iogu.onrender.com/updateInfo').replace(
          queryParameters: {
            'userId': updatedProfile.id,
            'email': updatedProfile.email,
            'name': updatedProfile.name,
            'country': updatedProfile.location,
          },
        ),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fullName', updatedProfile.name);
        await prefs.setString('email', updatedProfile.email);
        // As per original, updatedProfile.phone is likely null here
      
        await prefs.setString('country', updatedProfile.location ?? '');

        if (mounted) {
          setState(() {
            _isLoading = false;
            _showSuccess = true;
          });
          _animationController.forward(from: 0.0);

          Timer(const Duration(seconds: 3), () {
            // Show success for 3 seconds
            if (mounted) {
              Navigator.of(context).pop(); // Close the screen
            }
          });
        }
      } else {
        throw Exception(
          'Failed to update profile: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    }
    // The finally block for _isLoading = false is removed because
    // _isLoading is set to false in both success and error paths explicitly.
    // Or, if success, it stays true until _showSuccess takes over.
    // Corrected: _isLoading should be false before showing success or if error.
  }
}
