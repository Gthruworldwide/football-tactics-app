import 'package:hive/hive.dart';

/// User preferences for country selection
class UserPreferences extends HiveObject {
  final String selectedCountry;
  final bool showTacticalStats;
  final bool liveUpdatesEnabled;

  UserPreferences({
    required this.selectedCountry,
    this.showTacticalStats = true,
    this.liveUpdatesEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'selectedCountry': selectedCountry,
      'showTacticalStats': showTacticalStats,
      'liveUpdatesEnabled': liveUpdatesEnabled,
    };
  }

  UserPreferences fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      selectedCountry: map['selectedCountry'] as String,
      showTacticalStats: map['showTacticalStats'] as bool? ?? true,
      liveUpdatesEnabled: map['liveUpdatesEnabled'] as bool? ?? true,
    );
  }
}