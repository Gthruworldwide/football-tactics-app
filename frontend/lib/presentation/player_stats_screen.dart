import 'package:flutter/material.dart';

import '../core/services/app_language.dart';
import '../core/theme/app_theme.dart';
import 'widgets/language_menu_button.dart';

/// The selected-player details endpoint is not available from the current
/// data provider. Keep this screen honest instead of presenting demo stats.
class PlayerStatsScreen extends StatelessWidget {
  final int playerId;
  final String playerName;

  const PlayerStatsScreen({
    required this.playerId,
    required this.playerName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLanguage.instance.isArabic;
    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'ملف اللاعب' : 'Player profile'),
        actions: const [LanguageMenuButton()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_search_outlined,
                size: 56,
                color: AppTheme.accentCyan,
              ),
              const SizedBox(height: 16),
              Text(
                playerName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'المصدر الحالي لا يوفّر إحصائيات تفصيلية موثوقة لهذا اللاعب. لن نعرض أرقامًا تجريبية.'
                    : 'The current provider does not supply verified detailed stats for this player. Demo numbers are intentionally hidden.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
