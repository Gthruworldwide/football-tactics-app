import 'package:flutter/material.dart';
import 'date_bar.dart';
import 'league_filter_chips.dart';

/// Header section with date picker and country filters
class MatchHeader extends StatelessWidget {
  final Function(DateTime) onDateSelected;
  final DateTime selectedDate;
  final List<DateTime> dateRange;
  final ValueChanged<String> onCountrySelected;
  final String? selectedCountry;

  const MatchHeader({
    required this.onDateSelected,
    required this.selectedDate,
    required this.dateRange,
    required this.onCountrySelected,
    required this.selectedCountry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Date picker bar
          DateBar(
            onDateSelected: onDateSelected,
            selectedDate: selectedDate,
            dateRange: dateRange,
          ),
          const Divider(height: 1),

          // Country filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: LeagueFilterChips(
              onCountrySelected: onCountrySelected,
              selectedCountry: selectedCountry,
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

/// Bottom navigation bar for seamless mobile navigation (SofaScore-inspired)
class SoaScoreNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final TabController? tabController;
  final ValueChanged<String>? onCountryChanged;

  const SoaScoreNavBar({
    required this.currentIndex,
    required this.onTap,
    this.tabController,
    this.onCountryChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.5),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            // Matches tab
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Matches',
            ),
            // Tactical tab
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Tactical',
            ),
            // AI tab
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined),
              activeIcon: Icon(Icons.smart_toy),
              label: 'AI',
            ),
          ],
        ),
      ),
    );
  }
}