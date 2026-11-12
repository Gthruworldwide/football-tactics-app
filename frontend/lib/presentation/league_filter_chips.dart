import 'package:flutter/material.dart';

/// League filter chips for selecting the 5 countries (SofaScore-inspired)
class LeagueFilterChips extends StatefulWidget {
  final ValueChanged<String> onCountrySelected;
  final String? selectedCountry;
  final bool showGeoIP;

  const LeagueFilterChips({
    required this.onCountrySelected,
    this.selectedCountry,
    this.showGeoIP = true,
    super.key,
  });

  @override
  State<LeagueFilterChips> createState() => _LeagueFilterChipsState();
}

class _LeagueFilterChipsState extends State<LeagueFilterChips> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: _buildCountryChips(theme),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCountryChips(ThemeData theme) {
    return [
      _CountryFilterChip(
        country: 'England',
        isPermanent: true,
        isSelected: widget.selectedCountry == 'England',
        onSelected: widget.onCountrySelected,
      ),
      _CountryFilterChip(
        country: 'Spain',
        isPermanent: true,
        isSelected: widget.selectedCountry == 'Spain',
        onSelected: widget.onCountrySelected,
      ),
      _CountryFilterChip(
        country: 'Italy',
        isPermanent: true,
        isSelected: widget.selectedCountry == 'Italy',
        onSelected: widget.onCountrySelected,
      ),
      if (widget.showGeoIP)
        _CountryFilterChip(
          country: 'Egypt',
          isPermanent: false,
          isSelected: widget.selectedCountry == 'Egypt',
          onSelected: widget.onCountrySelected,
        ),
      _CountryFilterChip(
        country: 'Netherlands',
        isPermanent: false,
        isSelected: widget.selectedCountry == 'Netherlands',
        onSelected: widget.onCountrySelected,
      ),
    ];
  }
}

/// Individual country filter chip with premium styling
class _CountryFilterChip extends StatelessWidget {
  final String country;
  final bool isPermanent;
  final bool isSelected;
  final ValueChanged<String> onSelected;

  const _CountryFilterChip({
    required this.country,
    required this.isPermanent,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        type: MaterialType.transparency,
        child: ChoiceChip(
          label: Text(country),
          selected: isSelected,
          selectedColor: colors.primary,
          backgroundColor: colors.surface,
          avatar: isPermanent
              ? const Icon(Icons.lock_open, size: 16, color: Colors.blue)
              : null,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : colors.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          side: BorderSide(
            color: isSelected ? colors.primary : colors.outline,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onSelected: (_) => onSelected(country),
          disabledColor: colors.outline.withOpacity(0.3),
        ),
      ),
    );
  }
}