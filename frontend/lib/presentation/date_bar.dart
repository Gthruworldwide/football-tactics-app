import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Horizontal date picker bar with auto-scroll to today (SofaScore-inspired)
class DateBar extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final DateTime selectedDate;
  final List<DateTime> dateRange;

  const DateBar({
    required this.onDateSelected,
    required this.selectedDate,
    required this.dateRange,
    super.key,
  });

  @override
  State<DateBar> createState() => _DateBarState();
}

class _DateBarState extends State<DateBar> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  bool _isAnimatingToToday = false;
  ThemeData? _theme;
  bool _hasAutoScrolled = false;

  @override
  void initState() {
    super.initState();
    // DO NOT call Theme.of(context) or MediaQuery.of(context) here
    _tabController = TabController(length: widget.dateRange.length, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe to access inherited widgets here
    _theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    // Auto-scroll to current day on first build
    if (!_hasAutoScrolled) {
      _hasAutoScrolled = true;
      _scrollToToday();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Auto-scroll to today's date
  void _scrollToToday() {
    final todayIndex = _findTodayIndex();
    if (todayIndex >= 0 && todayIndex != _tabController.index) {
      setState(() {
        _isAnimatingToToday = true;
      });
      _animationController.forward().then((_) {
        _tabController.animateTo(todayIndex);
        _animationController.reset();
        _isAnimatingToToday = false;
      });
    } else {
      _tabController.animateTo(todayIndex.clamp(0, _tabController.length - 1));
    }
  }

  int _findTodayIndex() {
    final selectedStr = _formatDate(widget.selectedDate);
    for (int i = 0; i < widget.dateRange.length; i++) {
      if (_formatDate(widget.dateRange[i]) == selectedStr) return i;
    }
    return 0;
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    _theme = _theme ?? Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: _theme?.colorScheme.primaryContainer ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left arrow button
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              size: 16,
              color: _theme?.colorScheme.onPrimaryContainer ?? Colors.white,
            ),
            onPressed: () {
              final newIndex = _tabController.index - 1;
              if (newIndex >= 0) {
                _tabController.animateTo(newIndex);
              }
            },
          ),
          // Date tabs
          Expanded(
            child: TabBar(
              controller: _tabController,
              labelColor: _theme?.colorScheme.onPrimaryContainer ?? Colors.white,
              unselectedLabelColor:
                  _theme?.colorScheme.onPrimaryContainer?.withOpacity(0.6) ?? Colors.white,
              indicator: BoxDecoration(
                color: _theme?.colorScheme.primary ?? Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              tabs: widget.dateRange.map((date) => _buildDateTab(date)).toList(),
            ),
          ),
          // Right arrow button
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: _theme?.colorScheme.onPrimaryContainer ?? Colors.white,
            ),
            onPressed: () {
              final newIndex = _tabController.index + 1;
              if (newIndex < _tabController.length) {
                _tabController.animateTo(newIndex);
              }
            },
          ),
          const SizedBox(width: 8),
          // Today button
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _isAnimatingToToday ? 0.5 : 0,
                child: IconButton(
                  icon: _isAnimatingToToday
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.today,
                          size: 16,
                          color: Colors.white,
                        ),
                  onPressed: () => _scrollToToday(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateTab(DateTime date) {
    final isSelected = _formatDate(date) == _formatDate(widget.selectedDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      constraints: const BoxConstraints(
        minWidth: 60,
        maxWidth: 80,
      ),
      decoration: BoxDecoration(
        color: isSelected ? _theme?.colorScheme.primary ?? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? _theme?.colorScheme.primary ?? Colors.blue : _theme?.colorScheme.outline ?? Colors.grey,
        ),
      ),
      child: Text(
        DateFormat('EEE d MMM').format(date),
        style: _theme?.textTheme.bodySmall?.copyWith(
          color: isSelected ? Colors.white : _theme?.colorScheme.onPrimaryContainer?.withOpacity(0.8),
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}