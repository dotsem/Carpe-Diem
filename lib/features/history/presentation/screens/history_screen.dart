import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/screen_header.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/dialogs/filter_dialog.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/filter_bar.dart';
import 'package:carpe_diem/features/history/data/models/history_overview.dart';
import 'package:carpe_diem/features/history/presentation/providers/activity_provider.dart';
import 'package:carpe_diem/features/history/presentation/providers/history_insights_provider.dart';
import 'package:carpe_diem/features/history/presentation/providers/history_list_provider.dart';
import 'package:carpe_diem/features/history/presentation/widgets/date_range_button.dart';
import 'package:carpe_diem/features/history/presentation/widgets/tabs/history_dashboard_tab.dart';
import 'package:carpe_diem/features/history/presentation/widgets/tabs/history_insights_tab.dart';
import 'package:carpe_diem/features/history/presentation/widgets/tabs/history_list_tab.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_history_provider.dart';
import 'package:dotmaterial/dotmaterial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _isLoading = false;
  HistoryOverview? _overview;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // why: ref.invalidate listens to the scope, which throws when called from initState
    ProviderScope.containerOf(context, listen: false)
      ..invalidate(historyInsightsProvider)
      ..invalidate(activityProvider)
      ..invalidate(activityYearsProvider);
    setState(() => _isLoading = true);
    final historyNotifier = ref.read(taskHistoryProvider.notifier);
    final historyListNotifier = ref.read(historyListProvider.notifier);
    final queryRange = ref.read(historyListProvider).queryRange;
    if (!mounted) return;
    final filter = ref.read(filterProvider).activeFilter;

    final overviewFuture = historyNotifier.getHistoryOverview(
      queryRange.start,
      queryRange.end,
      filter: filter,
    );
    await historyListNotifier.load();
    final overview = await overviewFuture;

    if (mounted) {
      setState(() {
        _overview = overview;
        _isLoading = false;
      });
    }
  }

  Future<void> _showFilterDialog() async {
    if (await showFilterDialog(context, ref)) await _loadData();
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
    final historyList = ref.watch(historyListProvider);

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
                  dateRange: historyList.dateRange,
                  onDatePicked: (picked) {
                    ref.read(historyListProvider.notifier).setDateRange(picked);
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
                        HistoryDashboardTab(
                          overview: _overview,
                          range: historyList.dateRange,
                        ),
                        HistoryListTab(
                          tasks: historyList.completedTasks,
                          hasMore: historyList.hasMore,
                          isLoadingMore: historyList.isLoadingMore,
                          onLoadMore: () =>
                              ref.read(historyListProvider.notifier).loadMore(),
                        ),
                        HistoryInsightsTab(range: historyList.dateRange),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
