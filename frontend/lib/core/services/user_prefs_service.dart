import 'package:shared_preferences/shared_preferences.dart';

class UserPrefsService {
  static const _selectedLeaguesKey = 'selected_leagues';
  static const _tacticalLensKey = 'tactical_lens';
  static const _favoriteTeamsKey = 'favorite_teams';

  static Future<List<String>> getSelectedLeagues() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_selectedLeaguesKey) ?? [];
    return raw;
  }

  static Future<void> toggleLeague(String leagueCode) async {
    final leagues = await getSelectedLeagues();
    if (leagues.contains(leagueCode)) {
      leagues.remove(leagueCode);
    } else {
      leagues.add(leagueCode);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedLeaguesKey, leagues);
  }

  static Future<void> setSelectedLeagues(List<String> leagues) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedLeaguesKey, leagues);
  }

  static Future<String> getTacticalLens() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tacticalLensKey) ?? 'Possession';
  }

  static Future<void> setTacticalLens(String lens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tacticalLensKey, lens);
  }

  static Future<List<String>> getFavoriteTeams() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_favoriteTeamsKey) ?? [];
    return raw;
  }

  static Future<void> setFavoriteTeams(List<String> teams) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoriteTeamsKey, teams);
  }

  static Future<void> toggleFavoriteTeam(String teamName) async {
    final favorites = await getFavoriteTeams();
    if (favorites.contains(teamName)) {
      favorites.remove(teamName);
    } else {
      favorites.add(teamName);
    }
    await setFavoriteTeams(favorites);
  }
}