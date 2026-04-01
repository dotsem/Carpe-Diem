import 'dart:async';

import 'package:carpe_diem/data/models/task.dart';
import 'package:carpe_diem/data/models/task_layout.dart';
import 'package:carpe_diem/data/models/task_filter.dart';
import 'package:carpe_diem/ui/dialogs/edit_task_dialog.dart';
import 'package:carpe_diem/ui/dialogs/filter_dialog.dart';
import 'package:carpe_diem/ui/widgets/context_menu/task_card_context_menu.dart';
import 'package:carpe_diem/ui/widgets/filter_bar.dart';
import 'package:carpe_diem/ui/widgets/kanban_board.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:carpe_diem/providers/task_provider.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:carpe_diem/ui/widgets/task_list_view.dart';
import 'package:carpe_diem/ui/dialogs/add_task_dialog.dart';
import 'package:carpe_diem/ui/shortcuts/app_shortcuts.dart';

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

class _FilterIntent extends Intent {
  const _FilterIntent();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedDate;
  TaskFilter _filter = const TaskFilter();
  late Timer timer;
  final _dateFormat = DateFormat('EEEE, MMMM d');

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
        context.read<TaskProvider>().loadTasksForDate(_selectedDate);
      }
    });
    _selectedDate = _today;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasksForDate(_selectedDate);
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  DateTime get _today => DateTime.now();
  DateTime get _normalizedSelected => DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

  bool get _isToday {
    final now = _today;
    return _normalizedSelected == DateTime(now.year, now.month, now.day);
  }

  List<DateTime> get _days {
    final today = DateTime(_today.year, _today.month, _today.day);
    return List.generate(AppConstants.maxPlanningDaysAhead + 1, (i) => today.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        const CharacterActivator('h'): const _PrevDayIntent(),
        const CharacterActivator('l'): const _NextDayIntent(),
        const CharacterActivator('n'): const _NewTaskIntent(),
        const CharacterActivator('v'): const _ToggleLayoutIntent(),
        const CharacterActivator('f'): const _FilterIntent(),
        const CharacterActivator('H'): const _PrevDayIntent(),
        const CharacterActivator('L'): const _NextDayIntent(),
        const CharacterActivator('N'): const _NewTaskIntent(),
        const CharacterActivator('V'): const _ToggleLayoutIntent(),
        const CharacterActivator('F'): const _FilterIntent(),
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
            context.read<TaskProvider>().toggleLayoutMode();
          }),
          _FilterIntent: NonTypingAction<_FilterIntent>((_) {
            _showFilterDialog(context);
          }),
        },
        child: Focus(
          autofocus: true,
          debugLabel: 'HomeScreenFocus',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              _daySelector(),
              FilterBar(
                filter: _filter,
                onFilterTap: () => _showFilterDialog(context),
                onClearFilter: () => setState(() => _filter = const TaskFilter()),
              ),
              const Divider(height: 1),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isToday ? 'Today' : _dateFormat.format(_selectedDate),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _isToday
                    ? _dateFormat.format(_selectedDate)
                    : '${_normalizedSelected.difference(DateTime(_today.year, _today.month, _today.day)).inDays} days from now',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => provider.toggleLayoutMode(),
            icon: Icon(provider.layoutMode == TaskLayout.list ? Icons.view_kanban : Icons.view_list),
            tooltip: provider.layoutMode == TaskLayout.list ? 'Kanban view' : 'List view',
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => _showAddTask(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  void _changeDay(int delta) {
    final days = _days;
    final currentIndex = days.indexWhere((d) => d == _normalizedSelected);
    final nextIndex = currentIndex + delta;
    if (nextIndex >= 0 && nextIndex < days.length) {
      setState(() => _selectedDate = days[nextIndex]);
      context.read<TaskProvider>().loadTasksForDate(days[nextIndex]);
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
                context.read<TaskProvider>().loadTasksForDate(day);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayOfWeek,
                      style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.text,
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
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final projectProvider = context.read<ProjectProvider>();

        final overdue = provider.overdueTasks.where((t) {
          final project = t.projectId != null ? projectProvider.getById(t.projectId!) : null;
          return _filter.applyToTask(t, project?.labelIds ?? []);
        }).toList();

        final allTasks = provider.tasks.where((t) {
          final project = t.projectId != null ? projectProvider.getById(t.projectId!) : null;
          return _filter.applyToTask(t, project?.labelIds ?? []);
        }).toList();

        if (provider.layoutMode == TaskLayout.kanban) {
          return KanbanBoard(
            tasks: [...(_isToday ? overdue : []), ...allTasks],
            projectProvider: projectProvider,
            onStatusChange: (task, status) => provider.updateTaskStatus(task, status),
            onContextMenu: (task, pos, box) => showTaskCardContextMenu(context, task, pos, box),
            onEdit: (task) => _showEditTask(context, task),
          );
        }

        return TaskListView(
          tasks: allTasks,
          overdueTasks: _isToday ? overdue : [],
          onContextMenu: (ctx, task, pos, box) => showTaskCardContextMenu(ctx, task, pos, box),
          trailingBuilder: (ctx, task) => _taskTrailing(ctx, task),
          onEdit: (task) => _showEditTask(context, task),
          emptyPlaceholder: _buildEmptyState(),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            _isToday ? 'No tasks for today' : 'No tasks scheduled',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
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
              color: AppColors.textSecondary,
              onPressed: () {
                final RenderBox renderBox = buttonContext.findRenderObject() as RenderBox;
                const localPosition = Offset.zero;
                showTaskCardContextMenu(context, task, localPosition, renderBox);
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
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TaskProvider>(),
        child: ChangeNotifierProvider.value(
          value: context.read<ProjectProvider>(),
          child: AddTaskDialog(initialDate: _selectedDate),
        ),
      ),
    );
  }

  void _showEditTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TaskProvider>(),
        child: ChangeNotifierProvider.value(
          value: context.read<ProjectProvider>(),
          child: EditTaskDialog(task: task),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) async {
    final result = await showDialog<TaskFilter>(
      context: context,
      builder: (_) => FilterDialog(initialFilter: _filter),
    );
    if (result != null) {
      setState(() => _filter = result);
    }
  }
}
