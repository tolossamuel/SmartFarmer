import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfarmer/auth/authscreen.dart';
import 'package:smartfarmer/auth/signin.dart';
import 'package:smartfarmer/auth/signup.dart';
import 'package:smartfarmer/provider/lang_provider.dart'; // Ensure this exists
import 'package:smartfarmer/screens/onboarding/onboardingscreen.dart';
import 'package:smartfarmer/screens/onboarding/splash.dart';
import 'package:smartfarmer/screens/homescreen.dart';
import 'package:smartfarmer/service/shared_prefs_serv.dart'; // Optional helper

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Check auth status
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  print('-------------------------------');
  print('User logged in status: $isLoggedIn');
  print('-------------------------------');

  // Get saved language or default to 'en'

  final savedLanguage = prefs.getString('language') ?? 'en';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create:
              (_) =>
                  LanguageProvider()
                    ..loadTranslations()
                    ..changeLanguage(savedLanguage),
        ),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(langProvider.currentLanguage), // Force language update
      home: SplashScreen(isLoggedIn: isLoggedIn),
      routes: {
        '/home': (context) => const FarmDashboardScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/authscreen':(context)=>AuthScreen()
      },
    );
  }
}
