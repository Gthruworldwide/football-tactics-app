import 'package:flutter_test/flutter_test.dart';
import 'package:football_tactics_app/core/models/football_api_models.dart';

void main() {
  group('FixtureMatch', () {
    test('does not invent scores or xG for an upcoming fixture', () {
      final match = FixtureMatch.fromJson({
        'fixture': {
          'id': 42,
          'date': '2026-11-15T15:00:00+00:00',
          'status': {'short': 'NS'},
        },
        'league': {'name': 'Premier League'},
        'teams': {
          'home': {'name': 'Home FC'},
          'away': {'name': 'Away FC'},
        },
        'goals': {'home': null, 'away': null},
      });

      expect(match.fixtureId, 42);
      expect(match.fixtureDate, '2026-11-15T15:00:00+00:00');
      expect(match.homeScore, isNull);
      expect(match.awayScore, isNull);
      expect(match.homeXg, isNull);
      expect(match.awayXg, isNull);
      expect(match.displayStatusLabel(isArabic: true), 'لم تبدأ');
      expect(match.displayStatusLabel(isArabic: false), 'Scheduled');
    });

    test('parses real scores and xG when the provider supplies them', () {
      final match = FixtureMatch.fromJson({
        'fixture': {
          'id': 99,
          'status': {'short': 'FT'},
        },
        'league': {'name': 'Serie A'},
        'teams': {
          'home': {'name': 'Home FC'},
          'away': {'name': 'Away FC'},
        },
        'goals': {'home': 2, 'away': 1},
        'xg': {'home': 1.25, 'away': 0.75},
      });

      expect(match.homeScore, 2);
      expect(match.awayScore, 1);
      expect(match.homeXg, 1.25);
      expect(match.awayXg, 0.75);
    });

    test('live status is localized and keeps the supplied minute', () {
      final match = FixtureMatch.fromJson({
        'fixture': {
          'status': {'short': 'LIVE', 'elapsed': 63},
        },
        'goals': {'home': 1, 'away': 0},
      });

      expect(match.isLive, isTrue);
      expect(match.displayStatusLabel(isArabic: true), 'مباشر 63’');
      expect(match.displayStatusLabel(isArabic: false), "LIVE 63'");
    });
  });

  test('MatchesResponse retains provider provenance for the UI', () {
    final response = MatchesResponse.fromJson({
      'country_code': 'ENG',
      'season': 2026,
      'source': 'football-data',
      'matches': <dynamic>[],
    });

    expect(response.season, 2026);
    expect(response.source, 'football-data');
  });
}
