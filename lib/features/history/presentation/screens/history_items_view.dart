import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryItemsView extends ConsumerStatefulWidget {
  final List<Task> tasks;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final bool isLoadingMore;

  const HistoryItemsView({
    super.key,
    required this.tasks,
    required this.hasMore,
    required this.onLoadMore,
    required this.isLoadingMore,
  });

  @override
  ConsumerState<HistoryItemsView> createState() => _HistoryItemsViewState();
}

class _HistoryItemsViewState extends ConsumerState<HistoryItemsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasMore && !widget.isLoadingMore) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty && !widget.isLoadingMore) {
      return _buildEmptyState();
    }

    final projectState = ref.read(projectProvider);

    // Group tasks by completion date
    final groupedTasks = <String, List<Task>>{};
    for (final task in widget.tasks) {
      if (task.completedAt == null) continue;
      final dateKey = DateFormat('yyyy-MM-dd').format(task.completedAt!);
      groupedTasks.putIfAbsent(dateKey, () => []).add(task);
    }

    final sortedKeys = groupedTasks.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedKeys.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == sortedKeys.length) {
          return const Center(
            child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final dateKey = sortedKeys[index];
        final dayTasks = groupedTasks[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Text(
                _formatDateHeader(date),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ),
            ...dayTasks.map((task) {
              final project = task.projectId != null ? projectState.getById(task.projectId!) : null;
              return TaskCard(
                task: task,
                project: project,
                onToggle: (_) {}, // Read-only for history
                onTap: () {},
                leading: const SizedBox.shrink(),
                showStrikeThroughOnCompleted: false,
              );
            }),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.isAtSameMomentAs(today)) return 'TODAY';
    if (date.isAtSameMomentAs(yesterday)) return 'YESTERDAY';

    return DateFormat('EEEE, MMM d').format(date).toUpperCase();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(
            'No completed tasks found',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different date range or clearing filters',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
