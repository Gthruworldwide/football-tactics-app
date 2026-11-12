# الدليل المعماري الكامل للدمج وتحديث الواجهة (Native Android Mobile App)

## 1. ملخص المراجعة المعمارية والربط (Integration Audit)
تمت مراجعة جميع طبقات الواجهة الأمامية (`frontend`) لضمان تكاملها الكامل كتطبيق أندرويد أصيل (**Native Mobile-First App**) على هاتف **REA NX9** بدون أي تشتت للويب، مع إصلاح أي تعارضات محتملة بين الملفات:

1. **توحيد الحقول والخصائص:**
   - ربط `MatchesScreen` مع `UserPrefsService` لعرض الدوريات المختارة فقط (`selected_leagues`)، وتمييز الفرق المفضلة (`favorite_teams`) وتثبيت مبارياتها في أعلى القائمة تلقائياً.
   - ربط عدسة التحليل (`tactical_lens`) مع بطاقة المباراة (`TacticalMatchCard`) ونافذة التحليل السريع (`MatchTacticalSheet`) لتتغير المؤشرات المعروضة حسب اختيارك (`Possession`, `Offensive (xG)`, `Defensive (PPDA)`).
   - دمج شريط التنقل السفلي (`NavigationBar`) للتبديل السلس بيد واحدة بين **المباريات (`Matches`)** و **جدول الترتيب المخصص (`StandingsView`)** لنفس الدوري النشط.
   - إضافة زر متابعة/إلغاء متابعة الفريق (`Star Toggle`) مباشرة داخل نافذة تفاصيل المباراة لتحديث تفضيلاتك بضغطة واحدة.
2. **تجربة الهاتف الأصيلة (Mobile Ergonomics):**
   - قفل الشاشة في الوضع الرأسي (`portraitUp`) وتنسيق شريط الحالة وشريط الإيماءات العلوي والسفلي في Android 15.
   - تفعيل الاستجابة اللمسية (`HapticFeedback.lightImpact()`) عند التنقل وتغيير الفلاتر.

---

## 2. الملفات المحدثة والنهائية للدمج

### أولاً: تحديث بطاقة المباراة لدعم التمييز والعدسة التكتيكية (`frontend/lib/presentation/widgets/tactical_match_card.dart`)
```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TacticalMatchCard extends StatelessWidget {
  final String leagueName;
  final String homeTeam;
  final String awayTeam;
  final int? homeScore;
  final int? awayScore;
  final String status;
  final bool isLive;
  final bool isTracked;
  final String activeLens;
  final double homePossession;
  final String xgHome;
  final String xgAway;
  final VoidCallback onTap;

  const TacticalMatchCard({
    required this.leagueName,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    required this.status,
    this.isLive = false,
    this.isTracked = false,
    this.activeLens = 'Possession',
    this.homePossession = 50.0,
    this.xgHome = '1.20',
    this.xgAway = '0.95',
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final awayPossession = (100.0 - homePossession).clamp(0.0, 100.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isTracked
              ? AppTheme.accentEmerald.withOpacity(0.06)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLive
                ? AppTheme.accentEmerald.withOpacity(0.55)
                : (isTracked
                    ? AppTheme.accentCyan.withOpacity(0.45)
                    : AppTheme.borderSubtle),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Top Metadata Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (isTracked) ...[
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppTheme.accentCyan),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          leagueName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusPill(),
              ],
            ),
            const SizedBox(height: 16),

            // Teams & Score Row
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildTeamBadge(homeTeam, AppTheme.accentEmerald),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          homeTeam,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    homeScore != null && awayScore != null
                        ? '$homeScore  -$awayScore'
                        : 'VS',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color:
                          isLive ? AppTheme.accentEmerald : AppTheme.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          awayTeam,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildTeamBadge(awayTeam, AppTheme.accentCyan),
                    ],
                  ),
                ),
              ],
            ),

            // Dynamic Micro Telemetry Bar based on User's Selected Lens
            if (homeScore != null) ...[
              const SizedBox(height: 14),
              if (activeLens.contains('Offensive'))
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'xG $xgHome',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentEmerald,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Text(
                      'EXPECTED GOALS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      'xG $xgAway',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentCyan,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Text(
                      '${homePossession.toInt()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 4,
                          child: Row(
                            children: [
                              Expanded(
                                flex: homePossession.toInt().clamp(10, 90),
                                child: Container(color: AppTheme.accentEmerald),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                flex: awayPossession.toInt().clamp(10, 90),
                                child: Container(color: AppTheme.accentCyan),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${awayPossession.toInt()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isLive
            ? AppTheme.accentEmerald.withOpacity(0.15)
            : AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.accentEmerald,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isLive ? AppTheme.accentEmerald : AppTheme.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamBadge(String name, Color accent) {
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: accent,
          ),
        ),
      ),
    );
  }
}