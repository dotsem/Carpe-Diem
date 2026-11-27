import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/screen_header.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/dialogs/filter_dialog.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/filter_bar.dart';
import 'package:carpe_diem/features/history/presentation/providers/history_list_provider.dart';
import 'package:carpe_diem/features/history/presentation/widgets/date_range_button.dart';
import 'package:carpe_diem/features/history/presentation/widgets/tabs/history_dashboard_tab.dart';
import 'package:carpe_diem/features/history/presentation/widgets/tabs/history_insights_tab.dart';
import 'package:carpe_diem/features/history/presentation/widgets/tabs/history_list_tab.dart';
import 'package:dotmaterial/dotmaterial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() => ref.read(historyListProvider.notifier).load();

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
              child: historyList.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        HistoryDashboardTab(
                          overview: historyList.overview,
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
