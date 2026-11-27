import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/history/data/models/history_overview.dart';
import 'package:carpe_diem/features/history/presentation/providers/activity_provider.dart';
import 'package:carpe_diem/features/history/presentation/providers/history_insights_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_history_provider.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryListState {
  final DateTimeRange dateRange;
  final DateTimeRange queryRange;
  final List<Task> completedTasks;
  final HistoryOverview? overview;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;

  const HistoryListState({
    required this.dateRange,
    required this.queryRange,
    required this.completedTasks,
    required this.overview,
    required this.hasMore,
    required this.isLoading,
    required this.isLoadingMore,
  });
}

class HistoryListNotifier extends Notifier<HistoryListState> {
  late DateTimeRange _dateRange;
  late DateTimeRange _queryRange;
  int _offset = 0;
  bool _hasMore = true;
  List<Task> _completedTasks = [];
  HistoryOverview? _overview;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  final int _limit = 25;

  @override
  HistoryListState build() {
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

    _buildQueryRange();
    return _currentState;
  }

  Future<void> load() async {
    ref
      ..invalidate(historyInsightsProvider)
      ..invalidate(activityProvider)
      ..invalidate(activityYearsProvider);
    _resetPaging();
    _isLoading = true;
    state = _currentState;
    final historyNotifier = ref.read(taskHistoryProvider.notifier);
    final filter = ref.read(filterProvider).activeFilter;

    final (tasks, overview) = await (
      historyNotifier.getCompletedTasks(
        _queryRange.start,
        _queryRange.end,
        limit: _limit,
        offset: _offset,
        filter: filter,
      ),
      historyNotifier.getHistoryOverview(
        _queryRange.start,
        _queryRange.end,
        filter: filter,
      ),
    ).wait;

    if (!ref.mounted) return;
    _completedTasks = tasks;
    _overview = overview;
    _isLoading = false;
    _offset = tasks.length;
    _hasMore = tasks.length == _limit;
    state = _currentState;
  }

  Future<void> loadMore() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;
    state = _currentState;
    final historyNotifier = ref.read(taskHistoryProvider.notifier);
    final filter = ref.read(filterProvider).activeFilter;

    final tasks = await historyNotifier.getCompletedTasks(
      _queryRange.start,
      _queryRange.end,
      limit: _limit,
      offset: _offset,
      filter: filter,
    );

    if (!ref.mounted) return;
    _completedTasks = [..._completedTasks, ...tasks];
    _isLoadingMore = false;
    _offset += tasks.length;
    _hasMore = tasks.length == _limit;
    state = _currentState;
  }

  void setDateRange(DateTimeRange dateRange) {
    _dateRange = dateRange;
    _buildQueryRange();
    _resetPaging();
    state = _currentState;
  }

  HistoryListState get _currentState => HistoryListState(
    dateRange: _dateRange,
    queryRange: _queryRange,
    completedTasks: _completedTasks,
    overview: _overview,
    hasMore: _hasMore,
    isLoading: _isLoading,
    isLoadingMore: _isLoadingMore,
  );

  void _buildQueryRange() {
    _queryRange = DateTimeRange(
      start: DateTime(
        _dateRange.start.year,
        _dateRange.start.month,
        _dateRange.start.day,
      ),
      end: DateTime(
        _dateRange.end.year,
        _dateRange.end.month,
        _dateRange.end.day,
        23,
        59,
        59,
      ),
    );
  }

  void _resetPaging() {
    _offset = 0;
    _hasMore = true;
    _completedTasks = [];
    _isLoadingMore = false;
  }
}

final historyListProvider =
    NotifierProvider<HistoryListNotifier, HistoryListState>(
      HistoryListNotifier.new,
    );
