import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// نموذج بيانات ترتيب الفريق في الدوري
class StandingTeamModel {
  final int rank;
  final String teamName;
  final String league;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDiff;
  final int points;
  final String form;

  StandingTeamModel({
    required this.rank,
    required this.teamName,
    required this.league,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDiff,
    required this.points,
    required this.form,
  });

  factory StandingTeamModel.fromJson(Map<String, dynamic> json) {
    final int gf = (json['goals_for'] ?? json['gf'] ?? 0) as int;
    final int ga = (json['goals_against'] ?? json['ga'] ?? 0) as int;
    return StandingTeamModel(
      rank: (json['rank'] ?? json['position'] ?? 0) as int,
      teamName: (json['team_name'] ?? json['team'] ?? '').toString(),
      league: (json['league'] ?? '').toString(),
      played: (json['played'] ?? json['mp'] ?? 0) as int,
      won: (json['won'] ?? json['w'] ?? 0) as int,
      drawn: (json['drawn'] ?? json['d'] ?? 0) as int,
      lost: (json['lost'] ?? json['l'] ?? 0) as int,
      goalsFor: gf,
      goalsAgainst: ga,
      goalDiff: (json['goal_diff'] ?? json['gd'] ?? (gf - ga)) as int,
      points: (json['points'] ?? json['pts'] ?? 0) as int,
      form: (json['form'] ?? '').toString(),
    );
  }
}

class StandingsScreen extends StatefulWidget {
  final String serverHost;

  const StandingsScreen({
    super.key,
    this.serverHost = '192.168.1.5:8000',
  });

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  final List<String> _leagues = const [
    'La Liga',
    'Premier League',
    'Bundesliga',
    'Serie A',
    'Ligue 1',
  ];

  String _selectedLeague = 'La Liga';
  late Future<List<StandingTeamModel>> _standingsFuture;

  @override
  void initState() {
    super.initState();
    _standingsFuture = _fetchStandings(_selectedLeague);
  }

  Future<List<StandingTeamModel>> _fetchStandings(String league) async {
    final uri = Uri.http(
      widget.serverHost,
      '/api/tactics/standings',
      {'league': league},
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list = decoded['standings'] ?? [];
      return list.map((e) => StandingTeamModel.fromJson(e)).toList();
    } else {
      throw Exception('خطأ في السيرفر: ${response.statusCode}');
    }
  }

  void _onLeagueChanged(String league) {
    if (_selectedLeague == league) return;
    setState(() {
      _selectedLeague = league;
      _standingsFuture = _fetchStandings(league);
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _standingsFuture = _fetchStandings(_selectedLeague);
    });
    await _standingsFuture;
  }

  Color _getRankIndicatorColor(int rank, int totalTeams) {
    if (rank <= 4) return const Color(0xFF38BDF8); // دوري الأبطال
    if (rank == 5) return const Color(0xFFF59E0B); // الدوري الأوروبي
    if (totalTeams > 6 && rank > totalTeams - 3) {
      return const Color(0xFFF87171); // منطقة الهبوط
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'جدول ترتيب الدوري',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refresh,
            tooltip: 'تحديث الترتيب',
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط اختيار الدوري
          Container(
            height: 58,
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.symmetric(vertical: 8),
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
                    league,
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

          // ترويسة الأعمدة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFF1E293B).withOpacity(0.7),
            child: const Row(
              children: [
                SizedBox(
                    width: 28,
                    child: Text('#',
                        style: TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12))),
                Expanded(
                    flex: 4,
                    child: Text('الفريق',
                        style: TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12))),
                SizedBox(
                    width: 28,
                    child: Text('لعب',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12))),
                SizedBox(
                    width: 28,
                    child: Text('ف',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12))),
                SizedBox(
                    width: 28,
                    child: Text('ت',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12))),
                SizedBox(
                    width: 28,
                    child: Text('خ',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12))),
                SizedBox(
                    width: 34,
                    child: Text('ف.أ',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12))),
                SizedBox(
                    width: 36,
                    child: Text('نقاط',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                            fontSize: 12))),
              ],
            ),
          ),

          // محتوى الجدول
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFF38BDF8),
              child: FutureBuilder<List<StandingTeamModel>>(
                future: _standingsFuture,
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
                              'تعذر تحميل الترتيب\n${snapshot.error}',
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

                  final teams = snapshot.data ?? [];
                  if (teams.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد بيانات ترتيب مسجلة لهذا الدوري.',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: teams.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.white10),
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      final int displayRank =
                          team.rank > 0 ? team.rank : (index + 1);
                      final indicatorColor =
                          _getRankIndicatorColor(displayRank, teams.length);

                      return Container(
                        color: index.isEven
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF1E293B).withOpacity(0.35),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            // المؤشر اللوني للمركز + الرقم
                            Container(
                              width: 4,
                              height: 22,
                              margin: const EdgeInsets.only(left: 6),
                              decoration: BoxDecoration(
                                color: indicatorColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(
                              width: 22,
                              child: Text(
                                '$displayRank',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            // اسم الفريق + آخر النتائج
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team.teamName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  if (team.form.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    _FormBadges(form: team.form),
                                  ],
                                ],
                              ),
                            ),
                            // الإحصائيات
                            SizedBox(
                              width: 28,
                              child: Text('${team.played}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12.5)),
                            ),
                            SizedBox(
                              width: 28,
                              child: Text('${team.won}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12.5)),
                            ),
                            SizedBox(
                              width: 28,
                              child: Text('${team.drawn}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12.5)),
                            ),
                            SizedBox(
                              width: 28,
                              child: Text('${team.lost}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12.5)),
                            ),
                            SizedBox(
                              width: 34,
                              child: Text(
                                team.goalDiff > 0
                                    ? '+${team.goalDiff}'
                                    : '${team.goalDiff}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: team.goalDiff >= 0
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFFF87171),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${team.points}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
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

/// شارات آخر 5 مباريات (W/D/L)
class _FormBadges extends StatelessWidget {
  final String form;

  const _FormBadges({required this.form});

  @override
  Widget build(BuildContext context) {
    final chars = form.replaceAll(',', '').trim().split('');
    return Row(
      children: chars.take(5).map((c) {
        final upper = c.toUpperCase();
        Color bg;
        if (upper == 'W') {
          bg = const Color(0xFF22C55E);
        } else if (upper == 'D') {
          bg = const Color(0xFF94A3B8);
        } else {
          bg = const Color(0xFFEF4444);
        }
        return Container(
          margin: const EdgeInsets.only(left: 3),
          width: 14,
          height: 14,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg.withOpacity(0.25),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: bg, width: 0.8),
          ),
          child: Text(
            upper,
            style: TextStyle(
              color: bg,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }
}
