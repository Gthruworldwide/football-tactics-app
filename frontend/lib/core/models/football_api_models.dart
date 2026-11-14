/// Typed models for the backend v1 football responses.
class MatchesResponse {
  final String countryCode;
  final int? season;
  final String? source;
  final List<FixtureMatch> matches;

  const MatchesResponse({
    required this.countryCode,
    this.season,
    this.source,
    required this.matches,
  });

  factory MatchesResponse.fromJson(Map<String, dynamic> json) {
    // Supports the typed backend envelope and the provider's legacy
    // {"response": [...]} envelope while the migration is in progress.
    final rawMatches =
        (json['matches'] as List<dynamic>?) ??
        (json['response'] as List<dynamic>?) ??
        const [];
    return MatchesResponse(
      countryCode: json['country_code'] as String? ?? '',
      season: json['season'] is num
          ? (json['season'] as num).toInt()
          : int.tryParse(json['season']?.toString() ?? ''),
      source: json['source'] as String?,
      matches: rawMatches
          .whereType<Map<String, dynamic>>()
          .map(FixtureMatch.fromJson)
          .toList(),
    );
  }
}

class FixtureMatch {
  final int? fixtureId;
  final String fixtureDate;
  final String leagueName;
  final String homeTeam;
  final String awayTeam;
  final int? homeScore;
  final int? awayScore;
  final String status;
  final int? elapsed;
  final String venueName;
  final String venueCity;
  final double? homeXg;
  final double? awayXg;

  const FixtureMatch({
    required this.fixtureId,
    required this.fixtureDate,
    required this.leagueName,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    required this.elapsed,
    required this.venueName,
    required this.venueCity,
    required this.homeXg,
    required this.awayXg,
  });

  factory FixtureMatch.fromJson(Map<String, dynamic> json) {
    final fixture = _map(json['fixture']);
    final league = _map(json['league']);
    final teams = _map(json['teams']);
    final home = _map(teams['home']);
    final away = _map(teams['away']);
    final goals = _map(json['goals']);
    final status = _map(fixture['status']);
    final venue = _map(fixture['venue']);
    final xg = _map(json['xg']);

    return FixtureMatch(
      fixtureId: _asInt(fixture['id']),
      fixtureDate: _asString(fixture['date']),
      leagueName: _asString(league['name'], fallback: 'Competition'),
      homeTeam: _asString(home['name'], fallback: 'Home'),
      awayTeam: _asString(away['name'], fallback: 'Away'),
      homeScore: _asInt(goals['home']),
      awayScore: _asInt(goals['away']),
      status: _asString(status['short'], fallback: 'NS'),
      elapsed: _asInt(status['elapsed']),
      venueName: _asString(venue['name']),
      venueCity: _asString(venue['city']),
      homeXg: _asDouble(xg['home']),
      awayXg: _asDouble(xg['away']),
    );
  }

  bool get isLive =>
      const {'LIVE', '1H', '2H', 'HT', 'ET', 'P'}.contains(status);

  String get displayStatus =>
      isLive && elapsed != null ? "LIVE $elapsed'" : status;

  String displayStatusLabel({required bool isArabic}) {
    if (isLive && elapsed != null) {
      return isArabic ? 'مباشر $elapsed’' : "LIVE $elapsed'";
    }
    return (isArabic ? _arabicStatuses : _englishStatuses)[status] ?? status;
  }

  static const _englishStatuses = <String, String>{
    'LIVE': 'Live',
    '1H': '1st half',
    '2H': '2nd half',
    'HT': 'Half-time',
    'ET': 'Extra time',
    'P': 'Penalties',
    'NS': 'Scheduled',
    'FT': 'Finished',
    'PST': 'Postponed',
    'SUSP': 'Suspended',
    'CANC': 'Cancelled',
  };

  static const _arabicStatuses = <String, String>{
    'LIVE': 'مباشر',
    '1H': 'الشوط الأول',
    '2H': 'الشوط الثاني',
    'HT': 'استراحة',
    'ET': 'وقت إضافي',
    'P': 'ركلات الترجيح',
    'NS': 'لم تبدأ',
    'FT': 'انتهت',
    'PST': 'مؤجلة',
    'SUSP': 'متوقفة',
    'CANC': 'أُلغيت',
  };

  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : const {};

  static String _asString(Object? value, {String fallback = ''}) =>
      value is String && value.isNotEmpty ? value : fallback;

  static int? _asInt(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static double? _asDouble(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
}

class StandingsResponse {
  final String countryCode;
  final int? season;
  final List<Map<String, dynamic>> standings;

  const StandingsResponse({
    required this.countryCode,
    this.season,
    required this.standings,
  });

  factory StandingsResponse.fromJson(Map<String, dynamic> json) {
    return StandingsResponse(
      countryCode: json['country_code'] as String? ?? '',
      season: json['season'] is num ? (json['season'] as num).toInt() : null,
      standings: (json['standings'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(),
    );
  }
}
