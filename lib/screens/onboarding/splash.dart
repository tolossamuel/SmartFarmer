import 'package:flutter/material.dart';
import 'dart:async';

import 'package:smartfarmer/screens/onboarding/onboardingscreen.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  const SplashScreen({super.key, required this.isLoggedIn});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to appropriate screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (widget.isLoggedIn) {
        // If user is logged in, navigate to home screen
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // If user is not logged in, navigate to onboarding screen
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0), // Light green background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            // Image.asset(
            //   'assets/farmassist_logo.png', // Replace with your logo asset
            //   width: 120,
            //   height: 120,
            //   // Fallback icon if image not available
            //   errorBuilder:
            //       (context, error, stackTrace) => const Icon(
            //         Icons.agriculture,
            //         size: 100,
            //         color: Color(0xFF2E7D32),
            //       ),
            // ),
            const SizedBox(height: 30),

            // App Name
            const Text(
              'FarmAssist',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32), // Dark green
              ),
            ),
            const SizedBox(height: 10),

            // Taglinenav
            const Text(
              'Smart Farming Dashboard',
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 40),

            // Loading indicator with text
            Column(
              children: [
                CircularProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF2E7D32),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Initiating FarmAssist...',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Footer
            const Text(
              'CS.Commerce',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
