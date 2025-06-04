import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smartfarmer/screens/news.dart';

Future<List<NewsArticle>> fetchAgriculturalNews() async {
  final apiKey = 'd7a46317181c47799bf84d5e973f0ce1';
  final query =
      'AGRICULTURE AND INDIA OR INDIA FARMERS OR CROPS INDIA OR LIVESTOCK INDIA';

  final url =
      'https://newsapi.org/v2/everything?q=$query&language=en&sortBy=publishedAt&apiKey=$apiKey';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final List articles = data['articles'];
    return articles.map((json) => NewsArticle.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load news');
  }
}
