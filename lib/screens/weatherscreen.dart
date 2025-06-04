import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // For TimeoutException
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:smartfarmer/provider/lang_provider.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? currentWeather;
  Position? currentPosition;
  String weatherDescription = '';
  bool isLoading = false;
  bool isFetchingDescription = false;
  String errorMessage = '';

  // Define timeout durations
  static const Duration _locationTimeoutDuration = Duration(seconds: 45);
  static const Duration _weatherApiTimeoutDuration = Duration(seconds: 20);
  static const Duration _backendApiTimeoutDuration = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    debugPrint('Starting to fetch weather data...');
    if (mounted) {
      // Mounted check
      setState(() {
        isLoading = true;
        errorMessage = '';
        weatherDescription = ''; // Clear previous description
      });
    }

    try {
      debugPrint('Getting current position...');
      currentPosition = await _determinePosition();
      debugPrint(
        'Position obtained: ${currentPosition!.latitude}, ${currentPosition!.longitude}',
      );

      debugPrint('Fetching weather data from OpenWeather...');
      final weatherData = await _fetchWeather(
        currentPosition!.latitude,
        currentPosition!.longitude,
      );
      debugPrint('Weather data received: ${weatherData.toString()}');

      if (mounted) {
        // Mounted check
        setState(() {
          currentWeather = weatherData;
        });
      }
    } on TimeoutException catch (e) {
      debugPrint('A timeout occurred: ${e.message}');
      String userFriendlyMessage = 'The operation timed out. ';
      if (e.message?.contains('location timed out') ?? false) {
        userFriendlyMessage +=
            'Could not get your location. Please ensure GPS is enabled and you have a clear sky view.';
      } else if (e.message?.contains('OpenWeatherMap timed out') ?? false) {
        userFriendlyMessage +=
            'Could not retrieve weather data from the server. Please check your internet connection.';
      } else {
        userFriendlyMessage +=
            'Please check your internet connection and try again.';
      }
      if (mounted) {
        // Mounted check
        setState(() {
          errorMessage = userFriendlyMessage;
          currentWeather = null; // Clear stale weather data
        });
      }
    } catch (e) {
      debugPrint('Error fetching weather data: ${e.toString()}');
      if (mounted) {
        // Mounted check
        setState(() {
          errorMessage = 'Failed to fetch weather data: ${e.toString()}';
          currentWeather = null; // Clear stale weather data
        });
      }
    } finally {
      debugPrint('Finished fetching weather data');
      if (mounted) {
        // Mounted check
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    debugPrint('Checking location services...');
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      const message =
          'Location services are disabled. Please enable them in your device settings.';
      debugPrint(message);
      throw Exception(message);
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      debugPrint('Requesting location permission...');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        const message =
            'Location permissions are denied. Weather data cannot be fetched without location access.';
        debugPrint(message);
        throw Exception(message);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      const message =
          'Location permissions are permanently denied. Please enable them in app settings to use this feature.';
      debugPrint(message);
      throw Exception(message);
    }

    debugPrint(
      'Getting current position with medium accuracy (timeout: ${_locationTimeoutDuration.inSeconds}s)...',
    );
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(
        _locationTimeoutDuration,
        onTimeout: () {
          final message =
              'Getting current location timed out after ${_locationTimeoutDuration.inSeconds} seconds.';
          debugPrint(message);
          throw TimeoutException(message, _locationTimeoutDuration);
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _fetchWeather(double lat, double lon) async {
    // const apiKey =
    //     '9e558e3fa2a50dcac6d291ff0e018ec8';
    // // Keep API keys out of VCS in real apps
    final apiKey =
        dotenv.env['OPENWEATHER_API_KEY'];
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
    );
    debugPrint(
      'Fetching weather from URL: $url (timeout: ${_weatherApiTimeoutDuration.inSeconds}s)',
    );

    final response = await http
        .get(url)
        .timeout(
          _weatherApiTimeoutDuration,
          onTimeout: () {
            final message =
                'Fetching weather data from OpenWeatherMap timed out after ${_weatherApiTimeoutDuration.inSeconds} seconds.';
            debugPrint(message);
            throw TimeoutException(message, _weatherApiTimeoutDuration);
          },
        );

    debugPrint('Weather API response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to load weather data from OpenWeatherMap. Status code: ${response.statusCode}. Body: ${response.body}',
      );
    }
  }

  Future<void> _fetchWeatherDescription() async {
    if (currentWeather == null || currentPosition == null) {
      debugPrint(
        '[Weather Advice] Cannot fetch description - weather or position data missing',
      );
      if (mounted) {
        setState(() {
          errorMessage = 'Weather data not available to get advice.';
        });
      }
      return;
    }

    debugPrint('[Weather Advice] Starting to fetch weather description...');
    if (mounted) {
      setState(() {
        isFetchingDescription = true;
        errorMessage = '';
      });
    }

    try {
      final weatherDesc = currentWeather!['weather'][0]['description'];
      final temperature = currentWeather!['main']['temp'];
      final locationName = currentWeather!['name'];
      final lat = currentPosition!.latitude;
      final lon = currentPosition!.longitude;

      debugPrint('[Weather Advice] Current weather data:');
      debugPrint('- Description: $weatherDesc');
      debugPrint('- Temperature: ${temperature.toStringAsFixed(1)}°C');
      debugPrint('- Location: $locationName');
      debugPrint('- Coordinates: ($lat, $lon)');

      const backendUrl = 'https://smartfarmer-iogu.onrender.com';
      final Uri url = Uri.parse('$backendUrl/weather-discription').replace(
        queryParameters: {
          'user_input':
              'Weather:$weatherDesc,Temperature:$temperature°C,Location:$locationName,Coordinates:$lat,$lon',
        },
      );

      debugPrint('[Weather Advice] Sending request to: $url');
      debugPrint(
        '[Weather Advice] Timeout: ${_backendApiTimeoutDuration.inSeconds}s',
      );

      final response = await http
          .get(url)
          .timeout(
            _backendApiTimeoutDuration,
            onTimeout: () {
              debugPrint('[Weather Advice] Request timed out');
              throw TimeoutException(
                'Backend request timed out',
                _backendApiTimeoutDuration,
              );
            },
          );

      debugPrint(
        '[Weather Advice] Response received. Status: ${response.statusCode}',
      );
      debugPrint('[Weather Advice] Response headers: ${response.headers}');
      debugPrint(
        '[Weather Advice] Response body (first 200 chars): ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}',
      );

      if (response.statusCode == 200) {
        String newDescription;
        try {
          final decodedBody = json.decode(response.body);
          debugPrint('[Weather Advice] Decoded response body: $decodedBody');

          // Extract description from different possible response formats
          if (decodedBody is Map) {
            if (decodedBody.containsKey('generated_text')) {
              newDescription = decodedBody['generated_text'] as String;
            } else if (decodedBody.containsKey('description')) {
              newDescription = decodedBody['description'] as String;
            } else if (decodedBody.containsKey('message')) {
              newDescription = decodedBody['message'] as String;
            } else if (decodedBody.containsKey('advice')) {
              newDescription = decodedBody['advice'] as String;
            } else {
              // If none of the expected keys exist, try to use the first string value
              final firstStringValue = decodedBody.values.firstWhere(
                (value) => value is String,
                orElse: () => response.body,
              );
              newDescription = firstStringValue.toString();
            }
          } else {
            newDescription = response.body;
          }

          // Clean up the description if needed
          newDescription = newDescription.trim();
          if (newDescription.startsWith('"') && newDescription.endsWith('"')) {
            newDescription = newDescription.substring(
              1,
              newDescription.length - 1,
            );
          }

          debugPrint('[Weather Advice] Extracted description: $newDescription');
        } catch (e) {
          debugPrint('[Weather Advice] JSON parsing error: $e');
          newDescription = response.body;
        }

        if (mounted) {
          setState(() {
            weatherDescription = newDescription;
          });
        }
      } else {
        debugPrint('[Weather Advice] Error response body: ${response.body}');
        throw HttpException(
          'Failed to load weather advice (Status ${response.statusCode})',
          uri: url,
        );
      }
    } on TimeoutException catch (e) {
      debugPrint('[Weather Advice] Timeout error: ${e.message}');
      if (mounted) {
        setState(() {
          errorMessage = 'Request timed out. Please try again later.';
          weatherDescription = '';
        });
      }
    } on SocketException catch (e) {
      debugPrint('[Weather Advice] Network error: ${e.message}');
      if (mounted) {
        setState(() {
          errorMessage =
              'Network error. Please check your internet connection.';
          weatherDescription = '';
        });
      }
    } on HttpException catch (e) {
      debugPrint('[Weather Advice] HTTP error: ${e.message}');
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to fetch weather advice from server.';
          weatherDescription = '';
        });
      }
    } catch (e) {
      debugPrint('[Weather Advice] Unexpected error: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'An unexpected error occurred.';
          weatherDescription = '';
        });
      }
    } finally {
      debugPrint('[Weather Advice] Fetch completed');
      if (mounted) {
        setState(() {
          isFetchingDescription = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          langProvider.getText('weather_alert'),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _fetchWeatherData,
            tooltip: langProvider.getText('refresh'),
            color: Colors.white,
          ),
        ],
      ),
      body: Container(
        color: Colors.blue[50], // Light blue background
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              isLoading
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          langProvider.getText('fetching_weather_data'),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh: _fetchWeatherData,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (errorMessage.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Text(
                              errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        if (currentWeather != null) ...[
                          // Weather Card - matching dialog style
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentWeather!['name'],
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        '${currentWeather!['main']['temp']}°C',
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currentWeather!['weather'][0]['main'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                            ),
                                          ),
                                          Text(
                                            '${langProvider.getText('feels_like')}: ${currentWeather!['main']['feels_like']}°C',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    langProvider.getText(
                                      'detailed_weather_info',
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${langProvider.getText('humidity')}: ${currentWeather!['main']['humidity']}%',
                                  ),
                                  Text(
                                    '${langProvider.getText('wind')}: ${currentWeather!['wind']['speed']} m/s',
                                  ),
                                  Text(
                                    '${langProvider.getText('pressure')}: ${currentWeather!['main']['pressure']} hPa',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Farming Advice Section
                          if (weatherDescription.isNotEmpty)
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      langProvider.getText(
                                        'farming_recommendations',
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      weatherDescription,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed:
                                isFetchingDescription || isLoading
                                    ? null
                                    : _fetchWeatherDescription,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                isFetchingDescription
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                    : Text(
                                      langProvider.getText(
                                        'get_farming_advice',
                                      ),
                                    ),
                          ),
                        ] else if (!isLoading && errorMessage.isEmpty)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.cloud_off,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  langProvider.getText(
                                    'weather_data_unavailable',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _fetchWeatherData,
                                  child: Text(
                                    langProvider.getText('try_again'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }
}
