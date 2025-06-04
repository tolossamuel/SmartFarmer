import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartfarmer/auth/authscreen.dart';
import 'package:smartfarmer/auth/signin.dart';
import 'package:smartfarmer/provider/lang_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, String>> _getPageData(int index, BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: true);
     final pageKey = 'page${index + 1}';
    return [
      {
        'title':
            lang.getNestedText(['onboarding', 'page1', 'title']).toString(),
        'subtitle':
            lang.getNestedText(['onboarding', 'page1', 'subtitle']).toString(),
        'description':
            lang.getNestedText([
              'onboarding',
              'page1',
              'description',
            ]).toString(),
      },
      {
        'title':
            lang.getNestedText(['onboarding', 'page2', 'title']).toString(),
        'subtitle':
            lang.getNestedText(['onboarding', 'page2', 'subtitle']).toString(),
        'description':
            lang.getNestedText([
              'onboarding',
              'page2',
              'description',
            ]).toString(),
      },
      {
        'title':
            lang.getNestedText(['onboarding', 'page3', 'title']).toString(),
        'subtitle':
            lang.getNestedText(['onboarding', 'page3', 'subtitle']).toString(),
        'description':
            lang.getNestedText([
              'onboarding',
              'page3',
              'description',
            ]).toString(),
      },
      {
        'title':
            lang.getNestedText(['onboarding', 'page4', 'title']).toString(),
        'subtitle':
            lang.getNestedText(['onboarding', 'page4', 'subtitle']).toString(),
        'description':
            lang.getNestedText([
              'onboarding',
              'page4',
              'description',
            ]).toString(),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: true);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      body: SafeArea(
        child: Column(
          children: [
            // Language Toggle Button
            Padding(
              padding: const EdgeInsets.only(
                top: 10.0,
                right: 16.0,
                left: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        () => lang.changeLanguage(
                          lang.currentLanguage == 'en' ? 'hi' : 'en',
                        ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      backgroundColor: Colors.white.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: BorderSide(
                          color: const Color(0xFF2E7D32).withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: Text(
                      lang.currentLanguage == 'en' ? 'हिन्दी' : 'English',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight:FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount:4,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _getPageData(index, context)[index];
                  return OnboardingPage(
                    title: page['title']!,
                    subtitle: page['subtitle']!,
                    description: page['description']!,
                    image: _getIconForPage(index),
                  );
                },
              ),
            ),
           Padding(
  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Skip button
      if (_currentPage < 3) // Since you have 4 pages (0-3 index)
        TextButton(
          onPressed: () => _pageController.animateToPage(
            3, // Jump to last page
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
          ),
          child: Text(lang.getText('skip')),
        )
      else
        const SizedBox(width: 48),
      
      // Page indicators
      Row(
        children: List.generate(
          4, // Fixed to 4 pages
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentPage == index
                  ? const Color(0xFF2E7D32)
                  : Colors.grey.withOpacity(0.4),
            ),
          ),
        ),
      ),
      
      // Next/Get Started button
      ElevatedButton(
        onPressed: () {
          if (_currentPage < 3) { // If not last page
            _pageController.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.ease,
            );
          } else { // If on last page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AuthScreen()),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            _currentPage < 3 // If not last page
                ? lang.getText('next')
                : lang.getText('get_started'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    ],
  ),
),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                lang.getText('navigation_hint'),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForPage(int index) {
    switch (index) {
      case 0:
        return Icons.agriculture;
      case 1:
        return Icons.wb_sunny;
      case 2:
        return Icons.camera_alt;
      case 3:
        return Icons.chat;
      default:
        return Icons.help;
    }
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData image;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(image, size: 100, color: const Color(0xFF2E7D32)),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
