import 'dart:convert';
import 'package:http/http.dart' as http;

class StadiumWeather {
  final double tempC;
  final String condition;
  final double windKmh;
  final double? latitude;
  final double? longitude;
  final String resolvedLabel;

  StadiumWeather({
    required this.tempC,
    required this.condition,
    required this.windKmh,
    this.latitude,
    this.longitude,
    this.resolvedLabel = '',
  });
}

class WeatherService {
  static const String _apilayerKey = '995febc8029e43409f2cc90312bcf45e';
  static const String _positionStackUrl =
      'https://api.apilayer.net/positionstack/v1/forward';

  static final Map<String, StadiumWeather> _memoryCache = {};

  /// جلب إحداثيات الملعب عبر PositionStack ثم حالة الطقس الدقيقة عبر Open-Meteo
  static Future<StadiumWeather?> getVenueWeather(
    String? city, {
    String? venueName,
  }) async {
    final cleanCity = (city ?? '').split(',').first.trim();
    final cleanVenue = (venueName ?? '').trim();

    if (cleanCity.isEmpty && cleanVenue.isEmpty) return null;

    final query = cleanVenue.isNotEmpty && cleanCity.isNotEmpty
        ? '$cleanVenue, $cleanCity'
        : (cleanVenue.isNotEmpty ? cleanVenue : cleanCity);

    if (_memoryCache.containsKey(query)) {
      return _memoryCache[query];
    }

    double? lat;
    double? lon;
    String label = cleanCity;

    // 1. محاولة تحديد إحداثيات الملعب بدقة عبر PositionStack
    try {
      final posUri = Uri.parse(_positionStackUrl).replace(queryParameters: {
        'access_key': _apilayerKey,
        'query': query,
        'limit': '1',
      });
      final posRes = await http.get(posUri).timeout(const Duration(seconds: 6));

      if (posRes.statusCode == 200) {
        final decoded = jsonDecode(posRes.body);
        final List dataList = decoded['data'] ?? [];
        if (dataList.isNotEmpty) {
          lat = (dataList[0]['latitude'] as num?)?.toDouble();
          lon = (dataList[0]['longitude'] as num?)?.toDouble();
          label = (dataList[0]['label'] ?? cleanCity).toString();
        }
      }
    } catch (_) {}

    // 2. Fallback مجاني عبر Open-Meteo Geocoding إذا لم يُعثر على اسم الملعب
    if ((lat == null || lon == null) && cleanCity.isNotEmpty) {
      try {
        final geoUri = Uri.parse(
          'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(cleanCity)}&count=1&format=json',
        );
        final geoRes =
            await http.get(geoUri).timeout(const Duration(seconds: 5));
        if (geoRes.statusCode == 200) {
          final List results = jsonDecode(geoRes.body)['results'] ?? [];
          if (results.isNotEmpty) {
            lat = (results[0]['latitude'] as num?)?.toDouble();
            lon = (results[0]['longitude'] as num?)?.toDouble();
          }
        }
      } catch (_) {}
    }

    if (lat == null || lon == null) return null;

    // 3. جلب حالة الطقس الفعلية عند إحداثيات الملعب
    try {
      final weatherUri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true',
      );
      final wRes =
          await http.get(weatherUri).timeout(const Duration(seconds: 5));

      if (wRes.statusCode == 200) {
        final wData = jsonDecode(wRes.body)['current_weather'] ?? {};
        final code = (wData['weathercode'] ?? 0) as int;
        final weather = StadiumWeather(
          tempC: (wData['temperature'] ?? 20).toDouble(),
          condition: _decodeWeatherCode(code),
          windKmh: (wData['windspeed'] ?? 10).toDouble(),
          latitude: lat,
          longitude: lon,
          resolvedLabel: label,
        );
        _memoryCache[query] = weather;
        return weather;
      }
    } catch (_) {}

    return null;
  }

  static String _decodeWeatherCode(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Cloudy';
    if (code >= 51 && code <= 67) return 'Rain';
    if (code >= 80) return 'Showers';
    return 'Mild';
  }
}
