import 'package:flutter/material.dart';

import 'date_bar.dart';
import 'league_filter_chips.dart';
import 'soa_score_nav_bar.dart';

/// Main screen with BottomNavigationBar (Matches, Standings, Confederation Settings)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MatchesTab(),
    const StandingsTab(),
    const ConfederationSettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: SoaScoreNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

/// Matches tab with date picker, country filters, and match cards
class MatchesTab extends StatefulWidget {
  const MatchesTab({super.key});

  @override
  State<MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends State<MatchesTab> {
  DateTime _selectedDate = DateTime.now();
  final List<DateTime> _dateRange = List.generate(
    30,
    (i) => DateTime.now().subtract(Duration(days: i)),
  ).reversed.toList();

  Future<void> _onRefresh() async {
    // Trigger BLoC to reload matches for current country/date
    // For now, just a placeholder - in real implementation would call MatchesBloc
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matches'), elevation: 0),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            DateBar(
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
              selectedDate: _selectedDate,
              dateRange: _dateRange,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: LeagueFilterChips(
                onCountrySelected: (country) {
                  // Handle country selection
                },
                selectedCountry: 'England',
                userSelectedCountry: 'Netherlands',
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: const Center(
                child: Text(
                  'Open the verified Matches & xG screen for fixtures.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// League Standings tab
class StandingsTab extends StatelessWidget {
  const StandingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Standings'), elevation: 0),
      body: const Center(
        child: Text('League Standings will be displayed here'),
      ),
    );
  }
}

/// International/Confederation Settings tab
class ConfederationSettingsTab extends StatelessWidget {
  const ConfederationSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confederation Settings'), elevation: 0),
      body: const Center(
        child: Text(
          'International/Confederation settings will be displayed here',
        ),
      ),
    );
  }
}
