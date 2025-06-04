class WeatherData {
  final String cityName;
  final double temperature;
  final double humidity;
  final double windSpeed;
  final double pressure;
  final double? rainfall;
  final String description;
  final String icon;

  WeatherData({
    required this.cityName,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    this.rainfall,
    required this.description,
    required this.icon,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['name'] ?? 'Unknown Location',
      temperature: _toDouble(json['main']['temp']),
      humidity: _toDouble(json['main']['humidity']),
      windSpeed: _toDouble(json['wind']['speed']),
      pressure: _toDouble(json['main']['pressure']),
      rainfall: json['rain'] != null ? _toDouble(json['rain']['1h']) : null,
      description: json['weather'][0]['description'] ?? '',
      icon: json['weather'][0]['icon'] ?? '',
    );
  }

  static double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
