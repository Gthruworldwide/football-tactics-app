import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// نموذج بيانات الإحصائيات التكتيكية للاعب
class PlayerTacticalModel {
  final int understatId;
  final String playerName;
  final String teamName;
  final String league;
  final String position;
  final int games;
  final int minutes;
  final int goals;
  final int assists;
  final double xg;
  final double xa;
  final double xgChain;
  final double xgBuildup;
  final int shots;
  final int keyPasses;

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
    return PlayerTacticalModel(
      understatId: (json['understat_id'] ?? json['id'] ?? 0) as int,
      playerName: (json['player_name'] ?? json['name'] ?? '').toString(),
      teamName: (json['team_name'] ?? json['team'] ?? '').toString(),
      league: (json['league'] ?? '').toString(),
      position: (json['position'] ?? 'N/A').toString(),
      games: (json['games'] ?? json['appearances'] ?? 0) as int,
      minutes: (json['minutes'] ?? json['time'] ?? 0) as int,
      goals: (json['goals'] ?? 0) as int,
      assists: (json['assists'] ?? 0) as int,
      xg: (json['xg'] ?? json['xG'] ?? 0.0).toDouble(),
      xa: (json['xa'] ?? json['xA'] ?? 0.0).toDouble(),
      xgChain: (json['xg_chain'] ?? json['xGChain'] ?? 0.0).toDouble(),
      xgBuildup: (json['xg_buildup'] ?? json['xGBuildup'] ?? 0.0).toDouble(),
      shots: (json['shots'] ?? 0) as int,
      keyPasses: (json['key_passes'] ?? 0) as int,
    );
  }
}

class PlayersScreen extends StatefulWidget {
  final String serverHost;

  const PlayersScreen({
    super.key,
    this.serverHost = '192.168.1.5:8000',
  });

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final List<String> _leagues = const [
    'All',
    'La Liga',
    'Premier League',
    'Bundesliga',
    'Serie A',
    'Ligue 1',
  ];

  String _selectedLeague = 'La Liga';
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

  Future<List<PlayerTacticalModel>> _fetchPlayers() async {
    final Map<String, String> params = {'limit': '50'};
    if (_selectedLeague != 'All') {
      params['league'] = _selectedLeague;
    }
    if (_searchQuery.trim().isNotEmpty) {
      params['search'] = _searchQuery.trim();
    }

    final uri = Uri.http(widget.serverHost, '/api/tactics/players', params);
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list = decoded['players'] ?? [];
      return list.map((e) => PlayerTacticalModel.fromJson(e)).toList();
    } else {
      throw Exception('خطأ في السيرفر: ${response.statusCode}');
    }
  }

  void _onLeagueChanged(String league) {
    if (_selectedLeague == league) return;
    setState(() {
      _selectedLeague = league;
      _playersFuture = _fetchPlayers();
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
      _playersFuture = _fetchPlayers();
    });
    await _playersFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'التحليل التكتيكي للاعبين',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
            tooltip: 'تحديث البيانات',
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
                hintText: 'ابحث باسم اللاعب أو الفريق...',
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
                final league = _leagues[index];
                final isSelected = league == _selectedLeague;
                return ChoiceChip(
                  label: Text(
                    league == 'All' ? 'الكل' : league,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF38BDF8),
                  backgroundColor: const Color(0xFF334155),
                  onSelected: (_) => _onLeagueChanged(league),
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
                      child:
                          CircularProgressIndicator(color: Color(0xFF38BDF8)),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.redAccent, size: 46),
                            const SizedBox(height: 10),
                            Text(
                              'تعذر جلب بيانات اللاعبين\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final players = snapshot.data ?? [];
                  if (players.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد إحصائيات لاعبين مطابقة للبحث.',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
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

  const _PlayerTacticalCard({
    required this.rank,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final double finishingDiff = player.goals - player.xg;
    final bool clinical = finishingDiff >= 0;

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    '${player.position} | ${player.minutes}\'',
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
                _MetricItem(label: 'أهداف', value: '${player.goals}'),
                _MetricItem(
                  label: 'xG',
                  value: player.xg.toStringAsFixed(2),
                  highlightColor: const Color(0xFF38BDF8),
                ),
                _MetricItem(
                  label: 'كفاءة الإنهاء',
                  value:
                      '${clinical ? '+' : ''}${finishingDiff.toStringAsFixed(2)}',
                  highlightColor: clinical
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFFF87171),
                ),
                _MetricItem(label: 'صناعة', value: '${player.assists}'),
                _MetricItem(
                  label: 'xA',
                  value: player.xa.toStringAsFixed(2),
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
                      value: player.xgChain.toStringAsFixed(2)),
                  _SubStat(
                      label: 'xGBuildup',
                      value: player.xgBuildup.toStringAsFixed(2)),
                  _SubStat(label: 'تسديدات', value: '${player.shots}'),
                  _SubStat(
                      label: 'تمريرات مفتاحية', value: '${player.keyPasses}'),
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
