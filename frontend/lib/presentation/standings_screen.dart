import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/data_error_localizer.dart';
import '../core/data_source_label.dart';
import '../core/league_catalog.dart';
import '../core/services/app_language.dart';
import 'widgets/language_menu_button.dart';

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
    final team = json['team'] is Map<String, dynamic>
        ? json['team'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final all = json['all'] is Map<String, dynamic>
        ? json['all'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final goals = all['goals'] is Map<String, dynamic>
        ? all['goals'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final int gf = _asInt(json['goals_for'] ?? json['gf'] ?? goals['for']);
    final int ga = _asInt(
      json['goals_against'] ?? json['ga'] ?? goals['against'],
    );
    return StandingTeamModel(
      rank: _asInt(json['rank'] ?? json['position']),
      teamName: (json['team_name'] ?? team['name'] ?? json['team'] ?? '')
          .toString(),
      league: (json['league'] ?? json['group'] ?? '').toString(),
      played: _asInt(json['played'] ?? json['mp'] ?? all['played']),
      won: _asInt(json['won'] ?? json['w'] ?? all['win']),
      drawn: _asInt(json['drawn'] ?? json['d'] ?? all['draw']),
      lost: _asInt(json['lost'] ?? json['l'] ?? all['lose']),
      goalsFor: gf,
      goalsAgainst: ga,
      goalDiff: _asInt(
        json['goal_diff'] ?? json['gd'] ?? json['goalsDiff'] ?? (gf - ga),
      ),
      points: _asInt(json['points'] ?? json['pts']),
      form: (json['form'] ?? '').toString(),
    );
  }

  static int _asInt(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
}

class StandingsScreen extends StatefulWidget {
  final String serverHost;

  const StandingsScreen({super.key, this.serverHost = '192.168.1.14:8000'});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  final _leagues = LeagueCatalog.supported
      .where((option) => option.code != 'EG')
      .toList(growable: false);

  String _selectedLeague = 'ESP';
  int? _season;
  String? _source;
  late Future<List<StandingTeamModel>> _standingsFuture;

  @override
  void initState() {
    super.initState();
    _standingsFuture = _fetchStandings(_selectedLeague);
  }

  Future<List<StandingTeamModel>> _fetchStandings(String league) async {
    final uri = Uri.http(widget.serverHost, '/api/v1/standings/$league');

    final response = await http.get(uri).timeout(const Duration(seconds: 40));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final season = decoded['season'];
      final source = decoded['source'] as String?;
      // A slow response for a previously selected league must not overwrite
      // the season label for the currently selected league.
      if (mounted && _selectedLeague == league) {
        setState(() {
          _season = season is num ? season.toInt() : null;
          _source = source;
        });
      }
      final List<dynamic> list = decoded['standings'] ?? [];
      return list.map((e) => StandingTeamModel.fromJson(e)).toList();
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
      _standingsFuture = _fetchStandings(league);
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _season = null;
      _source = null;
      _standingsFuture = _fetchStandings(_selectedLeague);
    });
    try {
      await _standingsFuture;
    } catch (_) {
      // FutureBuilder presents the localized error state.
    }
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
                  ? 'جدول ترتيب الدوري'
                  : 'League Standings',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (_season != null || _source != null)
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
                ? 'تحديث الترتيب'
                : 'Refresh standings',
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

          // ترويسة الأعمدة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFF1E293B).withValues(alpha: 0.7),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '#',
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    AppLanguage.instance.isArabic ? 'الفريق' : 'Team',
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    AppLanguage.instance.isArabic ? 'لعب' : 'MP',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    AppLanguage.instance.isArabic ? 'ف' : 'W',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    AppLanguage.instance.isArabic ? 'ت' : 'D',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    AppLanguage.instance.isArabic ? 'خ' : 'L',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                SizedBox(
                  width: 34,
                  child: Text(
                    AppLanguage.instance.isArabic ? 'ف.أ' : 'GD',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    AppLanguage.instance.isArabic ? 'نقاط' : 'PTS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
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
                              '${AppLanguage.instance.isArabic ? 'تعذر تحميل الترتيب' : 'Could not load standings'}\n${localizedDataError(snapshot.error!, isArabic: AppLanguage.instance.isArabic, fallback: AppLanguage.instance.isArabic ? 'تحقق من الاتصال بالخادم ثم أعد المحاولة.' : 'Check the backend connection and retry.')}',
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

                  final teams = snapshot.data ?? [];
                  if (teams.isEmpty) {
                    return Center(
                      child: Text(
                        AppLanguage.instance.isArabic
                            ? 'لا توجد بيانات ترتيب متاحة لهذا الدوري حاليًا.'
                            : 'No standings are currently available for this league.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: teams.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.white10),
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      final int displayRank = team.rank > 0
                          ? team.rank
                          : (index + 1);
                      final indicatorColor = _getRankIndicatorColor(
                        displayRank,
                        teams.length,
                      );

                      return Container(
                        color: index.isEven
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF1E293B).withValues(alpha: 0.35),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
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
                              child: Text(
                                '${team.played}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${team.won}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${team.drawn}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${team.lost}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),
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
            color: bg.withValues(alpha: 0.25),
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
