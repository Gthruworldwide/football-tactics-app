import 'dart:convert';
import 'package:http/http.dart' as http;

class TravelInsight {
  final String routeLabel;
  final int activeFlightsToday;
  final String fatigueRisk;
  final String tacticalNote;

  TravelInsight({
    required this.routeLabel,
    required this.activeFlightsToday,
    required this.fatigueRisk,
    required this.tacticalNote,
  });
}

class TravelFatigueService {
  static const String _apilayerKey = '995febc8029e43409f2cc90312bcf45e';
  static const String _baseUrl =
      'https://api.apilayer.net/aviationstack/v1/flights';

  static final Map<String, TravelInsight> _cache = {};

  // ربط أبرز الأندية والمدن برموز مطارات IATA الدولية
  static const Map<String, String> _teamAirportIata = {
    'al ahly': 'CAI',
    'zamalek': 'CAI',
    'pyramids': 'CAI',
    'al masry': 'PSD',
    'al ittihad': 'HBE',
    'ismaily': 'CAI',
    'aswan': 'ASW',
    'liverpool': 'LPL',
    'manchester': 'MAN',
    'arsenal': 'LHR',
    'chelsea': 'LHR',
    'tottenham': 'LHR',
    'newcastle': 'NCL',
    'barcelona': 'BCN',
    'real madrid': 'MAD',
    'atletico': 'MAD',
    'sevilla': 'SVQ',
    'bayern': 'MUC',
    'dortmund': 'DTM',
    'inter': 'MXP',
    'milan': 'MXP',
    'juventus': 'TRN',
    'napoli': 'NAP',
    'al hilal': 'RUH',
    'al nassr': 'RUH',
    'al ahli': 'JED',
    'ittihad': 'JED',
  };

  static const Map<String, String> _cityAirportIata = {
    'cairo': 'CAI',
    'alexandria': 'HBE',
    'aswan': 'ASW',
    'london': 'LHR',
    'liverpool': 'LPL',
    'manchester': 'MAN',
    'newcastle': 'NCL',
    'barcelona': 'BCN',
    'madrid': 'MAD',
    'seville': 'SVQ',
    'sevilla': 'SVQ',
    'munich': 'MUC',
    'milan': 'MXP',
    'turin': 'TRN',
    'naples': 'NAP',
    'riyadh': 'RUH',
    'jeddah': 'JED',
    'dammam': 'DMM',
  };

  static String? _resolveTeamIata(String teamName) {
    final lower = teamName.toLowerCase();
    for (final entry in _teamAirportIata.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static String? _resolveCityIata(String city) {
    final lower = city.toLowerCase();
    for (final entry in _cityAirportIata.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// تحليل مسار سفر الفريق الضيف إلى مدينة الملعب عبر AviationStack
  static Future<TravelInsight?> analyzeAwayTravel({
    required String awayTeam,
    required String venueCity,
  }) async {
    final depIata = _resolveTeamIata(awayTeam);
    final arrIata = _resolveCityIata(venueCity);

    if (depIata == null || arrIata == null) return null;

    // إذا كان الفريقان في نفس المدينة (ديربي محلي)
    if (depIata == arrIata) {
      return TravelInsight(
        routeLabel: '$depIata Local Derby',
        activeFlightsToday: 0,
        fatigueRisk: 'Zero Travel Load',
        tacticalNote: 'Same-city fixture • Full recovery & high pressing capacity',
      );
    }

    final routeKey = '$depIata-$arrIata';
    if (_cache.containsKey(routeKey)) return _cache[routeKey];

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'access_key': _apilayerKey,
        'dep_iata': depIata,
        'arr_iata': arrIata,
        'limit': '10',
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 7));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List flights = decoded['data'] ?? [];
        final insight = TravelInsight(
          routeLabel: '$depIata ➔ $arrIata',
          activeFlightsToday: flights.length,
          fatigueRisk: flights.isNotEmpty ? 'Moderate Flight Load' : 'Charter / Bus Route',
          tacticalNote: flights.isNotEmpty
              ? '${flights.length} scheduled corridor flights • Watch 2nd-half stamina drop'
              : 'No direct commercial corridor • Overland or private charter transit',
        );
        _cache[routeKey] = insight;
        return insight;
      }
    } catch (_) {}

    return null;
  }
}
