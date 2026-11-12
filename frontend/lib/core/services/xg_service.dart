import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>> fetchLeagueXg(String leagueName, {int limit = 20}) async {
  // استخدم 10.0.2.2 لمحاكي أندرويد، أو عنوان IP جهازك على الشبكة المحلية (مثل 192.168.1.x) للهاتف الحقيقي
  final uri = Uri.http(
    '192.168.1.5:8000',
    '/api/tactics/xg',
    {
      'league': leagueName, // مثال: "La Liga" أو "Premier League"
      'limit': limit.toString(),
    },
  );

  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['matches_xg']);
  } else {
    throw Exception('فشل جلب بيانات xG: ${response.statusCode}');
  }
}
