import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/screen_header.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/filter_bar.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/filter_dialog.dart';
import 'package:carpe_diem/features/history/data/models/history_overview.dart';
import 'package:carpe_diem/features/history/presentation/providers/activity_provider.dart';
import 'package:carpe_diem/features/history/presentation/providers/history_insights_provider.dart';
import 'package:carpe_diem/features/history/presentation/screens/tab_history_dashboard.dart';
import 'package:carpe_diem/features/history/presentation/screens/tab_history_insights.dart';
import 'package:carpe_diem/features/history/presentation/screens/tab_history_list.dart';
import 'package:carpe_diem/features/history/presentation/screens/widgets/date_range_button.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_history_provider.dart';
import 'package:carpe_diem/flutter_ext/horizontal_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      case 'monthly':
        _dateRange = DateTimeRange(
          start: DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 30)),
          end: now,
        );
      case 'weekly':
      default:
        _dateRange = DateTimeRange(
          start: DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 6)),
          end: now,
        );
    }

    _loadData();
  }

  Future<void> _loadData() async {
    // why: ref.invalidate listens to the scope, which throws when called from initState
    ProviderScope.containerOf(context, listen: false)
      ..invalidate(historyInsightsProvider)
      ..invalidate(activityProvider)
      ..invalidate(activityYearsProvider);
    setState(() {
      _isLoading = true;
      _offset = 0;
      _hasMore = true;
      _completedTasks = [];
    });
    final historyNotifier = ref.read(taskHistoryProvider.notifier);

    final start = DateTime(
      _dateRange.start.year,
      _dateRange.start.month,
      _dateRange.start.day,
    );
    final end = DateTime(
      _dateRange.end.year,
      _dateRange.end.month,
      _dateRange.end.day,
      23,
      59,
      59,
    );
    if (!mounted) return;
    final filter = ref.read(filterProvider).activeFilter;

    final tasksFuture = historyNotifier.getCompletedTasks(
      start,
      end,
      limit: _limit,
      offset: _offset,
      filter: filter,
    );
    final overviewFuture = historyNotifier.getHistoryOverview(
      start,
      end,
      filter: filter,
    );

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
    final historyNotifier = ref.read(taskHistoryProvider.notifier);

    final start = DateTime(
      _dateRange.start.year,
      _dateRange.start.month,
      _dateRange.start.day,
    );
    final end = DateTime(
      _dateRange.end.year,
      _dateRange.end.month,
      _dateRange.end.day,
      23,
      59,
      59,
    );
    final filter = ref.read(filterProvider).activeFilter;

    final tasks = await historyNotifier.getCompletedTasks(
      start,
      end,
      limit: _limit,
      offset: _offset,
      filter: filter,
    );

    if (mounted) {
      setState(() {
        _completedTasks.addAll(tasks);
        _isLoadingMore = false;
        _offset += tasks.length;
        _hasMore = tasks.length == _limit;
      });
    }
  }

  Future<void> _showFilterDialog() async {
    final filterProviderVal = ref.read(filterProvider);
    final result = await showDialog<TaskFilter>(
      context: context,
      builder: (context) =>
          FilterDialog(initialFilter: filterProviderVal.filter),
    );

    if (result != null) {
      ref.read(filterProvider.notifier).setFilter(result);
      await _loadData();
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
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: 'History',
              actions: [
                DateRangeButton(
                  dateRange: _dateRange,
                  onDatePicked: (picked) {
                    setState(() => _dateRange = picked);
                    _loadData();
                  },
                ),
              ],
            ),
            FilterBar(
              filter: filterState.filter,
              isBypassed: filterState.isBypassed,
              onFilterTap: _showFilterDialog,
              onClearFilter: _clearFilter,
            ),

            TabBar(
              tabs: const [
                HorizontalTab(
                  icon: Icon(Icons.dashboard, size: 16),
                  label: 'Dashboard',
                ),
                HorizontalTab(
                  icon: Icon(Icons.history, size: 16),
                  label: 'History',
                ),
                HorizontalTab(
                  icon: Icon(Icons.insights, size: 16),
                  label: 'Insights',
                ),
              ],
              indicatorColor: AppColors.accent,
              labelColor: Theme.of(context).colorScheme.onSurface,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        TabHistoryDashboard(
                          overview: _overview,
                          range: _dateRange,
                        ),
                        TabHistoryList(
                          tasks: _completedTasks,
                          hasMore: _hasMore,
                          isLoadingMore: _isLoadingMore,
                          onLoadMore: _loadMoreData,
                        ),
                        TabHistoryInsights(range: _dateRange),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
