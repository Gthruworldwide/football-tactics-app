import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/services/sports_media_service.dart';
import '../../core/services/weather_service.dart';
import '../../core/theme/app_theme.dart';

class TacticalMatchCard extends StatelessWidget {
  final String leagueName;
  final String homeTeam;
  final String awayTeam;
  final String venueName;
  final String venueCity;
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
    this.venueName = '',
    this.venueCity = '',
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
        padding: const EdgeInsets.all(14),
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
            // Top Row: League & Status
            Row(
              children: [
                if (isTracked) ...[
                  const Icon(Icons.star_rounded,
                      size: 14, color: AppTheme.accentCyan),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    leagueName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusPill(),
              ],
            ),
            const SizedBox(height: 14),

            // Middle Row: Teams & Score
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildTeamBadge(homeTeam, AppTheme.accentEmerald),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          homeTeam,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 64),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      homeScore != null && awayScore != null
                          ? '$homeScore - $awayScore'
                          : 'VS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isLive
                            ? AppTheme.accentEmerald
                            : AppTheme.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
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
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTeamBadge(awayTeam, AppTheme.accentCyan),
                    ],
                  ),
                ),
              ],
            ),

            // Telemetry Bar
            if (homeScore != null) ...[
              const SizedBox(height: 12),
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

            // Stadium & Live Weather Strip
            if (venueCity.isNotEmpty || venueName.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FutureBuilder<StadiumWeather?>(
                  future: WeatherService.getVenueWeather(venueCity, venueName: venueName),
                  builder: (context, snapshot) {
                    final w = snapshot.data;
                    return Row(
                      children: [
                        const Icon(Icons.stadium_outlined,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            venueName.isNotEmpty
                                ? '$venueName ($venueCity)'
                                : venueCity,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        if (w != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            _weatherIcon(w.condition),
                            size: 14,
                            color: AppTheme.accentCyan,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${w.tempC.round()}°C • ${w.condition}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accentCyan,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _weatherIcon(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('rain') || c.contains('drizzle')) {
      return Icons.water_drop_rounded;
    }
    if (c.contains('cloud')) return Icons.cloud_outlined;
    if (c.contains('wind')) return Icons.air_rounded;
    return Icons.wb_sunny_outlined;
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
    return FutureBuilder<String?>(
      future: SportsMediaService.getTeamBadge(name),
      builder: (context, snapshot) {
        final badgeUrl = snapshot.data;
        return Container(
          width: 30,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withOpacity(0.35)),
          ),
          child: badgeUrl != null && badgeUrl.isNotEmpty
              ? Image.network(
                  badgeUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                ),
        );
      },
    );
  }
}
