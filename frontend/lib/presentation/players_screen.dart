import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/data_error_localizer.dart';
import '../core/data_source_label.dart';
import '../core/league_catalog.dart';
import '../core/services/app_language.dart';
import 'widgets/language_menu_button.dart';

/// نموذج بيانات الإحصائيات التكتيكية للاعب
class PlayerTacticalModel {
  final int understatId;
  final String playerName;
  final String teamName;
  final String league;
  final String position;
  final int? games;
  final int? minutes;
  final int? goals;
  final int? assists;
  final double? xg;
  final double? xa;
  final double? xgChain;
  final double? xgBuildup;
  final int? shots;
  final int? keyPasses;

  PlayerTacticalModel({
    required this.understatId,
    required this.playerName,
    required this.teamName,
    required this.league,
    required this.position,
    required this.games,
    required this.minutes,
    required this.goals,
    required this.assists,
    required this.xg,
    required this.xa,
    required this.xgChain,
    required this.xgBuildup,
    required this.shots,
    required this.keyPasses,
  });

  factory PlayerTacticalModel.fromJson(Map<String, dynamic> json) {
    int? asInt(Object? value) =>
        value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
    double? asDouble(Object? value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    return PlayerTacticalModel(
      understatId: asInt(json['understat_id'] ?? json['id']) ?? 0,
      playerName: (json['player_name'] ?? json['name'] ?? '').toString(),
      teamName: (json['team_name'] ?? json['team'] ?? '').toString(),
      league: (json['league'] ?? '').toString(),
      position: (json['position'] ?? 'N/A').toString(),
      games: asInt(json['games'] ?? json['appearances']),
      minutes: asInt(json['minutes'] ?? json['time']),
      goals: asInt(json['goals']),
      assists: asInt(json['assists']),
      xg: asDouble(json['xg'] ?? json['xG']),
      xa: asDouble(json['xa'] ?? json['xA']),
      xgChain: asDouble(json['xg_chain'] ?? json['xGChain']),
      xgBuildup: asDouble(json['xg_buildup'] ?? json['xGBuildup']),
      shots: asInt(json['shots']),
      keyPasses: asInt(json['key_passes']),
    );
  }
}

class PlayersScreen extends StatefulWidget {
  final String serverHost;

  const PlayersScreen({super.key, this.serverHost = '192.168.1.14:8000'});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _leagues = LeagueCatalog.supported;

  String _selectedLeague = 'ENG';
  int? _season;
  String? _source;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late Future<List<PlayerTacticalModel>> _playersFuture;

  @override
  void initState() {
    super.initState();
    _playersFuture = _fetchPlayers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<PlayerTacticalModel>> _fetchPlayers({String? league}) async {
    final requestedLeague = league ?? _selectedLeague;
    final uri = Uri.http(widget.serverHost, '/api/v1/players/$requestedLeague');
    final response = await http.get(uri).timeout(const Duration(seconds: 40));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final season = decoded['season'];
      final source = decoded['source'] as String?;
      // Ignore late responses from a league the user has already left.
      if (mounted && _selectedLeague == requestedLeague) {
        setState(() {
          _season = season is num ? season.toInt() : null;
          _source = source;
        });
      }
      final List<dynamic> list = decoded['players'] ?? [];
      final query = _searchQuery.trim().toLowerCase();
      return list
          .map((e) => PlayerTacticalModel.fromJson(e as Map<String, dynamic>))
          .where(
            (player) =>
                query.isEmpty ||
                player.playerName.toLowerCase().contains(query) ||
                player.teamName.toLowerCase().contains(query),
          )
          .toList();
    } else {
      final decoded = jsonDecode(response.body);
      final detail = decoded is Map ? decoded['detail'] : null;
      throw Exception(detail ?? 'خطأ في السيرفر: ${response.statusCode}');
    }
  }

