import 'package:http/http.dart' as http;

class ApiClient {
  // المفتاح المباشر لـ API-Sports (الأسرع والأولوية الأولى)
  static const String _directApiKey = '668c08564645671be333b72f3aceb668';
  static const String _directBaseUrl = 'https://v3.football.api-sports.io';

  // مفتاح RapidAPI كـ Fallback تلقائي في حال انتهاء الحد اليومي للمفتاح المباشر
  static const String _rapidApiKey =
      '1dc7d39a7dmsh2e2d7fc4b971e3bp13db04jsne4ceddc2fa77';
  static const String _rapidApiHost = 'api-football-v1.p.rapidapi.com';
  static const String _rapidBaseUrl = 'https://api-football-v1.p.rapidapi.com/v3';

  static const Map<String, int> primaryLeagueByIso = {
    'EG': 233,  // Egyptian Premier League
    'GB': 39,   // English Premier League
    'ENG': 39,  // Fallback alias
    'ES': 140,  // Spanish La Liga
    'ESP': 140,
    'IT': 135,  // Italian Serie A
    'ITA': 135,
    'DE': 78,   // German Bundesliga
    'GER': 78,
    'FR': 61,   // French Ligue 1
    'FRA': 61,
    'SA': 307,  // Saudi Pro League
    'SAU': 307,
    'AE': 301,  // UAE Pro League
    'MA': 200,  // Botola Pro (Morocco)
    'TN': 202,  // Ligue 1 (Tunisia)
    'BR': 71,   // Brasileirão Serie A
    'AR': 128,  // Liga Profesional Argentina
    'PT': 94,   // Primeira Liga (Portugal)
    'NL': 88,   // Eredivisie (Netherlands)
    'TR': 203,  // Süper Lig (Turkey)
    'US': 253,  // MLS (USA)
  };

  static int resolveLeagueId(String isoCode) {
    return primaryLeagueByIso[isoCode.toUpperCase()] ?? 39;
  }

  static const Map<String, int> leagueIds = {
    'EG': 233,  // Egyptian Premier League
    'ENG': 39,  // English Premier League
    'ESP': 140, // Spanish La Liga
    'ITA': 135, // Italian Serie A
    'GER': 78,  // German Bundesliga
    'FRA': 61,  // French Ligue 1
    'SAU': 307, // Saudi Pro League
  };

  static String matchesEndpoint(String countryCode) {
    final leagueId = leagueIds[countryCode] ?? 39;
    // جلب آخر 10 مباريات أو مباريات الموسم الحالي 2026 لضمان ظهور بيانات حتى في أيام التوقف
    return '/fixtures?league=$leagueId&season=2026&last=15';
  }

  static String standingsEndpoint(String countryCode) {
    final leagueId = leagueIds[countryCode] ?? 39;
    return '/standings?league=$leagueId&season=2026';
  }

  static String playerEndpoint(int playerId) =>
      '/players?id=$playerId&season=2026';

  static Future<http.Response> get(String path) async {
    // 1. المحاولة الأولى عبر API-Sports المباشر
    try {
      final directRes = await http.get(
        Uri.parse('$_directBaseUrl$path'),
        headers: {
          'Accept': 'application/json',
          'x-apisports-key': _directApiKey,
        },
      ).timeout(const Duration(seconds: 12));

      if (directRes.statusCode == 200 &&
          !directRes.body.contains('"requests":"You have reached')) {
        return directRes;
      }
    } catch (_) {}

    // 2. المحاولة الثانية التلقائية عبر RapidAPI
    return await http.get(
      Uri.parse('$_rapidBaseUrl$path'),
      headers: {
        'Accept': 'application/json',
        'x-rapidapi-key': _rapidApiKey,
        'x-rapidapi-host': _rapidApiHost,
      },
    ).timeout(const Duration(seconds: 12));
  }
}

