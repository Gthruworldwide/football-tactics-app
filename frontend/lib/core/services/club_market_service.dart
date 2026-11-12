import 'dart:convert';
import 'package:http/http.dart' as http;

class ClubStockQuote {
  final String symbol;
  final double closePrice;
  final double openPrice;

  ClubStockQuote({
    required this.symbol,
    required this.closePrice,
    required this.openPrice,
  });

  double get changePercent =>
      openPrice > 0 ? ((closePrice - openPrice) / openPrice) * 100 : 0.0;
}

class ClubMarketService {
  static const String _apilayerKey = '995febc8029e43409f2cc90312bcf45e';
  static const String _baseUrl = 'https://api.apilayer.net/marketstack/v2/eod';

  static const Map<String, String> _clubTickers = {
    'manchester united': 'MANU',
    'juventus': 'JUVE.MI',
    'borussia dortmund': 'BVB.DE',
    'dortmund': 'BVB.DE',
    'ajax': 'AJAX.AS',
    'benfica': 'SLBEN.LS',
  };

  static final Map<String, ClubStockQuote> _cache = {};

  static String? resolveTicker(String teamName) {
    final lower = teamName.toLowerCase();
    for (final entry in _clubTickers.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static Future<ClubStockQuote?> getClubStock(String teamName) async {
    final symbol = resolveTicker(teamName);
    if (symbol == null) return null;
    if (_cache.containsKey(symbol)) return _cache[symbol];

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'access_key': _apilayerKey,
        'symbols': symbol,
        'limit': '1',
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body)['data'] ?? [];
        if (data.isNotEmpty) {
          final quote = ClubStockQuote(
            symbol: symbol,
            closePrice: (data[0]['close'] as num?)?.toDouble() ?? 0.0,
            openPrice: (data[0]['open'] as num?)?.toDouble() ?? 0.0,
          );
          _cache[symbol] = quote;
          return quote;
        }
      }
    } catch (_) {}

    return null;
  }
}
