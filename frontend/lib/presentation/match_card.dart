import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/matches_bloc.dart';
import '../logic/tactical_bloc.dart';
import 'tactical_bottom_sheet.dart';

/// High-density, rounded mobile match card (SofaScore-inspired)
class MatchCard extends StatefulWidget {
  final MatchCache match;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isLive;

  const MatchCard({
    required this.match,
    this.onTap,
    this.isSelected = false,
    this.isLive = false,
    super.key,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(_controller);
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    if (widget.isLive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLive = widget.isLive;

    return InkWell(
      onTap: () {
        widget.onTap?.call();
        _controller.forward(from: 0.0);
        _showTacticalSheet(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Main card content
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Home team section
                        Expanded(
                          child: Column(
                            children: [
                              // Team logo
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    widget.match.homeTeam[0].toUpperCase(),
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Team name
                              Text(
                                widget.match.homeTeam,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        
                        // Central score/time
                        Column(
                          children: [
                            // Live indicator
                            if (isLive)
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(
                                        _pulseController.value * 0.5 + 0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(
                                            _pulseController.value * 0.3,
                                          ),
                                          blurRadius: 6,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 4),
                            // Score
                            Text(
                              '${widget.match.homeGoals ?? 0} - ${widget.match.awayGoals ?? 0}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Time
                            Text(
                              '${widget.match.minute}\'',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        
                        // Away team section
                        Expanded(
                          child: Column(
                            children: [
                              // Team logo
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    widget.match.awayTeam[0].toUpperCase(),
                                    style: TextStyle(
                                      color: theme.colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Team name
                              Text(
                                widget.match.awayTeam,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bottom micro-bar for broadcast/commentator info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Channel tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.match.channel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Commentator
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.match.commentator,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTacticalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return TacticalBottomSheet(
            matchId: widget.match.matchId,
            tacticalState: null,
          );
        },
      ),
    );
  }

  String _getCountryInitials(String country) {
    if (country.isEmpty) return '?';
    final parts = country.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return country[0].toUpperCase();
  }
}