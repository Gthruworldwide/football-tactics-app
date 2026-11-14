String? dataSourceLabel(String? source, {required bool isArabic}) {
  final provider = switch (source) {
    'football-data' => 'football-data.org',
    'highlightly' => 'Highlightly',
    'api-football' => 'API-Football',
    _ => null,
  };
  if (provider == null) return null;
  return isArabic ? 'المصدر: $provider' : 'Source: $provider';
}