  void _onLeagueChanged(String league) {
    if (_selectedLeague == league) return;
    setState(() {
      _selectedLeague = league;
      _season = null;
      _source = null;
      _playersFuture = _fetchPlayers(league: league);
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _searchQuery = value;
        _playersFuture = _fetchPlayers();
      });
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _season = null;
      _source = null;
      _playersFuture = _fetchPlayers();
    });
    try {
      await _playersFuture;
    } catch (_) {
      // FutureBuilder presents the localized error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceLabel = dataSourceLabel(
      _source,
      isArabic: AppLanguage.instance.isArabic,
    );
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLanguage.instance.isArabic
                  ? 'إحصائيات اللاعبين'
                  : 'Player Statistics',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_season != null || sourceLabel != null)
              Text(
                [
                  if (_season != null)
                    AppLanguage.instance.isArabic
                        ? 'موسم $_season/${_season! + 1}'
                        : 'Season $_season/${_season! + 1}',
                  ?sourceLabel,
                ].join(' · '),
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          const LanguageMenuButton(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
            tooltip: AppLanguage.instance.isArabic
                ? 'تحديث البيانات'
                : 'Refresh data',
          ),
        ],
      ),
      body: Column(
        children: [
          // مربع البحث الفوري عن لاعب أو نادي
          Container(
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: AppLanguage.instance.isArabic
                    ? 'ابحث باسم اللاعب أو الفريق...'
                    : 'Search player or team...',
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF0F172A),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // شريط اختيار الدوري
          Container(
            height: 52,
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.only(bottom: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _leagues.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = _leagues[index];
                final isSelected = option.code == _selectedLeague;
                return ChoiceChip(
                  label: Text(
                    option.label(isArabic: AppLanguage.instance.isArabic),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF38BDF8),
                  backgroundColor: const Color(0xFF334155),
                  onSelected: (_) => _onLeagueChanged(option.code),
                );
              },
            ),
          ),

          // قائمة اللاعبين
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFF38BDF8),
              child: FutureBuilder<List<PlayerTacticalModel>>(
                future: _playersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF38BDF8),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 46,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${AppLanguage.instance.isArabic ? 'تعذر جلب بيانات اللاعبين' : 'Could not load player data'}\n${localizedDataError(snapshot.error!, isArabic: AppLanguage.instance.isArabic, fallback: AppLanguage.instance.isArabic ? 'تحقق من الاتصال بالخادم ثم أعد المحاولة.' : 'Check the backend connection and retry.')}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                AppLanguage.instance.isArabic
                                    ? 'إعادة المحاولة'
                                    : 'Retry',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final players = snapshot.data ?? [];
                  if (players.isEmpty) {
                    return Center(
                      child: Text(
                        AppLanguage.instance.isArabic
                            ? 'لا توجد إحصائيات لاعبين متاحة لهذا الدوري أو البحث.'
                            : 'No player statistics match this league or search.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      return _PlayerTacticalCard(
                        rank: index + 1,
                        player: players[index],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة عرض المؤشرات التكتيكية لكل لاعب
class _PlayerTacticalCard extends StatelessWidget {
  final int rank;
  final PlayerTacticalModel player;

  const _PlayerTacticalCard({required this.rank, required this.player});

  String get _notAvailable =>
      AppLanguage.instance.isArabic ? 'غير متاح' : 'N/A';

  String get _positionLabel {
    if (!AppLanguage.instance.isArabic) return player.position;
    return const {
          'Goalkeeper': 'حارس مرمى',
          'Defender': 'مدافع',
          'Midfielder': 'لاعب وسط',
          'Attacker': 'مهاجم',
          'Forward': 'مهاجم',
        }[player.position] ??
        player.position;
  }

  @override
  Widget build(BuildContext context) {
    final double? finishingDiff = player.xg == null || player.goals == null
        ? null
        : player.goals! - player.xg!;
    final bool clinical = finishingDiff != null && finishingDiff >= 0;

    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الترويسة: الترتيب + الاسم + النادي + المركز
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF38BDF8).withOpacity(0.18),
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.playerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${player.teamName} • ${player.league}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    '$_positionLabel | ${player.minutes ?? _notAvailable}\'',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20, color: Colors.white10),

            // الصف الأول: الأهداف / xG / الفارق / الصناعة / xA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetricItem(
                  label: AppLanguage.instance.isArabic ? 'أهداف' : 'Goals',
                  value: player.goals?.toString() ?? _notAvailable,
                ),
                _MetricItem(
                  label: 'xG',
                  value: player.xg?.toStringAsFixed(2) ?? _notAvailable,
                  highlightColor: const Color(0xFF38BDF8),
                ),
                _MetricItem(
                  label: AppLanguage.instance.isArabic
                      ? 'كفاءة الإنهاء'
                      : 'Finishing',
                  value: finishingDiff == null
                      ? _notAvailable
                      : '${clinical ? '+' : ''}${finishingDiff.toStringAsFixed(2)}',
                  highlightColor: finishingDiff == null
                      ? Colors.white54
                      : clinical
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFFF87171),
                ),
                _MetricItem(
                  label: AppLanguage.instance.isArabic ? 'صناعة' : 'Assists',
                  value: player.assists?.toString() ?? _notAvailable,
                ),
                _MetricItem(
                  label: 'xA',
                  value: player.xa?.toStringAsFixed(2) ?? _notAvailable,
                  highlightColor: const Color(0xFFF59E0B),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // الصف الثاني: مساهمة البناء التكتيكي (xGChain & xGBuildup)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SubStat(
                    label: 'xGChain',
                    value: player.xgChain?.toStringAsFixed(2) ?? _notAvailable,
                  ),
                  _SubStat(
                    label: 'xGBuildup',
                    value:
                        player.xgBuildup?.toStringAsFixed(2) ?? _notAvailable,
                  ),
                  _SubStat(
                    label: AppLanguage.instance.isArabic ? 'تسديدات' : 'Shots',
                    value: '${player.shots ?? _notAvailable}',
                  ),
                  _SubStat(
                    label: AppLanguage.instance.isArabic
                        ? 'تمريرات مفتاحية'
                        : 'Key passes',
                    value: '${player.keyPasses ?? _notAvailable}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? highlightColor;

  const _MetricItem({
    required this.label,
    required this.value,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: highlightColor ?? Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}

class _SubStat extends StatelessWidget {
  final String label;
  final String value;

  const _SubStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}
