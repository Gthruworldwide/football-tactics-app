import 'package:flutter/material.dart';
import '../logic/matches_bloc.dart';
import 'date_bar.dart';
import 'league_filter_chips.dart';
import 'match_card.dart';
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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        elevation: 0,
      ),
      body: Column(
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
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: 10,
              itemBuilder: (context, index) {
                return MatchCard(
                  match: MatchCache(
                    matchId: 'match_$index',
                    homeTeam: 'Team A',
                    awayTeam: 'Team B',
                    homeGoals: index % 3,
                    awayGoals: index % 2,
                    homeXG: 1.2,
                    awayXG: 0.8,
                    homeXA: 0.5,
                    awayXA: 0.3,
                    homePPDA: 10,
                    awayPPDA: 12,
                    homeFieldTilt: '60%',
                    awayFieldTilt: '40%',
                    minute: 65,
                    channel: 'Sky Sports',
                    commentator: 'John Smith',
                    country: 'England',
                    matchDate: DateTime.now(),
                  ),
                  isLive: index % 2 == 0,
                );
              },
            ),
          ),
        ],
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
      appBar: AppBar(
        title: const Text('Standings'),
        elevation: 0,
      ),
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
      appBar: AppBar(
        title: const Text('Confederation Settings'),
        elevation: 0,
      ),
      body: const Center(
        child: Text('International/Confederation settings will be displayed here'),
      ),
    );
  }
}