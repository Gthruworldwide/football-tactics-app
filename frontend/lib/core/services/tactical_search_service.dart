import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchBriefItem {
  final String title;
  final String snippet;
  final String domain;
  final String url;

  SearchBriefItem({
    required this.title,
    required this.snippet,
    required this.domain,
    required this.url,
  });
}

class TacticalSearchService {
  static const String _apilayerKey = '995febc8029e43409f2cc90312bcf45e';
  static const String _baseUrl = 'https://api.apilayer.net/serpstack/search';

  static final Map<String, List<SearchBriefItem>> _cache = {};

  /// البحث الفوري عن التشكيل المتوقع والإصابات والتحليل التكتيكي لمباراة أو لاعب
  static Future<List<SearchBriefItem>> fetchTacticalIntel(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];
    if (_cache.containsKey(cleanQuery)) return _cache[cleanQuery]!;

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'access_key': _apilayerKey,
        'query': cleanQuery,
        'num': '5',
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List organic = decoded['organic_results'] ?? [];

        final items = organic
            .map<SearchBriefItem>((item) => SearchBriefItem(
                  title: (item['title'] ?? '').toString(),
                  snippet: (item['snippet'] ?? '').toString(),
                  domain: (item['domain'] ?? '').toString(),
                  url: (item['url'] ?? '').toString(),
                ))
            .where((i) => i.title.isNotEmpty && i.snippet.isNotEmpty)
            .take(4)
            .toList();

        if (items.isNotEmpty) {
          _cache[cleanQuery] = items;
          return items;
        }
      }
    } catch (_) {}

    return [];
  }
}
