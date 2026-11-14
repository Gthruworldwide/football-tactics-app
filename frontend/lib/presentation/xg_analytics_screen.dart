import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/data_error_localizer.dart';
import '../core/data_source_label.dart';
import '../core/models/football_api_models.dart';
import '../core/league_catalog.dart';
import 'widgets/language_menu_button.dart';

class XgAnalyticsScreen extends StatefulWidget {
  final String serverHost;

  const XgAnalyticsScreen({super.key, this.serverHost = '192.168.1.14:8000'});

  @override
  State<XgAnalyticsScreen> createState() => _XgAnalyticsScreenState();
}

class _XgAnalyticsScreenState extends State<XgAnalyticsScreen> {
  static const _leagues = LeagueCatalog.supported;

  String _selectedLeague = 'ENG';
  late Future<_FixtureFeed> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = _fetchMatches();
  }

  Future<_FixtureFeed> _fetchMatches() async {
    final uri = Uri.http(widget.serverHost, '/api/v1/matches/$_selectedLeague');
    final response = await http.get(uri).timeout(const Duration(seconds: 40));
    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200) {
      final detail = decoded is Map ? decoded['detail'] : null;
      throw Exception(detail ?? 'Server returned ${response.statusCode}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid matches response');
    }
    final responseModel = MatchesResponse.fromJson(decoded);
    return _FixtureFeed(
      season: responseModel.season,
      source: responseModel.source,
      matches: responseModel.matches,
    );
  }

  void _selectLeague(String code) {
    if (_selectedLeague == code) return;
    setState(() {
      _selectedLeague = code;
      _matchesFuture = _fetchMatches();
    });
  }

  Future<void> _refresh() async {
    setState(() => _matchesFuture = _fetchMatches());
    try {
      await _matchesFuture;
    } catch (_) {
      // FutureBuilder presents the localized error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          isArabic ? 'المباريات وتحليل xG' : 'Matches & xG',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          const LanguageMenuButton(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: isArabic ? 'تحديث' : 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _leagues.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = _leagues[index];
                final selected = option.code == _selectedLeague;
                return ChoiceChip(
                  label: Text(option.label(isArabic: isArabic)),
                  selected: selected,
                  onSelected: (_) => _selectLeague(option.code),
                  selectedColor: const Color(0xFF38BDF8),
                  backgroundColor: const Color(0xFF334155),
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : Colors.white70,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<_FixtureFeed>(
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
                    return _MessageView(
                      icon: Icons.cloud_off_outlined,
                      message: isArabic
                          ? 'تعذر تحميل المباريات.\n${localizedDataError(snapshot.error!, isArabic: true, fallback: 'تحقق من الاتصال بالخادم ثم أعد المحاولة.')}'
                          : 'Could not load matches.\n${localizedDataError(snapshot.error!, isArabic: false, fallback: 'Check the backend connection and retry.')}',
                      actionLabel: isArabic ? 'إعادة المحاولة' : 'Retry',
                      onPressed: _refresh,
                    );
                  }

                  final feed = snapshot.data;
                  final matches = feed?.matches ?? const <FixtureMatch>[];
                  if (matches.isEmpty) {
                    return _MessageView(
                      icon: Icons.sports_soccer_outlined,
                      message: isArabic
                          ? 'لا توجد مباريات متاحة لهذا الدوري حاليًا.'
                          : 'No matches are currently available for this league.',
                      actionLabel: isArabic ? 'تحديث' : 'Refresh',
                      onPressed: _refresh,
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: matches.length + 1,
                    itemBuilder: (_, index) {
                      if (index == 0) {
                        final season = feed?.season;
                        final label = season == null
                            ? (isArabic ? 'الموسم الحالي' : 'Current season')
                            : isArabic
                            ? 'موسم $season/${season + 1}'
                            : 'Season $season/${season + 1}';
                        final source = dataSourceLabel(
                          feed?.source,
                          isArabic: isArabic,
                        );
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
                          child: Text(
                            source == null ? label : '$label  ·  $source',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                      return _FixtureCard(
                        match: matches[index - 1],
                        isArabic: isArabic,
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

class _FixtureFeed {
  final int? season;
  final String? source;
  final List<FixtureMatch> matches;

  const _FixtureFeed({
    required this.season,
    required this.source,
    required this.matches,
  });
}

class _FixtureCard extends StatelessWidget {
  final FixtureMatch match;
  final bool isArabic;

  const _FixtureCard({required this.match, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(match.fixtureDate);
    final dateLabel = date == null
        ? match.fixtureDate
        : MaterialLocalizations.of(context).formatShortDate(date.toLocal());
    final hasScore = match.homeScore != null && match.awayScore != null;
    final hasXg = match.homeXg != null && match.awayXg != null;

    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    match.leagueName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(dateLabel, style: const TextStyle(color: Colors.white54)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.homeTeam,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    hasScore
                        ? '${match.homeScore}  –  ${match.awayScore}'
                        : 'VS',
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  match.displayStatusLabel(isArabic: isArabic),
                  style: const TextStyle(color: Colors.white60),
                ),
                Text(
                  hasXg
                      ? 'xG  ${match.homeXg!.toStringAsFixed(2)} – ${match.awayXg!.toStringAsFixed(2)}'
                      : (isArabic
                            ? 'بيانات xG غير متاحة'
                            : 'xG data unavailable'),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _MessageView({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      const SizedBox(height: 120),
      Icon(icon, size: 44, color: Colors.white38),
      const SizedBox(height: 16),
      Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70),
      ),
      const SizedBox(height: 16),
      Center(
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.refresh),
          label: Text(actionLabel),
        ),
      ),
    ],
  );
}
