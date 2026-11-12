import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/network/api_client.dart';
import '../core/services/user_prefs_service.dart';

class StandingsView extends StatefulWidget {
  final String countryCode;
  final List<String> favoriteTeams;
  final Function(String) onFavoriteToggle;

  const StandingsView({
    required this.countryCode,
    required this.favoriteTeams,
    required this.onFavoriteToggle,
    super.key,
  });

  @override
  State<StandingsView> createState() => _StandingsViewState();
}

class _StandingsViewState extends State<StandingsView> {
  List _standings = [];
  bool _isLoading = true;
  List<String> _favoriteTeams = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _favoriteTeams = await UserPrefsService.getFavoriteTeams();

    try {
      final res = await ApiClient.get(
        ApiClient.standingsEndpoint(widget.countryCode),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List resp = decoded['response'] ?? [];
        if (resp.isNotEmpty) {
          final List standingsGroups =
              resp[0]['league']?['standings'] ?? [];
          if (standingsGroups.isNotEmpty) {
            final List table = standingsGroups[0];
            final parsed = table.map((row) {
              final gdNum = row['goalsDiff'] ?? 0;
              return {
                'rank': row['rank'] ?? 0,
                'team': row['team']?['name'] ?? 'Team',
                'played': row['all']?['played'] ?? 0,
                'gd': gdNum >= 0 ? '+$gdNum' : '$gdNum',
                'pts': row['points'] ?? 0,
                'form': (row['form'] ?? 'DDDDD').toString(),
              };
            }).toList();

            setState(() {
              _standings = parsed;
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (_) {}

    setState(() {
      _standings = [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentEmerald),
      );
    }

    if (_standings.isEmpty) {
      return const Center(
        child: Text(
          'No standings available.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _standings.length,
      itemBuilder: (context, index) {
        final team = _standings[index];
        final isFavorite = widget.favoriteTeams.any((t) =>
          team['team'].toString().toLowerCase().contains(t.toLowerCase()));

        return _StandingCard(
          rank: team['rank'] ?? index + 1,
          teamName: team['team'] ?? 'Team',
          played: team['played'] ?? 0,
          gd: team['gd'] ?? '+0',
          pts: team['pts'] ?? 0,
          form: team['form'] ?? '-----',
          isFavorite: isFavorite,
          onFavoriteToggle: widget.onFavoriteToggle,
        );
      },
    );
  }
}

class _StandingCard extends StatelessWidget {
  final int rank;
  final String teamName;
  final int played;
  final String gd;
  final int pts;
  final String form;
  final bool isFavorite;
  final Function(String) onFavoriteToggle;

  const _StandingCard({
    required this.rank,
    required this.teamName,
    required this.played,
    required this.gd,
    required this.pts,
    required this.form,
    required this.isFavorite,
    required this.onFavoriteToggle,
    Key? key,
  }) : super(key: key);

  Color _getGdColor() {
    final sign = gd[0] == '+' ? 1 : -1;
    final value = double.parse(gd.substring(1)) * sign;
    return value > 0 ? AppTheme.accentEmerald : AppTheme.accentCyan;
  }

  @override
  Widget build(BuildContext context) {
    final color = isFavorite ? AppTheme.accentEmerald : Theme.of(context).colorScheme.onSurface;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      color: Theme.of(context).colorScheme.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isFavorite ? AppTheme.accentEmerald.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                color: isFavorite ? AppTheme.accentEmerald : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                teamName,
                style: TextStyle(
                  color: color,
                  fontWeight: isFavorite ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isFavorite)
              const Icon(
                Icons.star,
                color: AppTheme.accentEmerald,
                size: 18,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 4),
            Text(
              gd,
              style: TextStyle(
                color: _getGdColor(),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$pts pts',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () => onFavoriteToggle(teamName),
      ),
    );
  }
}