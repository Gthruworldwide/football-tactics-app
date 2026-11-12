import 'package:flutter/material.dart';
import '../logic/tactical_bloc.dart';

/// Modal bottom sheet for displaying tactical analytics (xG, PPDA, field tilt)
class TacticalBottomSheet extends StatelessWidget {
  final String matchId;
  final TacticalState? tacticalState;

  const TacticalBottomSheet({
    required this.matchId,
    required this.tacticalState,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              width: 28,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Match title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Tactical Analysis',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Conditional content based on state
          Expanded(
            child: tacticalState != null
                ? _buildTacticalContent(tacticalState!, context)
                : _buildLoadingState(),
          ),

          // Close button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalContent(TacticalState state, BuildContext context) {
    if (state is TacticalInitial) {
      return _buildEmptyState(context);
    }

    if (state is TacticalLoading) {
      return _buildLoadingState();
    }

    if (state is TacticalLoaded) {
      return _buildTacticalMetrics(state.tacticalCache!, context);
    }

    if (state is TacticalError) {
      return _buildErrorState(state.error, context);
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No tactical data available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(String error, BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: 12),
            Text(
              'Error loading tactical data',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.red[300],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red[300],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTacticalMetrics(TacticalCache cache, BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with match info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Match: ${cache.matchId}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // Live indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),

          // xG Section
          _buildMetricRow(
            context: context,
            icon: Icons.trending_up,
            title: 'Expected Goals (xG)',
            value: '${cache.homeXG.toStringAsFixed(2)} - ${cache.awayXG.toStringAsFixed(2)}',
            subtitle: 'Home vs Away',
          ),

          const SizedBox(height: 12),

          // PPDA Section
          _buildMetricRow(
            context: context,
            icon: Icons.speed,
            title: 'PPDA (Passing Pressing Defense Actions)',
            value: 'Home: ${cache.homePPDA} - Away: ${cache.awayPPDA}',
            subtitle: 'Lower is better (more efficient defense)',
          ),

          const SizedBox(height: 12),

          // Field Tilt Section
          _buildMetricRow(
            context: context,
            icon: Icons.map,
            title: 'Field Tilt',
            value: 'Home: ${cache.homeFieldTilt} - Away: ${cache.awayFieldTilt}',
            subtitle: 'Territorial advantage',
          ),

          const SizedBox(height: 12),

          // Momentum Section
          _buildMetricRow(
            context: context,
            icon: Icons.trending_up,
            title: 'Momentum',
            value: cache.momentum,
            subtitle: 'Match flow indicator',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}