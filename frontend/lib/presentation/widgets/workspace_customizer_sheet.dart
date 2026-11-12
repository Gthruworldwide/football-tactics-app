import 'package:flutter/material.dart';
import '../../core/services/user_prefs_service.dart';
import '../../core/theme/app_theme.dart';

class WorkspaceCustomizerSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const WorkspaceCustomizerSheet({required this.onSaved, super.key});

  @override
  State<WorkspaceCustomizerSheet> createState() => _WorkspaceCustomizerSheetState();
}

class _WorkspaceCustomizerSheetState extends State<WorkspaceCustomizerSheet> {
  final Map<String, String> _availableLeagues = {
    'EG': 'Egyptian Premier League',
    'ENG': 'English Premier League',
    'ESP': 'Spanish La Liga',
    'ITA': 'Italian Serie A',
    'GER': 'German Bundesliga',
  };

  final List<String> _lenses = ['Possession', 'Offensive (xG)', 'Defensive (PPDA)'];

  List<String> _selectedLeagues = [];
  String _selectedLens = 'Possession';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final leagues = await UserPrefsService.getSelectedLeagues();
    final lens = await UserPrefsService.getTacticalLens();
    setState(() {
      _selectedLeagues = leagues;
      _selectedLens = lens;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERSONALIZE WORKSPACE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppTheme.accentEmerald,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Active Leagues',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableLeagues.entries.map((entry) {
              final active = _selectedLeagues.contains(entry.key);
              return FilterChip(
                label: Text(entry.value),
                selected: active,
                selectedColor: AppTheme.accentEmerald.withOpacity(0.2),
                checkmarkColor: AppTheme.accentEmerald,
                labelStyle: TextStyle(
                  color: active ? AppTheme.accentEmerald : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) async {
                  await UserPrefsService.toggleLeague(entry.key);
                  await _load();
                  widget.onSaved();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tactical Telemetry Lens',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _lenses.map((lens) {
              final active = _selectedLens == lens;
              return ChoiceChip(
                label: Text(lens),
                selected: active,
                selectedColor: AppTheme.accentCyan.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: active ? AppTheme.accentCyan : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) async {
                  await UserPrefsService.setTacticalLens(lens);
                  await _load();
                  widget.onSaved();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}