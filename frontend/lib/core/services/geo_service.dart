import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'user_prefs_service.dart';

class CountryInfo {
  final String name;
  final String alpha2Code;
  final String region;

  CountryInfo({
    required this.name,
    required this.alpha2Code,
    required this.region,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'alpha2Code': alpha2Code,
        'region': region,
      };

  factory CountryInfo.fromMap(Map<dynamic, dynamic> map) => CountryInfo(
        name: (map['name'] ?? '').toString(),
        alpha2Code: (map['alpha2Code'] ?? '').toString().toUpperCase(),
        region: (map['region'] ?? '').toString(),
      );
}

class GeoService {
  static const String _accessKey = '995febc8029e43409f2cc90312bcf45e';
  static const String _ipstackUrl = 'https://api.apilayer.net/ipstack/check';
  static const String _countryLayerUrl =
      'https://api.apilayer.net/countrylayer/v2/all';

  /// 1. جلب جميع دول العالم من CountryLayer وتخزينها في Hive
  static Future<List<CountryInfo>> getAllCountries() async {
    final box = Hive.isBoxOpen('user_prefs_box')
        ? Hive.box('user_prefs_box')
        : await Hive.openBox('user_prefs_box');

    final cached = box.get('cached_countries');
    if (cached != null && cached is List && cached.isNotEmpty) {
      return cached
          .map<CountryInfo>((e) => CountryInfo.fromMap(e as Map))
          .toList();
    }

    try {
      final uri = Uri.parse('$_countryLayerUrl?access_key=$_accessKey');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List rawList = jsonDecode(res.body);
        final countries = rawList
            .map<CountryInfo>((item) => CountryInfo(
                  name: (item['name'] ?? '').toString(),
                  alpha2Code:
                      (item['alpha2Code'] ?? '').toString().toUpperCase(),
                  region: (item['region'] ?? '').toString(),
                ))
            .where((c) => c.name.isNotEmpty && c.alpha2Code.isNotEmpty)
            .toList();

        countries.sort((a, b) => a.name.compareTo(b.name));

        if (countries.isNotEmpty) {
          await box.put(
            'cached_countries',
            countries.map((c) => c.toMap()).toList(),
          );
          return countries;
        }
      }
    } catch (_) {}

    // قائمة احتياطية في حال عدم توفر الاتصال في أول تشغيل
    return [
      CountryInfo(name: 'Egypt', alpha2Code: 'EG', region: 'Africa'),
      CountryInfo(name: 'United Kingdom', alpha2Code: 'GB', region: 'Europe'),
      CountryInfo(name: 'Spain', alpha2Code: 'ES', region: 'Europe'),
      CountryInfo(name: 'Italy', alpha2Code: 'IT', region: 'Europe'),
      CountryInfo(name: 'Germany', alpha2Code: 'DE', region: 'Europe'),
      CountryInfo(name: 'France', alpha2Code: 'FR', region: 'Europe'),
      CountryInfo(name: 'Saudi Arabia', alpha2Code: 'SA', region: 'Asia'),
    ];
  }

  /// 2. اكتشاف دولة المستخدم تلقائياً عبر ipstack وتفعيلها
  static Future<String?> detectAndApplyUserCountry() async {
    final box = Hive.isBoxOpen('user_prefs_box')
        ? Hive.box('user_prefs_box')
        : await Hive.openBox('user_prefs_box');

    if (box.containsKey('detected_country')) {
      return box.get('detected_country');
    }

    try {
      final uri = Uri.parse('$_ipstackUrl?access_key=$_accessKey');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final isoCode = (data['country_code'] ?? '').toString().toUpperCase();
        if (isoCode.isNotEmpty) {
          await box.put('detected_country', isoCode);
          final current = await UserPrefsService.getSelectedLeagues();
          if (!current.contains(isoCode)) {
            await UserPrefsService.toggleLeague(isoCode);
          }
          return isoCode;
        }
      }
    } catch (_) {}

    return null;
  }
}
