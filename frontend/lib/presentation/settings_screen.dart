import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/services/geo_service.dart';
import '../core/services/user_prefs_service.dart';
import '../core/theme/app_theme.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _clubController = TextEditingController();

  String _userName = 'Analyst';
  String _userRole = 'Tactical Analyst';
  List<String> _selectedLeagues = [];
  List<String> _favoriteTeams = [];
  List<CountryInfo> _allCountries = [];
  String _countryQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final box = Hive.box('user_prefs_box');
    final leagues = await UserPrefsService.getSelectedLeagues();
    final teams = await UserPrefsService.getFavoriteTeams();
    final countries = await GeoService.getAllCountries();
    setState(() {
      _userName = box.get('user_name', defaultValue: 'Analyst');
      _userRole = box.get('user_role', defaultValue: 'Tactical Analyst');
      _selectedLeagues = leagues;
      _favoriteTeams = teams;
      _allCountries = countries;
    });
  }

  Future<void> _clearCache() async {
    HapticFeedback.mediumImpact();
    if (Hive.isBoxOpen('players_box')) {
      await Hive.box('players_box').clear();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Local data refreshed successfully.'),
        backgroundColor: AppTheme.accentEmerald,
      ),
    );
  }

  Future<void> _signOut() async {
    final box = Hive.box('user_prefs_box');
    await box.put('is_logged_in', false);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WORKSPACE SETTINGS')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.accentEmerald.withOpacity(0.18),
                  child: Text(
                    _userName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.accentEmerald,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_userName,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary)),
                      Text(_userRole,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.accentCyan)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _signOut,
                  child: const Text('Sign Out',
                      style: TextStyle(color: Color(0xFFEF4444))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Countries & Leagues Selection
          _sectionTitle('MY COMPETITIONS & COUNTRIES'),
          const SizedBox(height: 8),
          TextField(
            onChanged: (val) => setState(() => _countryQuery = val.trim().toLowerCase()),
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Filter countries (e.g. Egypt, Spain, Brazil)...',
              hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              prefixIcon: const Icon(Icons.public_rounded, color: AppTheme.accentEmerald, size: 18),
              filled: true,
              fillColor: AppTheme.surfaceCard,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderSubtle),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allCountries
                .where((c) =>
                    _countryQuery.isEmpty ||
                    c.name.toLowerCase().contains(_countryQuery) ||
                    c.alpha2Code.toLowerCase().contains(_countryQuery))
                .take(18)
                .map((c) {
              final active = _selectedLeagues.contains(c.alpha2Code);
              return FilterChip(
                label: Text('${c.name} (${c.alpha2Code})'),
                selected: active,
                selectedColor: AppTheme.accentEmerald.withOpacity(0.2),
                checkmarkColor: AppTheme.accentEmerald,
                labelStyle: TextStyle(
                  color: active ? AppTheme.accentEmerald : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) async {
                  HapticFeedback.selectionClick();
                  await UserPrefsService.toggleLeague(c.alpha2Code);
                  await _loadSettings();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // 3. Tracked Clubs Management
          _sectionTitle('TRACKED CLUBS'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _clubController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add club (e.g. Arsenal, Al Ahly)',
                    hintStyle: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: AppTheme.surfaceCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderSubtle),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                    backgroundColor: AppTheme.accentEmerald),
                icon: const Icon(Icons.add, color: AppTheme.bgObsidian),
                onPressed: () async {
                  final name = _clubController.text.trim();
                  if (name.isNotEmpty) {
                    await UserPrefsService.toggleFavoriteTeam(name);
                    _clubController.clear();
                    await _loadSettings();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _favoriteTeams.map((team) {
              return Chip(
                label: Text(team,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 12)),
                backgroundColor: AppTheme.surfaceCard,
                deleteIconColor: const Color(0xFFEF4444),
                onDeleted: () async {
                  await UserPrefsService.toggleFavoriteTeam(team);
                  await _loadSettings();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // 4. Refresh Local Data
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accentCyan,
              side: const BorderSide(color: AppTheme.borderSubtle),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _clearCache,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('REFRESH LOCAL CACHE'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: AppTheme.textSecondary,
        ),
      );
}
