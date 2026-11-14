import 'package:flutter/material.dart';

/// League filter chips for selecting the 5 countries (SofaScore-inspired)
class LeagueFilterChips extends StatefulWidget {
  final ValueChanged<String> onCountrySelected;
  final String? selectedCountry;
  final bool showGeoIP;
  final String userSelectedCountry;

  const LeagueFilterChips({
    required this.onCountrySelected,
    this.selectedCountry,
    this.showGeoIP = true,
    this.userSelectedCountry = 'Netherlands',
    super.key,
  });

  @override
  State<LeagueFilterChips> createState() => _LeagueFilterChipsState();
}

class _LeagueFilterChipsState extends State<LeagueFilterChips> {
  void _showAddCountrySheet(BuildContext context) {
    String searchQuery = '';
    final List<String> availableCountries = [
      'Netherlands',
      'Germany',
      'France',
      'Portugal',
      'Belgium',
      'Turkey',
      'Greece',
      'Austria',
      'Switzerland',
      'Denmark',
      'Scotland',
      'Norway',
      'Sweden',
      'Poland',
      'Russia',
      'Ukraine',
      'Serbia',
      'Croatia',
      'Czech Republic',
      'Romania',
      'Saudi Arabia',
      'Qatar',
      'UAE',
      'Japan',
      'South Korea',
      'USA',
      'Mexico',
      'Brazil',
      'Argentina',
    ];

    // Filter out already selected countries
    final permanentCountries = ['England', 'Spain', 'Italy'];
    final geoIPCountry = 'Egypt';
    final excludedCountries = [
      ...permanentCountries,
      geoIPCountry,
      widget.userSelectedCountry,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final filteredCountries = availableCountries
                  .where((c) => !excludedCountries.contains(c))
                  .where(
                    (c) => c.toLowerCase().contains(searchQuery.toLowerCase()),
                  )
                  .toList();

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outline
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Row(
                        children: [
                          Text(
                            'Select 5th Country',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    // Search field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        onChanged: (value) {
                          setSheetState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search countries...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Country list
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredCountries.length,
                        itemBuilder: (context, index) {
                          final country = filteredCountries[index];
                          return ListTile(
                            title: Text(country),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onCountrySelected(country);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

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
          child: Row(children: _buildCountryChips(theme)),
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
        country: widget.userSelectedCountry,
        isPermanent: false,
        isSelected: widget.selectedCountry == widget.userSelectedCountry,
        onSelected: widget.onCountrySelected,
      ),
      // Add Country button (5th country selector)
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Material(
          type: MaterialType.transparency,
          child: FilterChip(
            label: const Text('+ Add Country'),
            selected: false,
            onSelected: (_) => _showAddCountrySheet(context),
            avatar: Icon(
              Icons.add_circle_outline,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            labelStyle: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(
              0.3,
            ),
          ),
        ),
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
