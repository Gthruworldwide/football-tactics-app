import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../core/theme/app_theme.dart';
import 'player_stats_screen.dart';

class PlayerSearchScreen extends StatefulWidget {
  final String? initialQuery;
  const PlayerSearchScreen({this.initialQuery, super.key});

  @override
  State<PlayerSearchScreen> createState() => _PlayerSearchScreenState();
}

class _PlayerSearchScreenState extends State<PlayerSearchScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _searchPlayers(widget.initialQuery!);
    } else {
      _searchPlayers('Salah'); // اقتراح افتراضي سريع
    }
  }

  Future<void> _searchPlayers(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final uri = Uri.parse(
        'https://www.thesportsdb.com/api/v1/json/3/searchplayers.php?p=${Uri.encodeComponent(q)}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List? list = data['player'];
        if (list != null) {
          setState(() {
            _results = list
                .where((item) =>
                    (item['strSport'] ?? '').toString().toLowerCase() ==
                    'soccer')
                .map((item) => {
                      'id': int.tryParse(item['idPlayer']?.toString() ?? '') ??
                          141,
                      'name': item['strPlayer'] ?? 'Player',
                      'team': item['strTeam'] ?? 'Free Agent',
                      'position': item['strPosition'] ?? 'Midfielder',
                      'nationality': item['strNationality'] ?? '',
                      'photo': item['strCutout'] ?? item['strThumb'],
                    })
                .toList()
                .cast<Map<String, dynamic>>();
            _isSearching = false;
          });
          return;
        }
      }
    } catch (_) {}

    setState(() {
      _results = [];
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SCOUTING DATABASE')),
      body: SafeArea(
        child: Column(
          children: [
            // شريط البحث المريح للهاتف
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _searchPlayers,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search player (e.g. Yamal, Haaland, Marmoush)',
                  hintStyle: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppTheme.accentCyan),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded,
                        color: AppTheme.accentEmerald),
                    onPressed: () => _searchPlayers(_searchController.text),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.borderSubtle),
                  ),
                ),
              ),
            ),

            // نتائج البحث
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.accentEmerald),
                    )
                  : _results.isEmpty
                      ? const Center(
                          child: Text(
                            'No players found. Try another name.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final p = _results[index];
                            final photo = p['photo']?.toString();
                            final name = p['name'].toString();

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(
                                    color: AppTheme.borderSubtle),
                              ),
                              tileColor: AppTheme.surfaceCard,
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.surfaceElevated,
                                backgroundImage:
                                    (photo != null && photo.isNotEmpty)
                                        ? NetworkImage(photo)
                                        : null,
                                child: (photo == null || photo.isEmpty)
                                    ? Text(
                                        name.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(
                                          color: AppTheme.accentEmerald,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                '${p['team']} • ${p['position']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.radar_rounded,
                                color: AppTheme.accentCyan,
                              ),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PlayerStatsScreen(
                                      playerId: p['id'],
                                      playerName: name,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
