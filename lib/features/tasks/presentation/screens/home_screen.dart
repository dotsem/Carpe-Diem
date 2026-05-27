import 'dart:async';

import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_layout.dart';
import 'package:carpe_diem/features/common/data/models/task_filter.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/edit_task_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/filter_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card_context_menu.dart';
import 'package:carpe_diem/features/common/presentation/widgets/filter_bar.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/kanban_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/common/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list_view.dart';
import 'package:carpe_diem/features/common/presentation/widgets/screen_header.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/add_task_dialog.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';

class _PrevDayIntent extends Intent {
  const _PrevDayIntent();
}

class _NextDayIntent extends Intent {
  const _NextDayIntent();
}

class _NewTaskIntent extends Intent {
  const _NewTaskIntent();
}

class _ToggleLayoutIntent extends Intent {
  const _ToggleLayoutIntent();
}

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
          const CharacterActivator('h'): _PrevDayIntent(),
          const CharacterActivator('l'): _NextDayIntent(),
          const CharacterActivator('a'): _NewTaskIntent(),
          const CharacterActivator('v'): _ToggleLayoutIntent(),
          const CharacterActivator('f'): FilterIntent(),
          const CharacterActivator('H'): _PrevDayIntent(),
          const CharacterActivator('L'): _NextDayIntent(),
          const CharacterActivator('A'): _NewTaskIntent(),
          const CharacterActivator('V'): _ToggleLayoutIntent(),
          const CharacterActivator('j'): MoveNextIntent(),
          const CharacterActivator('k'): MovePrevIntent(),
        },
        child: Actions(
          actions: {
            _PrevDayIntent: NonTypingAction<_PrevDayIntent>((_) {
              _changeDay(-1);
            }),
            _NextDayIntent: NonTypingAction<_NextDayIntent>((_) {
              _changeDay(1);
            }),
            _NewTaskIntent: NonTypingAction<_NewTaskIntent>((_) {
              _showAddTask(context);
            }),
            _ToggleLayoutIntent: NonTypingAction<_ToggleLayoutIntent>((_) {
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
                _daySelector(),
                FilterBar(
                  filter: filterState.filter,
                  isBypassed: filterState.isBypassed,
                  onFilterTap: () => _showFilterDialog(context),
                  onClearFilter: () => ref.read(filterProvider.notifier).clearFilter(),
                ),
                const Divider(height: 1),
                Expanded(child: _body()),
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

  Widget _daySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: 60,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _days.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final day = _days[index];
            final isSelected = _normalizedSelected == day;
            final dayOfWeek = DateFormat('E').format(day);
            return GestureDetector(
              onTap: () {
                setState(() => _selectedDate = day);
                ref.read(taskProvider.notifier).loadTasksForDate(day);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayOfWeek,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _body() {
    final provider = ref.watch(taskProvider);
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final projectState = ref.watch(projectProvider);
    final filter = ref.watch(filterProvider).activeFilter;
    final settings = ref.watch(settingsProvider);
    final showActiveOnly = settings.showActiveProjectsOnly;

    final overdue = provider.overdueTasks.where((t) {
      final project = t.projectId != null ? projectState.getById(t.projectId!) : null;
      if (showActiveOnly && project != null && !project.isActive) return false;
      return filter.applyToTask(t, project?.labelIds ?? []);
    }).toList();

    final allTasks = provider.tasks.where((t) {
      final project = t.projectId != null ? projectState.getById(t.projectId!) : null;
      if (showActiveOnly && project != null && !project.isActive) return false;
      return filter.applyToTask(t, project?.labelIds ?? []);
    }).toList();

    if (settings.getTaskLayout() == TaskLayout.kanban) {
      return KanbanBoard(
        tasks: [...(_isToday ? overdue : []), ...allTasks],
        onStatusChange: (task, status) => ref.read(taskProvider.notifier).updateTaskStatus(task, status),
        onContextMenu: (task, pos, box) => showTaskCardContextMenu(context, ref, task, pos, box),
        onEdit: (task) => _showEditTask(context, task),
        itemFocusNodes: _itemFocusNodes,
        onOrderedIdsChanged: (ids) {
          _orderedItemIds.clear();
          _orderedItemIds.addAll(ids);
        },
      );
    }

    return TaskListView(
      tasks: allTasks,
      overdueTasks: _isToday ? overdue : [],
      onContextMenu: (ctx, task, pos, box) => showTaskCardContextMenu(ctx, ref, task, pos, box),
      trailingBuilder: (ctx, task) => _taskTrailing(ctx, task),
      onOrderedIdsChanged: (ids) {
        _orderedItemIds.clear();
        _orderedItemIds.addAll(ids);
      },
      itemFocusNodes: _itemFocusNodes,
      onEdit: (task) => _showEditTask(context, task),
      emptyPlaceholder: _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            _isToday ? 'No tasks for today' : 'No tasks scheduled',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => _showAddTask(context), child: const Text('Add your first task')),
        ],
      ),
    );
  }

  Widget _taskTrailing(BuildContext context, Task task) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Builder(
          builder: (buttonContext) {
            return IconButton(
              icon: const Icon(Icons.more_vert, size: 18),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              onPressed: () {
                final RenderBox renderBox = buttonContext.findRenderObject() as RenderBox;
                final localPosition = Offset.zero;
                showTaskCardContextMenu(context, ref, task, localPosition, renderBox);
              },
            );
          },
        ),
      ],
    );
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
