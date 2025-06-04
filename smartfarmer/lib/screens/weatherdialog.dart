import 'package:flutter/material.dart';

class WeatherAlertDialogContent extends StatelessWidget {
  final String location;
  final String temperature;
  final String weatherCondition;
  final Map<String, dynamic> fullWeatherData;
  final String backendResponse;

  const WeatherAlertDialogContent({
    super.key,
    required this.location,
    required this.temperature,
    required this.weatherCondition,
    required this.fullWeatherData,
    required this.backendResponse,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Weather in $location'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic weather info
            Text(
              'Temperature: $temperature°C',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Condition: $weatherCondition',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),

            // Backend response
            const Text(
              'Recommendation:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(backendResponse),
            const SizedBox(height: 16),

            // Detailed weather info (optional)
            const Text(
              'Detailed Info:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Humidity: ${fullWeatherData['main']['humidity']}%'),
            Text('Wind: ${fullWeatherData['wind']['speed']} m/s'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
