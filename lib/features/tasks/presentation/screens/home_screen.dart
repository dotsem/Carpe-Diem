import 'dart:async';

import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_layout.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/edit_task_dialog.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/filter_dialog.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/selected_date_provider.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/screen_header.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/add_task_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/home_day_selector.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/home_planner_pane.dart';
import 'package:carpe_diem/core/utils/focus_utils.dart';
import 'package:carpe_diem/features/tasks/presentation/shortcuts/home_shortcuts.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Timer timer;
  final _dateFormat = DateFormat('EEEE, MMMM d');
  final List<String> _orderedItemIds = [];
  final Map<String, FocusNode> _itemFocusNodes = {};

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!mounted) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      final selectedDate = ref.read(selectedDateProvider);
      if (selectedDate.normalize == yesterday) {
        ref.read(selectedDateProvider.notifier).state = now;
        ref.read(taskProvider.notifier).loadTasksForDate(now);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskProvider.notifier).loadTasksForDate(ref.read(selectedDateProvider));
    });
  }

  @override
  void dispose() {
    timer.cancel();
    for (final node in _itemFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  DateTime get _today => DateTime.now();

  List<DateTime> get _days {
    final settings = ref.read(settingsProvider);
    final today = DateTime(_today.year, _today.month, _today.day);
    return List.generate(settings.maxPlanningDays + 1, (i) => today.add(Duration(days: i)));
  }

  void _moveFocus(int delta) => FocusUtils.moveFocus(
    orderedItemIds: _orderedItemIds,
    itemFocusNodes: _itemFocusNodes,
    delta: delta,
    debugLabelPrefix: 'HomeTask',
  );

  @override
  Widget build(BuildContext context) {
    ref.watch(taskProvider);
    final filterState = ref.watch(filterProvider);
    final settings = ref.watch(settingsProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final isToday = selectedDate.isToday;
    final daysFromToday = selectedDate.daysFromToday;

    return HomeShortcuts(
      onPrevDay: () => _changeDay(-1),
      onNextDay: () => _changeDay(1),
      onNewTask: () => _showAddTask(context),
      onToggleLayout: () {
        final currentLayout = settings.getTaskLayout();
        final nextLayout = currentLayout == TaskLayout.list ? TaskLayout.kanban : TaskLayout.list;
        ref.read(settingsProvider.notifier).setTaskLayout(nextLayout);
      },
      onShowFilter: () => _showFilterDialog(context),
      onMoveNext: () => _moveFocus(1),
      onMovePrev: () => _moveFocus(-1),
      onNavigateToToday: () {
        ref.read(selectedDateProvider.notifier).state = _today;
        ref.read(taskProvider.notifier).loadTasksForDate(_today);
      },
      child: Focus(
        autofocus: true,
        debugLabel: 'HomeScreenFocus',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: isToday ? 'Today' : _dateFormat.format(selectedDate),
              subtitle: isToday
                  ? _dateFormat.format(selectedDate)
                  : switch (daysFromToday) {
                      1 => '1 day from now',
                      int d => '$d days from now',
                    },
              actions: [
                IconButton(
                  onPressed: () {
                    final currentLayout = settings.getTaskLayout();
                    final nextLayout = currentLayout == TaskLayout.list ? TaskLayout.kanban : TaskLayout.list;
                    ref.read(settingsProvider.notifier).setTaskLayout(nextLayout);
                  },
                  icon: Icon(settings.getTaskLayout() == TaskLayout.list ? Icons.view_kanban : Icons.view_list),
                  tooltip: settings.getTaskLayout() == TaskLayout.list ? 'Kanban view' : 'List view',
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _showAddTask(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Task'),
                ),
              ],
            ),
            const HomeDaySelector(),
            FilterBar(
              filter: filterState.filter,
              isBypassed: filterState.isBypassed,
              onFilterTap: () => _showFilterDialog(context),
              onClearFilter: () => ref.read(filterProvider.notifier).clearFilter(),
            ),
            const Divider(height: 1),
            Expanded(
              child: HomePlannerPane(
                itemFocusNodes: _itemFocusNodes,
                onOrderedIdsChanged: (ids) {
                  _orderedItemIds.clear();
                  _orderedItemIds.addAll(ids);
                },
                onEdit: (task) => _showEditTask(context, task),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeDay(int delta) {
    final days = _days;
    final selectedDate = ref.read(selectedDateProvider);
    final currentIndex = days.indexWhere((d) => d == selectedDate.normalize);
    final nextIndex = currentIndex + delta;
    if (nextIndex >= 0 && nextIndex < days.length) {
      final nextDay = days[nextIndex];
      ref.read(selectedDateProvider.notifier).state = nextDay;
      ref.read(taskProvider.notifier).loadTasksForDate(nextDay);
    }
  }

  void _showAddTask(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddTaskDialog());
  }

  void _showEditTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (_) => EditTaskDialog(task: task),
    );
  }

  void _showFilterDialog(BuildContext context) async {
    final filterProviderVal = ref.read(filterProvider);
    final result = await showDialog<TaskFilter>(
      context: context,
      builder: (_) => FilterDialog(initialFilter: filterProviderVal.filter),
    );
    if (result != null) {
      ref.read(filterProvider.notifier).setFilter(result);
    }
  }
}
