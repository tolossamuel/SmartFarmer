import 'package:flutter/material.dart';
import 'package:smartfarmer/service/newsapi.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:smartfarmer/provider/lang_provider.dart';

class NewsArticle {
  final String imageUrl;
  final List<Tag> tags;
  final String timeAgo;
  final String title;
  final String description;
  final String source;
  final String readTime;
  final String imagePlaceholderText;
  final Color imagePlaceholderColor;
  final String url;

  NewsArticle({
    required this.imageUrl,
    required this.tags,
    required this.timeAgo,
    required this.title,
    required this.description,
    required this.source,
    required this.readTime,
    required this.imagePlaceholderText,
    required this.imagePlaceholderColor,
    required this.url,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      imageUrl: json['urlToImage'] ?? '',
      url: json['url'] ?? '',
      tags: _generateTags(json),
      timeAgo: _calculateTimeAgo(json['publishedAt']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      source: json['source']['name'] ?? '',
      readTime: _calculateReadTime(json['content']),
      imagePlaceholderText: (json['title'] ?? '').substring(0, 1),
      imagePlaceholderColor: _getRandomColor(),
    );
  }
}

List<Tag> _generateTags(Map<String, dynamic> json) {
  return [
    Tag(
      text: "news_tag",
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    ),
  ];
}

String _calculateTimeAgo(String publishedAt) {
  return "2 hours ago";
}

String _calculateReadTime(String? content) {
  return "3 min read";
}

Color _getRandomColor() {
  return Colors.green;
}

class Tag {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  Tag({
    required this.text,
    required this.backgroundColor,
    this.textColor = Colors.white,
  });
}

class AgricultureNewsScreen extends StatefulWidget {
  const AgricultureNewsScreen({super.key});

  @override
  State<AgricultureNewsScreen> createState() => _AgricultureNewsScreenState();
}

class _AgricultureNewsScreenState extends State<AgricultureNewsScreen> {
  List<NewsArticle> _newsArticles = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final articles = await fetchAgriculturalNews();
      setState(() {
        _newsArticles = articles;
        _isLoading = false;
      });
    } catch (e) {
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      setState(() {
        _errorMessage =
            '${lang.getText('failed_to_load_news')}: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  static const Color headerColor = Color(0xFF385434);
  static const Color primaryTextColor = Colors.white;
  static const Color secondaryTextColor = Colors.white70;
  static const Color iconColor = Colors.white;
  static const Color cardBackgroundColor = Colors.white;
  static const Color readMoreColor = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: true);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage.isNotEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: _buildNewsArticleCard(_newsArticles[index]),
                );
              }, childCount: _newsArticles.length),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final lang = Provider.of<LanguageProvider>(context, listen: true);
    return SliverAppBar(
      backgroundColor: headerColor,
      expandedHeight: 100.0,
      pinned: false,
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.article_outlined,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.getText('agriculture_news'),
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          lang.getText('latest_farming_updates'),
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: iconColor, size: 20),
                    onPressed: () {
                      // your refresh logic
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsArticleCard(NewsArticle article) {
    final lang = Provider.of<LanguageProvider>(context, listen: true);
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          article.imageUrl.isNotEmpty
              ? Image.network(
                article.imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              )
              : Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey,
                child: Center(
                  child: Text(
                    lang.getText('no_image'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...article.tags.map((tag) => _buildTagChip(tag)).toList(),
                    const Spacer(),
                    Text(
                      article.timeAgo,
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  article.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      article.source,
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text(
                        lang.getText('separator_dot'),
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ),
                    Text(
                      article.readTime,
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse(article.url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          throw 'Could not launch ${article.url}';
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            lang.getText('read_more'),
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.blue,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(Tag tag) {
    final lang = Provider.of<LanguageProvider>(context, listen: true);
    return Container(
      margin: const EdgeInsets.only(right: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: tag.backgroundColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        lang.getText(tag.text),
        style: TextStyle(
          color: tag.textColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
