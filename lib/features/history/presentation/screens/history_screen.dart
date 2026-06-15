import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/history/data/models/history_overview.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/filter_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/pick_date_range_dialog.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/filter_bar.dart';
import 'package:carpe_diem/features/common/presentation/widgets/screen_header.dart';
import 'package:carpe_diem/features/history/presentation/screens/history_items_view.dart';
import 'package:carpe_diem/features/history/presentation/screens/history_overview_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:carpe_diem/features/tasks/data/models/task.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<Task> _completedTasks = [];
  HistoryOverview? _overview;
  DateTime? _minDate;
  int _offset = 0;
  bool _hasMore = true;
  final int _limit = 25;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    final now = DateTime.now();

    switch (settings.defaultStatsPeriod) {
      case 'daily':
        _dateRange = DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day),
        );
        break;
      case 'monthly':
        _dateRange = DateTimeRange(
          start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30)),
          end: now,
        );
        break;
      case 'weekly':
      default:
        _dateRange = DateTimeRange(
          start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)),
          end: now,
        );
        break;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _offset = 0;
      _hasMore = true;
      _completedTasks = [];
    });
    final taskNotifier = ref.read(taskProvider.notifier);

    _minDate ??= await taskNotifier.getFirstTaskDate();

    final start = DateTime(_dateRange.start.year, _dateRange.start.month, _dateRange.start.day);
    final end = DateTime(_dateRange.end.year, _dateRange.end.month, _dateRange.end.day, 23, 59, 59);
    if (!mounted) return;
    final filter = ref.read(filterProvider).activeFilter;

    final tasksFuture = taskNotifier.getCompletedTasks(start, end, limit: _limit, offset: _offset, filter: filter);
    final overviewFuture = taskNotifier.getHistoryOverview(start, end, filter: filter);

    final results = await Future.wait([tasksFuture, overviewFuture]);
    final tasks = results[0] as List<Task>;
    final overview = results[1] as HistoryOverview;

    if (mounted) {
      setState(() {
        _completedTasks = tasks;
        _overview = overview;
        _isLoading = false;
        _offset = tasks.length;
        _hasMore = tasks.length == _limit;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    final taskNotifier = ref.read(taskProvider.notifier);

    final start = DateTime(_dateRange.start.year, _dateRange.start.month, _dateRange.start.day);
    final end = DateTime(_dateRange.end.year, _dateRange.end.month, _dateRange.end.day, 23, 59, 59);
    final filter = ref.read(filterProvider).activeFilter;

    final tasks = await taskNotifier.getCompletedTasks(start, end, limit: _limit, offset: _offset, filter: filter);

    if (mounted) {
      setState(() {
        _completedTasks.addAll(tasks);
        _isLoadingMore = false;
        _offset += tasks.length;
        _hasMore = tasks.length == _limit;
      });
    }
  }

  void _selectDateRange() async {
    final now = DateTime.now();
    final initialDateRange = _dateRange;
    final firstDate = _minDate ?? now.subtract(const Duration(days: 365 * 10));

    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) =>
          PickDateRangeDialog(initialDateRange: initialDateRange, firstDate: firstDate, lastDate: now),
    );

    if (picked != null && picked != _dateRange) {
      setState(() => _dateRange = picked);
      _loadData();
    }
  }

  void _showFilterDialog() async {
    final filterProviderVal = ref.read(filterProvider);
    final result = await showDialog<TaskFilter>(
      context: context,
      builder: (context) => FilterDialog(initialFilter: filterProviderVal.filter),
    );

    if (result != null) {
      ref.read(filterProvider.notifier).setFilter(result);
      _loadData();
    }
  }

  void _clearFilter() {
    ref.read(filterProvider.notifier).clearFilter();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(filterProvider, (previous, next) {
      _loadData();
    });

    final filterState = ref.watch(filterProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: 'History', actions: [_buildDateRangeButton()]),
            FilterBar(
              filter: filterState.filter,
              isBypassed: filterState.isBypassed,
              onFilterTap: _showFilterDialog,
              onClearFilter: _clearFilter,
            ),

            TabBar(
              tabs: [
                Tab(text: 'Items'),
                Tab(text: 'Overview'),
              ],
              indicatorColor: AppColors.accent,
              labelColor: Theme.of(context).colorScheme.onSurface,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        HistoryItemsView(
                          tasks: _completedTasks,
                          hasMore: _hasMore,
                          isLoadingMore: _isLoadingMore,
                          onLoadMore: _loadMoreData,
                        ),
                        HistoryOverviewView(overview: _overview),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeButton() {
    final dateFormat = DateFormat('MMM d, yyyy');
    return InkWell(
      onTap: _selectDateRange,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHigh),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              '${dateFormat.format(_dateRange.start)} - ${dateFormat.format(_dateRange.end)}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
