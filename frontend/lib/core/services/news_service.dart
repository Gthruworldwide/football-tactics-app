import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsArticle {
  final String title;
  final String description;
  final String source;
  final String url;
  final String? imageUrl;
  final String publishedAt;

  NewsArticle({
    required this.title,
    required this.description,
    required this.source,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: (json['title'] ?? 'Sports Update').toString(),
      description: (json['description'] ?? '').toString(),
      source: (json['source'] ?? 'Mediastack').toString(),
      url: (json['url'] ?? '').toString(),
      imageUrl: json['image']?.toString(),
      publishedAt: (json['published_at'] ?? '').toString(),
    );
  }
}

class NewsService {
  static const String _accessKey = '995febc8029e43409f2cc90312bcf45e';
  static const String _baseUrl = 'https://api.apilayer.net/mediastack/v1/news';

  static List<NewsArticle> _cachedNews = [];
  static String _lastQuery = '';

  static Future<List<NewsArticle>> getSportsNews({String? keywords}) async {
    final queryKey = keywords?.trim() ?? 'football';
    if (_cachedNews.isNotEmpty && _lastQuery == queryKey) {
      return _cachedNews;
    }

    final queryParams = <String, String>{
      'access_key': _accessKey,
      'categories': 'sports',
      'languages': 'en,ar',
      'limit': '25',
      'offset': '0',
      if (keywords != null && keywords.trim().isNotEmpty)
        'keywords': keywords.trim(),
    };

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List rawList = decoded['data'] ?? [];
        final articles = rawList
            .map<NewsArticle>((item) => NewsArticle.fromJson(item))
            .where((a) => a.title.isNotEmpty)
            .toList();

        if (articles.isNotEmpty) {
          _cachedNews = articles;
          _lastQuery = queryKey;
          return articles;
        }
      }
    } catch (_) {}

    return _cachedNews;
  }
}
