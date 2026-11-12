import 'dart:convert';
import 'package:http/http.dart' as http;

class ScraperService {
  static const String _apilayerKey = '995febc8029e43409f2cc90312bcf45e';
  static const String _baseUrl = 'https://api.apilayer.net/scrapestack/scrape';

  static final Map<String, String> _articleCache = {};

  /// جلب المحتوى الكامل لأي صفحة ويب عبر ScrapeStack
  static Future<String?> fetchRawHtml(String targetUrl,
      {bool renderJs = false}) async {
    if (targetUrl.trim().isEmpty) return null;

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'access_key': _apilayerKey,
        'url': targetUrl.trim(),
        if (renderJs) 'render_js': '1',
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        // ScrapeStack قد يرجع HTML مباشرة أو JSON حسب الإعداد
        final body = res.body.trim();
        if (body.startsWith('{') && body.contains('"success":false')) {
          return null;
        }
        return body;
      }
    } catch (_) {}
    return null;
  }

  /// استخراج النص المقروء الكامل لمقال رياضي من رابطه الأصلي
  static Future<String?> extractReadableArticle(String articleUrl) async {
    if (articleUrl.isEmpty) return null;
    if (_articleCache.containsKey(articleUrl)) {
      return _articleCache[articleUrl];
    }

    final html = await fetchRawHtml(articleUrl);
    if (html == null || html.isEmpty) return null;

    // استخراج فقرات المقال (<p>...</p>) وتنظيفها من وسوم HTML
    final pMatches = RegExp(
      r'<p[^>]*>(.*?)</p>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html);

    final paragraphs = <String>[];
    for (final m in pMatches) {
      var text = m.group(1) ?? '';
      text = text
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&quot;', '"')
          .replaceAll('&amp;', '&')
          .replaceAll('&#39;', "'")
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      // الاحتفاظ بالفقرات التحليلية ذات الطول المناسب وتجاهل نصوص القوائم القصيرة
      if (text.length >= 65 && !text.toLowerCase().contains('cookie')) {
        paragraphs.add(text);
      }
    }

    if (paragraphs.isEmpty) return null;

    final fullText = paragraphs.take(12).join('\n\n');
    _articleCache[articleUrl] = fullText;
    return fullText;
  }
}
