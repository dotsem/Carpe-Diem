import 'package:carpe_diem/core/utils/color_utils.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/backlog_label_tab_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BacklogLabelTabBar extends ConsumerStatefulWidget {
  const BacklogLabelTabBar({super.key});

  @override
  ConsumerState<BacklogLabelTabBar> createState() => _BacklogLabelTabBarState();
}

class _BacklogLabelTabBarState extends ConsumerState<BacklogLabelTabBar>
    with TickerProviderStateMixin {
  TabController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _syncController(int length, int index) {
    if (_controller == null || _controller!.length != length) {
      _controller?.dispose();
      _controller = TabController(
        length: length,
        vsync: this,
        initialIndex: index.clamp(0, length - 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allLabels = ref.watch(labelProvider).labels;
    final state = ref.watch(backlogLabelTabProvider);
    final notifier = ref.read(backlogLabelTabProvider.notifier);
    final filterState = ref.watch(filterProvider);
    final filter = filterState.filter;
    final isBypassed = filterState.isBypassed;

    final labels = isBypassed
        ? allLabels
        : allLabels.where((label) {
            if (filter.labelIdsExcluded.contains(label.id)) return false;
            if (filter.labelIdsIncluded.isNotEmpty &&
                !filter.labelIdsIncluded.contains(label.id)) {
              return false;
            }
            return true;
          }).toList();

    if (allLabels.isEmpty) return const SizedBox.shrink();

    final currentIndex = state.getIndex(labels);
    _syncController(labels.length + 2, currentIndex);

    ref.listen(backlogLabelTabProvider, (prev, next) {
      final newIndex = next.getIndex(labels);
      if (_controller != null &&
          _controller!.index != newIndex &&
          newIndex < _controller!.length) {
        _controller!.animateTo(newIndex);
      }
    });

    final taskState = ref.watch(taskProvider);
    final projectState = ref.watch(projectProvider);
    final tasks = taskState.unscheduledTasks;

    final labelCounts = <String, int>{};
    int inboxCount = 0;
    for (final t in tasks) {
      final project = t.projectId != null
          ? projectState.getById(t.projectId!)
          : null;
      final combined = {...t.labelIds, ...?project?.labelIds};
      if (combined.isEmpty) {
        inboxCount++;
      } else {
        for (final id in combined) {
          labelCounts[id] = (labelCounts[id] ?? 0) + 1;
        }
      }
    }

    return TabBar(
      controller: _controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: _buildTabs(context, labels, tasks.length, inboxCount, labelCounts),
      onTap: (index) {
        if (index == 0) {
          notifier.selectAll();
        } else if (index == labels.length + 1) {
          notifier.selectInbox();
        } else {
          notifier.selectLabel(labels[index - 1].id);
        }
      },
    );
  }

  List<Widget> _buildTabs(
    BuildContext context,
    List<Label> labels,
    int allCount,
    int inboxCount,
    Map<String, int> labelCounts,
  ) {
    return [
      Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6.0,
          children: [
            const Icon(Icons.all_inbox_rounded, size: 16),
            const Text('All'),
            _TabCountBadge(count: allCount),
          ],
        ),
      ),
      for (final label in labels)
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6.0,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: label.color.themeDependentColor(context),
                  shape: BoxShape.circle,
                ),
              ),
              Text(label.name),
              _TabCountBadge(
                count: labelCounts[label.id] ?? 0,
                accentColor: label.color.themeDependentColor(context),
              ),
            ],
          ),
        ),
      Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6.0,
          children: [
            const Icon(Icons.inbox_rounded, size: 16),
            const Text('Inbox'),
            _TabCountBadge(count: inboxCount),
          ],
        ),
      ),
    ];
  }
}

class _TabCountBadge extends StatelessWidget {
  final int count;
  final Color? accentColor;

  const _TabCountBadge({required this.count, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = accentColor != null
        ? accentColor!.withAlpha(30)
        : theme.colorScheme.surfaceContainerHighest;
    final fg = accentColor ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
