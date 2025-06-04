import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfarmer/profile/profilescreen.dart';
import 'package:smartfarmer/provider/lang_provider.dart';
import 'package:smartfarmer/screens/chatai.dart';
import 'package:smartfarmer/screens/dd.dart';
import 'package:smartfarmer/screens/news.dart';
import 'package:smartfarmer/screens/onboarding/onboardingscreen.dart';
import 'package:smartfarmer/screens/weatherdialog.dart';
import 'package:smartfarmer/screens/weatherscreen.dart';
import 'package:smartfarmer/service/weather_service.dart';

class FarmDashboardScreen extends StatefulWidget {
  const FarmDashboardScreen({super.key});

  @override
  State<FarmDashboardScreen> createState() => _FarmDashboardScreenState();
}

class _FarmDashboardScreenState extends State<FarmDashboardScreen> {
  String getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);

    if (hour < 12) {
      return langProvider.getText('good_morning');
    } else if (hour < 17) {
      return langProvider.getText('good_afternoon');
    } else if (hour < 21) {
      return langProvider.getText('good_evening');
    } else {
      return langProvider.getText('good_night');
    }
  }

  List<String> farmingTipKeys = [
    "farming_tip_1",
    "farming_tip_2",
    "farming_tip_3",
    "farming_tip_4",
    "farming_tip_5",
  ];
  String fullName = 'Guest'; // Default full name
  String weatherMessage = 'Loading weather...'; // Default weather message
  String temperature = '0'; // Default temperature
  String weatherDescription = 'Unknown'; // Default weather description

  final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '9e558e3fa2a50dcac6d291ff0e018ec8';

  late Timer _timer;
  int currentTipIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      setState(() {
        currentTipIndex = Random().nextInt(farmingTipKeys.length);
      });
    });
    _loadFullName();
    _fetchWeather();
  }

  Future<void> _loadFullName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString('fullName') ?? 'Guest';
    });
  }

  Future<void> _fetchWeather() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        weatherMessage = 'Location services are disabled';
        temperature = '0';
        weatherDescription = 'Unknown';
      });
      return;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          weatherMessage = 'Location permissions denied';
          temperature = '0';
          weatherDescription = 'Unknown';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        weatherMessage = 'Location permissions permanently denied';
        temperature = '0';
        weatherDescription = 'Unknown';
      });
      return;
    }

    try {
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Use latitude and longitude for the API call
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final temp = data['main']['temp'].toStringAsFixed(1);
        final description = data['weather'][0]['description'];
        final cityName = data['name']; // Get city name from API response
        setState(() {
          weatherMessage = 'Weather in $cityName';
          temperature = '$temp°C';
          weatherDescription = description;
        });
      } else {
        setState(() {
          weatherMessage = 'Failed to load weather';
          temperature = '0';
          weatherDescription = 'Unknown';
        });
      }
    } catch (e) {
      setState(() {
        weatherMessage = 'Error fetching weather';
        temperature = '0';
        weatherDescription = 'Unknown';
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: true);
    return SafeArea(
      child: SafeArea(
        child: Scaffold(
          body: SingleChildScrollView(
          
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Good Morning Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A6B35),
                   borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16.0),
                      bottomRight: Radius.circular(16.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Top Row (Icon + Title + Avatar)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// Leading Icon
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF577C52),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
          
                          /// Title & Subtitle
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    langProvider.getText('dashboard_title'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    langProvider.getText('dashboard_subtitle'),
                                    style: TextStyle(
                                      color: Color(0xFFC8E6C9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
          
                          /// Avatar
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyProfileScreen(),
                                ),
                              );
                            },
                            child: const CircleAvatar(
                              backgroundColor: Color(0xFF9CCC65),
                              child: Icon(
                                Icons.person,
                                color: Color(0xFF33691E),
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
          
                      const SizedBox(height: 16),
          
                      /// Weather Info Row
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9CCC65),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          children: [
                            /// Sun Icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEB3B),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.wb_sunny,
                                color: Color(0xFFF57F17),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
          
                            /// Greeting & Message
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getGreeting(context),
                                    style: TextStyle(
                                      color: Color(0xFF333333),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    fullName,
                                    style: TextStyle(
                                      color: Color(0xFF333333),
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    weatherMessage,
                                    style: TextStyle(
                                      color: Color(0xFF555555),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
          
                            /// Temp Info
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  temperature,
                                  style: TextStyle(
                                    color: Color(0xFF333333),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26,
                                  ),
                                ),
                                Text(
                                  weatherDescription,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
          
                // Feature Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1 / 1.05,
                  children: [
                    FeatureCard(
                      ontap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AiFarmingAssistantScreen(),
                          ),
                        );
                      },
                      icon: Icons.chat_bubble_outline,
                      iconBgColor: Color(0xFFE8F5E9),
                      iconColor: Color(0xFF388E3C),
                      title: langProvider.getText('expert_chat'),
                      subtitle: langProvider.getText('expert_chat_subtitle'),
                      statusText: langProvider.getText('expert_chat_status'),
                      statusColor: Color(0xFF4CAF50),
                    ),
                    FeatureCard(
                      ontap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CropDiseaseDetectionScreen(),
                          ),
                        );
                      },
                      icon: Icons.document_scanner_outlined,
                      iconBgColor: Color(0xFFFFF3E0),
                      iconColor: Color(0xFFFB8C00),
                      title: langProvider.getText('crop_scanner'),
                      subtitle: langProvider.getText('crop_scanner_subtitle'),
                      statusText: langProvider.getText('crop_scanner_status'),
                      statusColor: Color(0xFFFF9800),
                    ),
                    FeatureCard(
                      ontap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WeatherScreen(),
                          ),
                        );
                      },
                      icon: Icons.wb_cloudy_outlined,
                      iconBgColor: Color(0xFFE3F2FD),
                      iconColor: Color(0xFF1976D2),
                      title: langProvider.getText('weather'),
                      subtitle: langProvider.getText('weather_forecast'),
                      statusText: langProvider.getText('weather_status'),
                      statusColor: Color(0xFF2196F3),
                    ),
                    FeatureCard(
                      ontap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AgricultureNewsScreen(),
                          ),
                        );
                      },
                      icon: Icons.article_outlined,
                      iconBgColor: Color(0xFFF3E5F5),
                      iconColor: Color(0xFF8E24AA),
                      title: langProvider.getText('agri_news'),
                      subtitle: langProvider.getText('agri_news_subtitle'),
                      statusText: langProvider.getText('agri_news_status'),
                      statusColor: Color(0xFF9C27B0),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
          
                // Today's Farming Tip
                Padding(
                  padding: EdgeInsets.only(left: 20 , right:20),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8BC34A),
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            color: Colors.grey[700],
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                langProvider.getText('farming_tip'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                langProvider.getText(
                                  farmingTipKeys[currentTipIndex],
                                ),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final VoidCallback ontap;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String statusText;
  final Color statusColor;

  const FeatureCard({
    super.key,
    required this.ontap,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: true);
    return InkWell(
      onTap: ontap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickStatItem extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String count;
  final String label;

  const QuickStatItem({
    super.key,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: true);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
