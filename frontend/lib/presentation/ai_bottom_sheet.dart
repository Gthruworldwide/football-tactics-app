import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/tactical_bloc.dart';

/// Modal bottom sheet for displaying AI tactical summary
class AIBottomSheet extends StatefulWidget {
  final String matchId;

  const AIBottomSheet({
    required this.matchId,
    super.key,
  });

  @override
  State<AIBottomSheet> createState() => _AIBottomSheetState();
}

class _AIBottomSheetState extends State<AIBottomSheet>
    with SingleTickerProviderStateMixin {
  late TacticalBloc _tacticalBloc;
  late TextEditingController _promptController;
  bool _isGenerating = false;
  String _aiSummary = '';

  @override
  void initState() {
    super.initState();
    _tacticalBloc = context.read<TacticalBloc>();
    _promptController = TextEditingController();
    _loadTacticalData();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _loadTacticalData() {
    _tacticalBloc.refreshTacticalData(matchId: widget.matchId);
  }

  void _generateSummary() {
    setState(() {
      _isGenerating = true;
      _aiSummary = '';
    });

    // Trigger AI summary generation via event
    _tacticalBloc.add(GenerateAISummary(matchId: widget.matchId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tacticalBloc = context.watch<TacticalBloc>();

    return Scaffold(
      body: Column(
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'AI Tactical Summary',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Summary content
          Expanded(
            child: _isGenerating
                ? _buildGeneratingState()
                : tacticalBloc.aiSummary.isNotEmpty
                    ? _buildSummaryContent(tacticalBloc.aiSummary)
                    : _buildPromptArea(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(theme, tacticalBloc),
    );
  }

  Widget _buildGeneratingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildSummaryContent(String summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        summary,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.5,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildPromptArea() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate AI summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            decoration: InputDecoration(
              hintText: 'Enter your analysis request...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isGenerating ? null : _generateSummary,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: _isGenerating
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : const Text('Generate Summary'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Theme theme, TacticalBloc tacticalBloc) {
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                side: BorderSide(color: theme.colorScheme.outline),
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: _isGenerating ? null : () {
                // Generate summary
                _generateSummary();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isGenerating
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Generate'),
            ),
          ),
        ],
      ),
    );
  }
}