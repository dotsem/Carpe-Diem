import 'package:carpe_diem/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/ui/dialogs/add_task_dialog.dart';
import 'package:carpe_diem/ui/dialogs/filter_dialog.dart';
import 'package:carpe_diem/ui/dialogs/import_from_md_dialog.dart';
import 'package:carpe_diem/ui/dialogs/bulk_edit_tasks_dialog.dart';
import 'package:carpe_diem/ui/widgets/blocker_indicator.dart';
import 'package:carpe_diem/ui/widgets/context_menu/backlog_context_menu.dart';
import 'package:carpe_diem/ui/widgets/filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/providers/task_provider.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:carpe_diem/ui/dialogs/edit_task_dialog.dart';
import 'package:carpe_diem/ui/widgets/bulk_action_menu.dart';
import 'package:carpe_diem/ui/widgets/task_card.dart';
import 'package:carpe_diem/ui/widgets/task_hierarchy_indicator.dart';
import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/core/utils/fuzzy_search_utils.dart';
import 'package:carpe_diem/ui/widgets/fuzzy_search_bar.dart';
import 'package:carpe_diem/ui/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/data/models/task.dart';
import 'package:carpe_diem/data/models/task_filter.dart';

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _UnfocusSearchIntent extends Intent {
  const _UnfocusSearchIntent();
}

class _NewTaskIntent extends Intent {
  const _NewTaskIntent();
}

class BacklogScreen extends StatefulWidget {
  const BacklogScreen({super.key});

  @override
  State<BacklogScreen> createState() => _BacklogScreenState();
}

class _BacklogScreenState extends State<BacklogScreen> {
  TaskFilter _filter = const TaskFilter();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _mainFocusNode = FocusNode();
  String _searchQuery = '';

  final List<String> _selectedTaskIds = [];

