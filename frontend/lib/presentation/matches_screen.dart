import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/network/api_client.dart';
import '../core/services/geo_service.dart';
import '../core/services/tactical_search_service.dart';
import '../core/services/travel_fatigue_service.dart';
import '../core/services/user_prefs_service.dart';
import '../core/services/weather_service.dart';
import '../core/theme/app_theme.dart';
import 'player_search_screen.dart';
import 'settings_screen.dart';
import 'standings_view.dart';
import 'widgets/tactical_match_card.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  int _navIndex = 0;
  String _selectedCountry = 'EG';
  String _activeLens = 'Possession';
  List<String> _userLeagues = ['EG', 'ENG', 'ESP'];
  List<String> _favoriteTeams = [];
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _matches = [];

  final Map<String, String> _leagueLabels = {
    'EG': 'Egypt',
    'ENG': 'England',
    'ESP': 'Spain',
    'ITA': 'Italy',
    'GER': 'Germany',
    'FRA': 'France',
    'SAU': 'Saudi Arabia',
  };

  @override
  void initState() {
    super.initState();
    _initWorkspace();
  }

  Future<void> _initWorkspace() async {
    final detected = await GeoService.detectAndApplyUserCountry();
    final leagues = await UserPrefsService.getSelectedLeagues();
    final teams = await UserPrefsService.getFavoriteTeams();
    final lens = await UserPrefsService.getTacticalLens();

    setState(() {
      _userLeagues = leagues;
      _favoriteTeams = teams;
      _activeLens = lens;
      if (detected != null && _userLeagues.contains(detected)) {
        _selectedCountry = detected;
      } else if (!_userLeagues.contains(_selectedCountry)) {
        _selectedCountry = _userLeagues.first;
      }
    });

    await _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.get(
        ApiClient.matchesEndpoint(_selectedCountry),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List rawList = decoded['response'] ?? [];

        final parsed = rawList.map((item) {
          final fixture = item['fixture'] ?? {};
          final league = item['league'] ?? {};
          final teams = item['teams'] ?? {};
          final goals = item['goals'] ?? {};
          final statusObj = fixture['status'] ?? {};
          final shortStatus = statusObj['short'] ?? 'NS';
          final elapsed = statusObj['elapsed'];
          final venue = fixture['venue'] ?? {};

          final bool isLive = ['1H', '2H', 'HT', 'ET', 'P'].contains(shortStatus);
          final String displayStatus = isLive && elapsed != null
              ? "LIVE $elapsed'"
              : shortStatus.toString();

          return {
            'league': league['name'] ?? 'Competition',
            'home': teams['home']?['name'] ?? 'Home',
            'away': teams['away']?['name'] ?? 'Away',
            'homeScore': goals['home'],
            'awayScore': goals['away'],
            'status': displayStatus,
            'isLive': isLive,
            'possession': 50.0,
            'xgHome': '1.35',
            'xgAway': '1.10',
            'shotsHome': 0,
            'shotsAway': 0,
            'venueName': venue['name'] ?? '',
            'venueCity': venue['city'] ?? '',
          };
        }).toList();

        // ترتيب المباريات: الحية أولاً ثم الفرق المفضلة
        parsed.sort((a, b) {
          final aScore = (a['isLive'] ? 0 : 2) + (_isMatchTracked(a) ? 0 : 1);
          final bScore = (b['isLive'] ? 0 : 2) + (_isMatchTracked(b) ? 0 : 1);
          return aScore.compareTo(bScore);
        });

        setState(() {
          _matches = parsed;
          _isLoading = false;
        });
      } else {
        setState(() {
          _matches = [];
          _errorMessage = 'API Error: HTTP ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _matches = [];
        _errorMessage = 'Connection timeout. Pull down to retry.';
        _isLoading = false;
      });
    }
  }

  bool _isMatchTracked(Map<String, dynamic> m) {
    final home = (m['home'] ?? '').toString().toLowerCase();
    final away = (m['away'] ?? '').toString().toLowerCase();
    return _favoriteTeams.any(
      (t) => home.contains(t.toLowerCase()) || away.contains(t.toLowerCase()),
    );
  }

  Future<void> _openSettings() async {
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    await _initWorkspace();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: _errorMessage == null
                    ? AppTheme.accentEmerald
                    : const Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            const Text('TACTICS ENGINE'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_rounded, color: AppTheme.accentCyan),
            tooltip: 'Scouting Database',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PlayerSearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppTheme.accentEmerald),
            tooltip: 'Workspace Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // User's Selected Countries Strip
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _userLeagues.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final code = _userLeagues[index];
                  final isSelected = code == _selectedCountry;
                  return ChoiceChip(
                    label: Text(_leagueLabels[code] ?? code),
                    selected: isSelected,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCountry = code);
                      if (_navIndex == 0) _fetchMatches();
                    },
                    backgroundColor: AppTheme.surfaceCard,
                    selectedColor: AppTheme.accentEmerald.withOpacity(0.18),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.accentEmerald
                          : AppTheme.borderSubtle,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.accentEmerald
                          : AppTheme.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: _navIndex == 0
                  ? _buildMatchesList()
                  : StandingsView(
                      countryCode: _selectedCountry,
                      favoriteTeams: _favoriteTeams,
                      onFavoriteToggle: (team) async {
                        await UserPrefsService.toggleFavoriteTeam(team);
                        await _initWorkspace();
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        backgroundColor: AppTheme.surfaceCard,
        indicatorColor: AppTheme.accentEmerald.withOpacity(0.18),
        selectedIndex: _navIndex,
        onDestinationSelected: (idx) {
          HapticFeedback.selectionClick();
          setState(() => _navIndex = idx);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined,
                color: AppTheme.textSecondary),
            selectedIcon:
                Icon(Icons.sports_soccer, color: AppTheme.accentEmerald),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_chart_outlined,
                color: AppTheme.textSecondary),
            selectedIcon:
                Icon(Icons.table_chart, color: AppTheme.accentEmerald),
            label: 'Standings',
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentEmerald),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 44, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentEmerald,
                  foregroundColor: AppTheme.bgObsidian,
                ),
                onPressed: _openSettings,
                icon: const Icon(Icons.settings_rounded, size: 18),
                label: const Text('CONFIGURE SERVER URL'),
              ),
            ],
          ),
        ),
      );
    }

    if (_matches.isEmpty) {
      return RefreshIndicator(
        color: AppTheme.accentEmerald,
        onRefresh: _fetchMatches,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'No live fixtures scheduled for this selection today.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.accentEmerald,
      backgroundColor: AppTheme.surfaceCard,
      onRefresh: _fetchMatches,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final m = _matches[index];
          return TacticalMatchCard(
            leagueName: m['league'],
            homeTeam: m['home'],
            awayTeam: m['away'],
            venueName: m['venueName'] ?? '',
            venueCity: m['venueCity'] ?? '',
            homeScore: m['homeScore'],
            awayScore: m['awayScore'],
            status: m['status'],
            isLive: m['isLive'],
            isTracked: _isMatchTracked(m),
            activeLens: _activeLens,
            homePossession: m['possession'],
            xgHome: m['xgHome'],
            xgAway: m['xgAway'],
            onTap: () => _showMatchTacticalSheet(context, m),
          );
        },
      ),
    );
  }

  void _showMatchTacticalSheet(
      BuildContext context, Map<String, dynamic> match) {
    HapticFeedback.lightImpact();
    final homeTeam = match['home'].toString();
    final isHomeFav = _favoriteTeams.contains(homeTeam);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${match['home']} vs ${match['away']}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isHomeFav
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: isHomeFav
                          ? AppTheme.accentEmerald
                          : AppTheme.textSecondary,
                    ),
                    onPressed: () async {
                      await UserPrefsService.toggleFavoriteTeam(homeTeam);
                      await _initWorkspace();
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const Text(
                'KEY MATCH TELEMETRY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppTheme.accentEmerald,
                ),
              ),
              const SizedBox(height: 18),
              _buildStatRow(
                  'Expected Goals (xG)', match['xgHome'], match['xgAway']),
              const Divider(color: AppTheme.borderSubtle, height: 22),
              _buildStatRow(
                'Ball Possession',
                '${(match['possession'] as double).toInt()}%',
                '${(100 - (match['possession'] as double)).toInt()}%',
              ),
              const Divider(color: AppTheme.borderSubtle, height: 22),
              _buildStatRow('Total Shots', '${match['shotsHome']}',
                  '${match['shotsAway']}'),
              const Divider(color: AppTheme.borderSubtle, height: 22),
              FutureBuilder<StadiumWeather?>(
                future: WeatherService.getVenueWeather(
                  match['venueCity'],
                  venueName: match['venueName'],
                ),
                builder: (context, snap) {
                  final w = snap.data;
                  if (w == null) return const SizedBox.shrink();
                  return _buildStatRow(
                    'Pitch Weather (${match['venueCity']})',
                    '${w.tempC.round()}°C ${w.condition}',
                    'Wind ${w.windKmh.round()} km/h',
                  );
                },
              ),
              FutureBuilder<TravelInsight?>(
                future: TravelFatigueService.analyzeAwayTravel(
                  awayTeam: match['away'].toString(),
                  venueCity: (match['venueCity'] ?? '').toString(),
                ),
                builder: (context, snap) {
                  final travel = snap.data;
                  if (travel == null) return const SizedBox.shrink();
                  return Column(
                    children: [
                      const Divider(color: AppTheme.borderSubtle, height: 22),
                      _buildStatRow(
                        'Away Travel Corridor',
                        travel.routeLabel,
                        travel.fatigueRisk,
                      ),
                      const Divider(color: AppTheme.borderSubtle, height: 22),
              const Text(
                'LIVE LINEUP & INJURY INTEL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppTheme.accentCyan,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<SearchBriefItem>>(
                future: TacticalSearchService.fetchTacticalIntel(
                  '${match['home']} vs ${match['away']} lineups injuries tactical preview',
                ),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(
                        color: AppTheme.accentCyan,
                        backgroundColor: AppTheme.surfaceElevated,
                      ),
                    );
                  }
                  final intel = snap.data ?? [];
                  if (intel.isEmpty) {
                    return const Text(
                      'No pre-match bulletins indexed yet.',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    );
                  }
                  return Column(
                    children: intel.take(2).map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.snippet,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),SizedBox(height: 6),
                      Text(
                        travel.tacticalNote,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentEmerald,
                    foregroundColor: AppTheme.bgObsidian,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.person_search_rounded),
                  label: const Text(
                    'SCOUT MATCH PLAYERS',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerSearchScreen(
                          initialQuery: match['home'],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String homeVal, String awayVal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          homeVal,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppTheme.accentEmerald,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          awayVal,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppTheme.accentCyan,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}






