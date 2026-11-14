class LeagueOption {
  final String code;
  final String englishName;
  final String arabicName;

  const LeagueOption(this.code, this.englishName, this.arabicName);

  String label({required bool isArabic}) => isArabic ? arabicName : englishName;
}

class LeagueCatalog {
  static const supported = <LeagueOption>[
    LeagueOption('ENG', 'Premier League', 'الدوري الإنجليزي الممتاز'),
    LeagueOption('GER', 'Bundesliga', 'الدوري الألماني'),
    LeagueOption('ITA', 'Serie A', 'الدوري الإيطالي'),
    LeagueOption('ESP', 'La Liga', 'الدوري الإسباني'),
    LeagueOption('FRA', 'Ligue 1', 'الدوري الفرنسي'),
    LeagueOption('EG', 'Egyptian Premier League', 'الدوري المصري الممتاز'),
  ];
}
