import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:smartfarmer/screens/news.dart';

Future<List<NewsArticle>> fetchAgriculturalNews() async {
  final apiKey = dotenv.env['NEWSAPI_KEY'] ;

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
