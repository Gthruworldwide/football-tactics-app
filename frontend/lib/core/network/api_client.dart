import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Uri? uri;

  const ApiException(this.message, {this.statusCode, this.uri});

  @override
  String toString() => message;
}

class ApiClient {
  /// Provider keys stay on the backend; never compile them into the mobile app.
  static const String backendHost = String.fromEnvironment(
    'BACKEND_HOST',
    defaultValue: '192.168.1.14:8000',
  );
  static const String _backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://192.168.1.14:8000',
  );

  static const Map<String, String> leagueCodes = {
    'EG': 'EG',
    'Egypt': 'EG',
    'Egyptian Premier League': 'EG',
    'ENG': 'ENG',
    'GB': 'ENG',
    'England': 'ENG',
    'Premier League': 'ENG',
    'ESP': 'ESP',
    'ES': 'ESP',
    'Spain': 'ESP',
    'La Liga': 'ESP',
    'ITA': 'ITA',
    'Italy': 'ITA',
    'Serie A': 'ITA',
    'GER': 'GER',
    'DE': 'GER',
    'Germany': 'GER',
    'Bundesliga': 'GER',
    'FRA': 'FRA',
    'France': 'FRA',
    'Ligue 1': 'FRA',
    'SAU': 'SAU',
    'Saudi Arabia': 'SAU',
  };

  static String normalizeLeagueCode(String value) =>
      leagueCodes[value] ??
      leagueCodes[value.toUpperCase()] ??
      value.toUpperCase();

  static String matchesEndpoint(String countryCode) {
    return '/api/v1/matches/${normalizeLeagueCode(countryCode)}';
  }

  static String standingsEndpoint(String countryCode) {
    return '/api/v1/standings/${normalizeLeagueCode(countryCode)}';
  }

  static String playersEndpoint(String countryCode) =>
      '/api/v1/players/${normalizeLeagueCode(countryCode)}';

  static const Duration _requestTimeout = Duration(seconds: 35);

  static Future<http.Response> _request(
    Uri uri,
    Map<String, String> headers,
  ) async {
    try {
      return await http.get(uri, headers: headers).timeout(_requestTimeout);
    } on Object catch (error) {
      throw ApiException('Request failed: $error', uri: uri);
    }
  }

  static Future<http.Response> get(String path) async {
    try {
      final uri = Uri.parse('$_backendBaseUrl$path');
      return await _request(uri, const {'Accept': 'application/json'});
    } on ApiException catch (error) {
      throw ApiException(
        'Unable to reach the football data server. Check that it is running on the same network.',
        statusCode: error.statusCode,
        uri: error.uri,
      );
    }
  }
}