  bool isFiltering() => _searchQuery != "" || !_filter.isEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadUnscheduledTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mainFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        const CharacterActivator('/'): const _FocusSearchIntent(),
        const SingleActivator(LogicalKeyboardKey.escape): const _UnfocusSearchIntent(),
        const CharacterActivator('n'): const _NewTaskIntent(),
        const CharacterActivator('N'): const _NewTaskIntent(),
      },
      child: Actions(
        actions: {
          _FocusSearchIntent: NonTypingAction<_FocusSearchIntent>((_) {
            _searchFocusNode.requestFocus();
          }),
          _UnfocusSearchIntent: CallbackAction<_UnfocusSearchIntent>(
            onInvoke: (intent) {
              if (_searchFocusNode.hasFocus) {
                _searchFocusNode.unfocus();
                // Re-focus the main node so shortcuts still work
                _mainFocusNode.requestFocus();
              }
              return null;
            },
          ),
          _NewTaskIntent: NonTypingAction<_NewTaskIntent>((_) {
            _showAddTask(context);
          }),
        },
        child: Focus(
          focusNode: _mainFocusNode,
          autofocus: true,
          debugLabel: 'BacklogScreenMainFocus',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              FilterBar(
                filter: _filter,
                onFilterTap: () => _showFilterDialog(context),
                onClearFilter: () => setState(() => _filter = const TaskFilter()),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: FuzzySearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  hintText: 'Search backlog tasks... (Press / to focus)',
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _taskList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Backlog', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Tasks without a scheduled date', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          if (_selectedTaskIds.isNotEmpty) ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: AppColors.text),
              onPressed: () {
                context.read<TaskProvider>().scheduleTasksForToday(_selectedTaskIds).then((_) {
                  setState(() => _selectedTaskIds.clear());
                });
              },
              label: const Text('Plan tasks for today'),
              icon: const Icon(Icons.calendar_today_rounded),
            ),
            const SizedBox(width: 8),
          ],
          FilledButton.icon(
            onPressed: () => _showAddTask(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
          ),
          const SizedBox(width: 8),
          _buildHeaderActions(context),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context) {
    return BulkActionMenu(
      options: [
        BulkActionOption(value: 'import', icon: Icons.download_rounded, label: 'Import from MD', enabled: true),
        BulkActionOption(
          value: 'edit',
          icon: Icons.edit_rounded,
          label: 'Bulk Edit',
          enabled: _selectedTaskIds.length >= 2,
        ),
        BulkActionOption(
          value: 'delete',
          icon: Icons.delete_rounded,
          label: 'Bulk Delete',
          enabled: _selectedTaskIds.length >= 2,
          isDestructive: true,
        ),
      ],
      onOptionSelected: (value) {
        switch (value) {
          case 'import':
            _showImportFromMD(context);
            break;
          case 'edit':
            _showBulkEdit(context);
            break;
          case 'delete':
            _showBulkDeleteConfirm(context);
            break;
        }
      },
    );
  }

  Widget _taskList() {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final projectProvider = context.read<ProjectProvider>();
        var allTasks = provider.unscheduledTasks.where((t) {
          final project = t.projectId != null ? projectProvider.getById(t.projectId!) : null;
          return _filter.applyToTask(t, project?.labelIds ?? []);
        }).toList();

        if (_searchQuery.isNotEmpty) {
          allTasks = FuzzySearchUtils.search<Task>(
            query: _searchQuery,
            items: allTasks,
            itemToString: (t) => '${t.title} ${t.description ?? ''}',
            threshold: 0.3,
          );
        }

        final activeTasks = allTasks.where((t) => !t.isCompleted).toList();
        final completedTasks = allTasks.where((t) => t.isCompleted).toList();

        if (activeTasks.isEmpty && completedTasks.isEmpty) {
          return Center(
            child: isFiltering()
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.filter_list_alt, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      const Text('No items found'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() {
                          _searchQuery = "";
                          _searchController.text = "";
                          _filter = const TaskFilter();
                        }),
                        child: const Text('Remove Filters'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox_rounded, size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      const Text('No backlog tasks', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextButton(onPressed: () => _showAddTask(context), child: const Text('Add a task')),
                    ],
                  ),
          );
        }

        Widget buildNode(TaskHierarchyNode n, {bool autofocus = false}) {
          Widget child;
          if (n is TaskNode) {
            child = TaskCard(
              autofocus: autofocus,
              task: n.task,
              project: n.task.projectId != null ? projectProvider.getById(n.task.projectId!) : null,
              isChecked: _selectedTaskIds.contains(n.task.id),
              selectionMode: true,
              onToggle: (value) {
                if (value != null) {
                  setState(() {
                    if (value) {
                      _selectedTaskIds.add(n.task.id);
                    } else {
                      _selectedTaskIds.remove(n.task.id);
                    }
                  });
                }
              },
              onTap: () => _showEditTask(context, n.task),
              onContextMenu: (localPosition, renderBox) => showBacklogContextMenu(
                context,
                n.task,
                localPosition,
                renderBox,
                onAction: () {
                  if (_selectedTaskIds.contains(n.task.id)) {
                    setState(() => _selectedTaskIds.remove(n.task.id));
                  }
                },
              ),
              trailing: _taskTrailing(context, n.task),
            );
          } else if (n is BlockerIndicatorNode) {
            child = BlockerIndicator(
              blockerId: n.blockerId,
              blockerTitle: n.blockerTitle,
              blockedTaskId: n.blockedTaskId,
            );
          } else {
            return const SizedBox.shrink();
          }

          return TaskHierarchyIndicator(depth: n.depth, child: child);
        }

        final allAvailableTasks = {for (var t in provider.tasks) t.id: t}
          ..addAll({for (var t in provider.overdueTasks) t.id: t})
          ..addAll({for (var t in provider.unscheduledTasks) t.id: t});

        final activeHierarchical = TaskHierarchyUtils.buildHierarchy(activeTasks, allTasks: allAvailableTasks);
        final completedHierarchical = TaskHierarchyUtils.buildHierarchy(completedTasks, allTasks: allAvailableTasks);

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            ...activeHierarchical.asMap().entries.map(
              (entry) => buildNode(entry.value, autofocus: entry.key == 0 && entry.value is TaskNode),
            ),
            if (completedHierarchical.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Completed',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              ...completedHierarchical.map((n) => buildNode(n)),
            ],
          ],
        );
      },
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
                showBacklogContextMenu(
                  context,
                  task,
                  localPosition,
                  renderBox,
                  onAction: () {
                    if (_selectedTaskIds.contains(task.id)) {
                      setState(() => _selectedTaskIds.remove(task.id));
                    }
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showEditTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<TaskProvider>()),
          ChangeNotifierProvider.value(value: context.read<ProjectProvider>()),
        ],
        child: EditTaskDialog(task: task),
      ),
    );
  }

  void _showAddTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TaskProvider>(),
        child: ChangeNotifierProvider.value(value: context.read<ProjectProvider>(), child: const AddTaskDialog()),
      ),
    );
  }

  void _showImportFromMD(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TaskProvider>(),
        child: ChangeNotifierProvider.value(value: context.read<ProjectProvider>(), child: const ImportFromMDDialog()),
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

  void _showBulkEdit(BuildContext context) async {
    final result = await showDialog<BulkEditResult>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TaskProvider>(),
        child: ChangeNotifierProvider.value(
          value: context.read<ProjectProvider>(),
          child: BulkEditTasksDialog(taskIds: _selectedTaskIds),
        ),
      ),
    );

    if (result != null && context.mounted) {
      await context.read<TaskProvider>().bulkUpdateTasks(
        taskIds: _selectedTaskIds,
        priority: result.priority,
        updatePriority: result.updatePriority,
        scheduledDate: result.scheduledDate,
        updateScheduledDate: result.updateScheduledDate,
        clearScheduledDate: result.clearScheduledDate,
        projectId: result.projectId,
        updateProjectId: result.updateProjectId,
        clearProjectId: result.clearProjectId,
        deadline: result.deadline,
        updateDeadline: result.updateDeadline,
        clearDeadline: result.clearDeadline,
        blockedById: result.blockedById,
        updateBlockedById: result.updateBlockedById,
        clearBlockedById: result.clearBlockedById,
      );
      setState(() => _selectedTaskIds.clear());
    }
  }

  void _showBulkDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete ${_selectedTaskIds.length} tasks?'),
        backgroundColor: AppColors.surfaceLight,
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        contentTextStyle: Theme.of(context).textTheme.bodyMedium,
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.text),
            onPressed: () async {
              await context.read<TaskProvider>().bulkDeleteTasks(_selectedTaskIds);
              if (!mounted) return;
              setState(() => _selectedTaskIds.clear());
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
