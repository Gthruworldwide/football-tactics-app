/// Core constants used across the application.
class AppConstants {
  // 5-Country Geographic Filter
  static const List<String> permanentCountries = [
    'England',
    'Spain',
    'Italy',
  ];

  // Dynamic Geo-IP country (auto-detected)
  static const String dynamicGeoIPCountry = 'Egypt'; // Example

  // User-selectable country
  static const String userSelectableCountry = 'Netherlands';

  // API endpoints
  static const String apiFootballBase = 'https://api-football-v1.p.rapidapi.com/v3';

  // Cache TTL values (seconds)
  static const int liveMatchCacheTTL = 15;    // 15 seconds for live data
  static const int staticDataCacheTTL = 86400; // 24 hours for standings

  // UI constants
  static const double horizontalPadding = 16.0;
  static const double verticalPadding = 8.0;
  // Border radius defined as a constant value for use in widgets
  static const double borderRadiusValue = 8.0;
}