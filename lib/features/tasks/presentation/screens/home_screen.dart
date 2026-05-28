import 'dart:async';

import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_layout.dart';
import 'package:carpe_diem/features/common/data/models/task_filter.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/edit_task_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/filter_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/common/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/screen_header.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/add_task_dialog.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/home_day_selector.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/home_planner_pane.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late DateTime _selectedDate;
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

      if (_normalizedSelected == yesterday) {
        setState(() => _selectedDate = now);
        ref.read(taskProvider.notifier).loadTasksForDate(_selectedDate);
      }
    });
    _selectedDate = _today;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskProvider.notifier).loadTasksForDate(_selectedDate);
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
  DateTime get _normalizedSelected => DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

  bool get _isToday {
    final now = _today;
    return _normalizedSelected == DateTime(now.year, now.month, now.day);
  }

  List<DateTime> get _days {
    final settings = ref.read(settingsProvider);
    final today = DateTime(_today.year, _today.month, _today.day);
    return List.generate(settings.maxPlanningDays + 1, (i) => today.add(Duration(days: i)));
  }

  void _moveFocus(int delta) {
    if (_orderedItemIds.isEmpty) return;

    int currentIndex = -1;
    for (int i = 0; i < _orderedItemIds.length; i++) {
      final node = _itemFocusNodes[_orderedItemIds[i]];
      if (node?.hasFocus ?? false) {
        currentIndex = i;
        break;
      }
    }

    if (currentIndex == -1) {
      final targetIndex = delta > 0 ? 0 : _orderedItemIds.length - 1;
      final id = _orderedItemIds[targetIndex];
      final node = _itemFocusNodes.putIfAbsent(id, () => FocusNode(debugLabel: 'HomeTask_$id'));
      node.requestFocus();
    } else {
      final nextIndex = (currentIndex + delta).clamp(0, _orderedItemIds.length - 1);
      final id = _orderedItemIds[nextIndex];
      final node = _itemFocusNodes.putIfAbsent(id, () => FocusNode(debugLabel: 'HomeTask_$id'));
      node.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(taskProvider);
    final filterState = ref.watch(filterProvider);
    final settings = ref.watch(settingsProvider);

    return AppShortcutRegistrar(
      shortcuts: homeShortcutEntries,
      child: Shortcuts(
        shortcuts: {
          const CharacterActivator('h'): const PrevDayIntent(),
          const CharacterActivator('l'): const NextDayIntent(),
          const CharacterActivator('a'): const NewTaskIntent(),
          const CharacterActivator('v'): const ToggleLayoutIntent(),
          const CharacterActivator('f'): const FilterIntent(),
          const CharacterActivator('H'): const PrevDayIntent(),
          const CharacterActivator('L'): const NextDayIntent(),
          const CharacterActivator('A'): const NewTaskIntent(),
          const CharacterActivator('V'): const ToggleLayoutIntent(),
          const CharacterActivator('j'): const MoveNextIntent(),
          const CharacterActivator('k'): const MovePrevIntent(),
        },
        child: Actions(
          actions: {
            PrevDayIntent: NonTypingAction<PrevDayIntent>((_) {
              _changeDay(-1);
            }),
            NextDayIntent: NonTypingAction<NextDayIntent>((_) {
              _changeDay(1);
            }),
            NewTaskIntent: NonTypingAction<NewTaskIntent>((_) {
              _showAddTask(context);
            }),
            ToggleLayoutIntent: NonTypingAction<ToggleLayoutIntent>((_) {
              final currentLayout = settings.getTaskLayout();
              final nextLayout = currentLayout == TaskLayout.list ? TaskLayout.kanban : TaskLayout.list;
              ref.read(settingsProvider.notifier).setTaskLayout(nextLayout);
            }),
            FilterIntent: NonTypingAction<FilterIntent>((_) {
              _showFilterDialog(context);
            }),
            MoveNextIntent: NonTypingAction<MoveNextIntent>((_) {
              _moveFocus(1);
            }),
            MovePrevIntent: NonTypingAction<MovePrevIntent>((_) {
              _moveFocus(-1);
            }),
            NavigateToTodayIntent: NonTypingAction<NavigateToTodayIntent>((_) {
              setState(() => _selectedDate = _today);
              ref.read(taskProvider.notifier).loadTasksForDate(_selectedDate);
            }),
          },
          child: Focus(
            autofocus: true,
            debugLabel: 'HomeScreenFocus',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScreenHeader(
                  title: _isToday ? 'Today' : _dateFormat.format(_selectedDate),
                  subtitle: _isToday
                      ? _dateFormat.format(_selectedDate)
                      : '${_normalizedSelected.difference(DateTime(_today.year, _today.month, _today.day)).inDays} days from now',
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
                HomeDaySelector(
                  days: _days,
                  selectedDate: _selectedDate,
                  onDateSelected: (day) {
                    setState(() => _selectedDate = day);
                    ref.read(taskProvider.notifier).loadTasksForDate(day);
                  },
                ),
                FilterBar(
                  filter: filterState.filter,
                  isBypassed: filterState.isBypassed,
                  onFilterTap: () => _showFilterDialog(context),
                  onClearFilter: () => ref.read(filterProvider.notifier).clearFilter(),
                ),
                const Divider(height: 1),
                Expanded(
                  child: HomePlannerPane(
                    selectedDate: _selectedDate,
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
        ),
      ),
    );
  }

  void _changeDay(int delta) {
    final days = _days;
    final currentIndex = days.indexWhere((d) => d == _normalizedSelected);
    final nextIndex = currentIndex + delta;
    if (nextIndex >= 0 && nextIndex < days.length) {
      setState(() => _selectedDate = days[nextIndex]);
      ref.read(taskProvider.notifier).loadTasksForDate(days[nextIndex]);
    }
  }

  void _showAddTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(initialDate: _selectedDate),
    );
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
