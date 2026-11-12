import 'dart:convert';
import 'package:http/http.dart' as http;

class SportsMediaService {
  static final Map<String, String?> _teamBadgeCache = {};
  static final Map<String, String?> _playerPhotoCache = {};

  static Future<String?> getTeamBadge(String teamName) async {
    if (_teamBadgeCache.containsKey(teamName)) {
      return _teamBadgeCache[teamName];
    }

    try {
      final uri = Uri.parse(
        'https://www.thesportsdb.com/api/v1/json/3/searchteams.php?t=${Uri.encodeComponent(teamName)}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final teams = data['teams'] as List?;
        if (teams != null && teams.isNotEmpty) {
          final badge = teams[0]['strTeamBadge'] as String?;
          _teamBadgeCache[teamName] = badge;
          return badge;
        }
      }
    } catch (_) {}

    _teamBadgeCache[teamName] = null;
    return null;
  }

  static Future<String?> getPlayerPhoto(String playerName) async {
    if (_playerPhotoCache.containsKey(playerName)) {
      return _playerPhotoCache[playerName];
    }

    try {
      final uri = Uri.parse(
        'https://www.thesportsdb.com/api/v1/json/3/searchplayers.php?p=${Uri.encodeComponent(playerName)}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final players = data['player'] as List?;
        if (players != null && players.isNotEmpty) {
          final photo = players[0]['strThumb'] as String? ??
              players[0]['strCutout'] as String?;
          _playerPhotoCache[playerName] = photo;
          return photo;
        }
      }
    } catch (_) {}

    _playerPhotoCache[playerName] = null;
    return null;
  }
}
