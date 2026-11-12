import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// نموذج بيانات المباراة مع إحصائيات xG
class MatchXgModel {
  final int understatId;
  final String league;
  final String matchDate;
  final String homeTeam;
  final String awayTeam;
  final int homeGoals;
  final int awayGoals;
  final double homeXg;
  final double awayXg;
  final double forecastWin;
  final double forecastDraw;
  final double forecastLoss;

  MatchXgModel({
    required this.understatId,
    required this.league,
    required this.matchDate,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeGoals,
    required this.awayGoals,
    required this.homeXg,
    required this.awayXg,
    required this.forecastWin,
    required this.forecastDraw,
    required this.forecastLoss,
  });

  factory MatchXgModel.fromJson(Map<String, dynamic> json) {
    return MatchXgModel(
      understatId: json['understat_id'] ?? 0,
      league: json['league'] ?? '',
      matchDate: (json['match_date'] ?? '').toString().split(' ').first,
      homeTeam: json['home_team'] ?? '',
      awayTeam: json['away_team'] ?? '',
      homeGoals: (json['home_goals'] ?? 0) as int,
      awayGoals: (json['away_goals'] ?? 0) as int,
      homeXg: (json['home_xg'] ?? 0.0).toDouble(),
      awayXg: (json['away_xg'] ?? 0.0).toDouble(),
      forecastWin: (json['forecast_win'] ?? 0.0).toDouble(),
      forecastDraw: (json['forecast_draw'] ?? 0.0).toDouble(),
      forecastLoss: (json['forecast_loss'] ?? 0.0).toDouble(),
    );
  }
}

class XgAnalyticsScreen extends StatefulWidget {
  /// استبدل العنوان بـ IP جهاز الكمبيوتر على شبكة Wi-Fi (مثال: '192.168.1.5:8000')
  /// أو اتركه '10.0.2.2:8000' لمحاكي أندرويد
  final String serverHost;

  const XgAnalyticsScreen({
    super.key,
    this.serverHost = '192.168.1.14:8000',
  });

  @override
  State<XgAnalyticsScreen> createState() => _XgAnalyticsScreenState();
}

class _XgAnalyticsScreenState extends State<XgAnalyticsScreen> {
  final List<String> _leagues = const [
    'La Liga',
    'Premier League',
    'Bundesliga',
    'Serie A',
    'Ligue 1',
  ];

  String _selectedLeague = 'La Liga';
  late Future<List<MatchXgModel>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = _fetchLeagueXg(_selectedLeague);
  }

  Future<List<MatchXgModel>> _fetchLeagueXg(String league) async {
    final uri = Uri.http(
      widget.serverHost,
      '/api/tactics/xg',
      {
        'league': league,
        'limit': '30',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list = decoded['matches_xg'] ?? [];
      return list.map((e) => MatchXgModel.fromJson(e)).toList();
    } else {
      throw Exception('خطأ في السيرفر: ${response.statusCode}');
    }
  }

  void _onLeagueChanged(String league) {
    if (_selectedLeague == league) return;
    setState(() {
      _selectedLeague = league;
      _matchesFuture = _fetchLeagueXg(league);
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _matchesFuture = _fetchLeagueXg(_selectedLeague);
    });
    await _matchesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'تحليل الأهداف المتوقعة (xG)',
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

          // قائمة المباريات
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFF38BDF8),
              child: FutureBuilder<List<MatchXgModel>>(
                future: _matchesFuture,
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
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off,
                                color: Colors.redAccent, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'تعذر الاتصال بالسيرفر (${widget.serverHost})\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 16),
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

                  final matches = snapshot.data ?? [];
                  if (matches.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد مباريات مسجلة لهذا الدوري حالياً.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      return _MatchXgCard(match: matches[index]);
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

/// بطاقة عرض المباراة ومقارنة الأهداف الفعلية مع xG
class _MatchXgCard extends StatelessWidget {
  final MatchXgModel match;

  const _MatchXgCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final double homeDiff = match.homeGoals - match.homeXg;
    final double awayDiff = match.awayGoals - match.awayXg;
    final double totalXg =
        (match.homeXg + match.awayXg) == 0 ? 1.0 : (match.homeXg + match.awayXg);
    final double homeXgRatio = (match.homeXg / totalXg).clamp(0.05, 0.95);

    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // التاريخ والدوري
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  match.league,
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  match.matchDate,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // أسماء الفريقين والنتيجة الفعلية
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.homeTeam,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    '${match.homeGoals}  -  ${match.awayGoals}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    match.awayTeam,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // مقارنة الأهداف المتوقعة (xG) والفارق عن الفعلي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _XgBadge(
                  xg: match.homeXg,
                  diff: homeDiff,
                  alignLeft: true,
                ),
                const Text(
                  'xG (الفارق)',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                _XgBadge(
                  xg: match.awayXg,
                  diff: awayDiff,
                  alignLeft: false,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // شريط السيطرة الهجومية بناءً على نسبة xG
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 7,
                child: Row(
                  children: [
                    Expanded(
                      flex: (homeXgRatio * 100).round(),
                      child: Container(color: const Color(0xFF38BDF8)),
                    ),
                    Expanded(
                      flex: ((1 - homeXgRatio) * 100).round(),
                      child: Container(color: const Color(0xFFF59E0B)),
                    ),
                  ],
                ),
              ),
            ),

            // احتمالات النتيجة حسب نموذج المحاكاة (Forecast)
            if (match.forecastWin > 0 ||
                match.forecastDraw > 0 ||
                match.forecastLoss > 0) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'فوز المضيف: ${(match.forecastWin * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  Text(
                    'تعادل: ${(match.forecastDraw * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  Text(
                    'فوز الضيف: ${(match.forecastLoss * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _XgBadge extends StatelessWidget {
  final double xg;
  final double diff;
  final bool alignLeft;

  const _XgBadge({
    required this.xg,
    required this.diff,
    required this.alignLeft,
  });

  @override
  Widget build(BuildContext context) {
    final bool overperformed = diff >= 0;
    final Color diffColor =
        overperformed ? const Color(0xFF4ADE80) : const Color(0xFFF87171);
    final String sign = overperformed ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          xg.toStringAsFixed(2),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: diffColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '($sign${diff.toStringAsFixed(2)})',
            style: TextStyle(
              color: diffColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
