import 'package:carpe_diem/features/tasks/data/models/task_hierarchy_node.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/add_task_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/common/sized_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/common/delete_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/filter_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/import_from_md_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/bulk_edit_tasks_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/blocker_indicator.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog_context_menu.dart';
import 'package:carpe_diem/features/common/presentation/widgets/filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/toast_utils.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/common/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/edit_task_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/bulk_action_menu.dart';
import 'package:carpe_diem/features/common/presentation/widgets/bulk_planning_bar.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_hierarchy_indicator.dart';
import 'package:carpe_diem/core/utils/task_hierarchy_utils.dart';
import 'package:carpe_diem/core/utils/fuzzy_search_utils.dart';
import 'package:carpe_diem/features/common/presentation/widgets/fuzzy_search_bar.dart';
import 'package:carpe_diem/features/common/presentation/widgets/screen_header.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/common/data/models/task_filter.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _mainFocusNode = FocusNode();

  final Map<String, FocusNode> _itemFocusNodes = {};
  final List<String> _orderedItemIds = [];

  String _searchQuery = '';
  final List<String> _selectedTaskIds = [];

  bool isFiltering(TaskFilter filter) => _searchQuery != "" || !filter.isEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadUnscheduledTasks();
    });

    _searchFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.enter) {
          if (_orderedItemIds.isNotEmpty) {
            final firstNode = _itemFocusNodes[_orderedItemIds.first];
            firstNode?.requestFocus();
            return KeyEventResult.handled;
          }
        }
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mainFocusNode.dispose();
    for (final node in _itemFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
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
      final node = _itemFocusNodes.putIfAbsent(id, () => FocusNode(debugLabel: 'BacklogTask_$id'));
      node.requestFocus();
    } else {
      final nextIndex = (currentIndex + delta).clamp(0, _orderedItemIds.length - 1);
      final id = _orderedItemIds[nextIndex];
      final node = _itemFocusNodes.putIfAbsent(id, () => FocusNode(debugLabel: 'BacklogTask_$id'));
      node.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return AppShortcutRegistrar(
      shortcuts: backlogShortcutEntries,
      child: Shortcuts(
        shortcuts: {
          const CharacterActivator('/'): const _FocusSearchIntent(),
          const SingleActivator(LogicalKeyboardKey.escape): const _UnfocusSearchIntent(),
          const CharacterActivator('a'): const _NewTaskIntent(),
          const CharacterActivator('A'): const _NewTaskIntent(),
          const CharacterActivator('j'): const MoveNextIntent(),
          const CharacterActivator('k'): const MovePrevIntent(),
          const CharacterActivator('f'): const FilterIntent(),
          const SingleActivator(LogicalKeyboardKey.keyT, control: true): const PlanTaskIntent(),
          const SingleActivator(LogicalKeyboardKey.keyT, control: true, shift: true): const PlanTaskTomorrowIntent(),
        },
        child: Actions(
          actions: {
            MoveNextIntent: NonTypingAction<MoveNextIntent>((_) {
              _moveFocus(1);
            }),
            MovePrevIntent: NonTypingAction<MovePrevIntent>((_) {
              _moveFocus(-1);
            }),
            FilterIntent: NonTypingAction<FilterIntent>((_) {
              _showFilterDialog(context);
            }),
            _FocusSearchIntent: NonTypingAction<_FocusSearchIntent>((_) {
              _searchFocusNode.requestFocus();
            }),
            _UnfocusSearchIntent: CallbackAction<_UnfocusSearchIntent>(
              onInvoke: (intent) {
                if (_searchFocusNode.hasFocus) {
                  _searchFocusNode.unfocus();
                  if (_orderedItemIds.isNotEmpty) {
                    _itemFocusNodes[_orderedItemIds.first]?.requestFocus();
                  } else {
                    _mainFocusNode.requestFocus();
                  }
                }
                return null;
              },
            ),
            _NewTaskIntent: NonTypingAction<_NewTaskIntent>((_) {
              _showAddTask(context);
            }),
            PlanTaskIntent: NonTypingAction<PlanTaskIntent>((_) {
              if (_selectedTaskIds.isNotEmpty) {
                context.read<TaskProvider>().scheduleTasksForToday(List.from(_selectedTaskIds)).then((_) {
                  setState(() => _selectedTaskIds.clear());
                });
              } else {
                final taskId = _getFocusedTaskId();
                if (taskId != null) {
                  context.read<TaskProvider>().scheduleTasksForToday([taskId]);
                }
              }
            }),
            PlanTaskTomorrowIntent: NonTypingAction<PlanTaskTomorrowIntent>((_) {
              if (_selectedTaskIds.isNotEmpty) {
                context.read<TaskProvider>().scheduleTasksForTomorrow(List.from(_selectedTaskIds)).then((_) {
                  setState(() => _selectedTaskIds.clear());
                });
              } else {
                final taskId = _getFocusedTaskId();
                if (taskId != null) {
                  context.read<TaskProvider>().scheduleTasksForTomorrow([taskId]);
                }
              }
            }),
          },
          child: Focus(
            focusNode: _mainFocusNode,
            autofocus: true,
            debugLabel: 'BacklogScreenMainFocus',
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScreenHeader(
                      title: 'Backlog',
                      subtitle: 'Tasks without a scheduled date',
                      actions: [
                        if (settings.enableRandomTask) ...[
                          IconButton(
                            onPressed: () => _pickRandomTask(context),
                            icon: Icon(Icons.casino_rounded),
                            tooltip: 'Give me a random task!',
                          ),
                          const SizedBox(width: 8),
                        ],
                        FilledButton.icon(
                          onPressed: () => _showAddTask(context),
                          icon: Icon(Icons.add),
                          label: Text('Add Task'),
                        ),
                        const SizedBox(width: 8),
                        _buildHeaderActions(context),
                      ],
                    ),
                    Consumer<FilterProvider>(
                      builder: (context, filterProvider, _) => FilterBar(
                        filter: filterProvider.filter,
                        isBypassed: filterProvider.isBypassed,
                        onFilterTap: () => _showFilterDialog(context),
                        onClearFilter: () => filterProvider.clearFilter(),
                      ),
                    ),
                    Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: FuzzySearchBar(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        hintText: 'Search backlog tasks... (Press / to focus)',
                        onChanged: (value) => setState(() {
                          _searchQuery = value;
                        }),
                        onSubmitted: (_) {
                          if (_orderedItemIds.isNotEmpty) {
                            _itemFocusNodes[_orderedItemIds.first]?.requestFocus();
                          }
                        },
                      ),
                    ),
                    Divider(height: 1),
                    Expanded(child: _taskList()),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: BulkPlanningBar(
                    selectedCount: _selectedTaskIds.length,
                    onClearSelection: () => setState(() => _selectedTaskIds.clear()),
                    onScheduleToday: () {
                      context.read<TaskProvider>().scheduleTasksForToday(_selectedTaskIds).then((_) {
                        setState(() => _selectedTaskIds.clear());
                      });
                    },
                    onScheduleTomorrow: () {
                      context.read<TaskProvider>().scheduleTasksForTomorrow(_selectedTaskIds).then((_) {
                        setState(() => _selectedTaskIds.clear());
                      });
                    },
                    onBulkEdit: () {
                      if (_selectedTaskIds.length == 1) {
                        final provider = context.read<TaskProvider>();
                        final task = provider.unscheduledTasks.firstWhere((t) => t.id == _selectedTaskIds.first);
                        _showEditTask(context, task);
                      } else {
                        _showBulkEdit(context);
                      }
                    },
                    onBulkDelete: () {
                      if (_selectedTaskIds.length == 1) {
                        final provider = context.read<TaskProvider>();
                        final task = provider.unscheduledTasks.firstWhere((t) => t.id == _selectedTaskIds.first);
                        showDialog(
                          context: context,
                          builder: (ctx) => DeleteDialog(
                            title: "Delete Task",
                            message: "Are you sure you want to delete this task?",
                            onConfirm: () {
                              provider.deleteTask(task);
                              setState(() => _selectedTaskIds.clear());
                            },
                          ),
                        );
                      } else {
                        _showBulkDeleteConfirm(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _getFocusedTaskId() {
    if (_orderedItemIds.isEmpty) return null;
    for (int i = 0; i < _orderedItemIds.length; i++) {
      final node = _itemFocusNodes[_orderedItemIds[i]];
      if (node?.hasFocus ?? false) {
        return _orderedItemIds[i];
      }
    }
    return null;
  }

  Widget _buildHeaderActions(BuildContext context) {
    return BulkActionMenu(
      options: [
        BulkActionOption(value: 'import', icon: Icons.download_rounded, label: 'Import from MD', enabled: true),
      ],
      onOptionSelected: (value) {
        switch (value) {
          case 'import':
            _showImportFromMD(context);
            break;
        }
      },
    );
  }

  Widget _taskList() {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        final projectProvider = context.read<ProjectProvider>();
        final filter = context.watch<FilterProvider>().activeFilter;
        var allTasks = provider.unscheduledTasks.where((t) {
          final project = t.projectId != null ? projectProvider.getById(t.projectId!) : null;
          return filter.applyToTask(t, project?.labelIds ?? []);
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
          _orderedItemIds.clear();
          return Center(
            child: isFiltering(filter)
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_list_alt, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      SizedBox(height: 16),
                      Text('No items found'),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = "";
                            _searchController.text = "";
                          });
                          context.read<FilterProvider>().clearFilter();
                        },
                        child: Text('Remove Filters'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_rounded, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      SizedBox(height: 16),
                      Text(
                        'No backlog tasks',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      TextButton(onPressed: () => _showAddTask(context), child: Text('Add a task')),
                    ],
                  ),
          );
        }

        final allAvailableTasks = {for (var t in provider.tasks) t.id: t}
          ..addAll({for (var t in provider.overdueTasks) t.id: t})
          ..addAll({for (var t in provider.unscheduledTasks) t.id: t});

        final activeHierarchical = TaskHierarchyUtils.buildHierarchy(activeTasks, allTasks: allAvailableTasks);
        final completedHierarchical = TaskHierarchyUtils.buildHierarchy(completedTasks, allTasks: allAvailableTasks);

        // Build the ordered list of IDs explicitly for traversal
        _orderedItemIds.clear();
        for (final n in activeHierarchical) {
          if (n is TaskNode) {
            _orderedItemIds.add(n.task.id);
          }
        }
        for (final n in completedHierarchical) {
          if (n is TaskNode) {
            _orderedItemIds.add(n.task.id);
          }
        }

        Widget buildNode(TaskHierarchyNode n) {
          Widget child;
          if (n is TaskNode) {
            final focusNode = _itemFocusNodes.putIfAbsent(n.task.id, () => FocusNode(debugLabel: 'Task_${n.task.id}'));

            child = TaskCard(
              key: ValueKey(n.task.id),
              task: n.task,
              project: n.task.projectId != null ? projectProvider.getById(n.task.projectId!) : null,
              isChecked: _selectedTaskIds.contains(n.task.id),
              selectionMode: true,
              focusNode: focusNode,
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

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            ...activeHierarchical.map((n) => buildNode(n)),
            if (completedHierarchical.isNotEmpty) ...[
              SizedBox(height: 20),
              Text(
                'Completed',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 8),
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
              icon: Icon(Icons.more_vert, size: 18),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              onPressed: () {
                final RenderBox renderBox = buttonContext.findRenderObject() as RenderBox;
                final localPosition = Offset.zero;
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
        child: ChangeNotifierProvider.value(value: context.read<ProjectProvider>(), child: AddTaskDialog()),
      ),
    );
  }

  void _showImportFromMD(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TaskProvider>(),
        child: ChangeNotifierProvider.value(value: context.read<ProjectProvider>(), child: ImportFromMDDialog()),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) async {
    final filterProvider = context.read<FilterProvider>();
    final result = await showDialog<TaskFilter>(
      context: context,
      builder: (_) => FilterDialog(initialFilter: filterProvider.filter),
    );
    if (result != null) {
      filterProvider.setFilter(result);
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
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete ${_selectedTaskIds.length} tasks?'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        contentTextStyle: Theme.of(context).textTheme.bodyMedium,
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () async {
              await context.read<TaskProvider>().bulkDeleteTasks(_selectedTaskIds);
              if (!mounted) return;
              setState(() => _selectedTaskIds.clear());
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _pickRandomTask(BuildContext context) async {
    final taskProvider = context.read<TaskProvider>();
    final projectProvider = context.read<ProjectProvider>();
    final filter = context.read<FilterProvider>().activeFilter;

    // Filter tasks based on current filters (same logic as in _taskList)
    var availableTasks = taskProvider.unscheduledTasks.where((t) {
      final project = t.projectId != null ? projectProvider.getById(t.projectId!) : null;
      return filter.applyToTask(t, project?.labelIds ?? []);
    }).toList();

    if (_searchQuery.isNotEmpty) {
      availableTasks = FuzzySearchUtils.search<Task>(
        query: _searchQuery,
        items: availableTasks,
        itemToString: (t) => '${t.title} ${t.description ?? ''}',
        threshold: 0.3,
      );
    }

    final randomTask = await taskProvider.pickAndScheduleRandomTask(availableTasks);

    if (randomTask == null) {
      ToastUtils.showInfo('No available tasks to pick from');
      return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => SizedDialog(
        title: 'We\'ve picked this task for you:',
        showDefaultActions: false,
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Great!'))],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TaskCard(
              task: randomTask,
              project: randomTask.projectId != null ? projectProvider.getById(randomTask.projectId!) : null,
              onToggle: (_) {}, // Read-only for history
              onTap: () {},
              leading: const SizedBox.shrink(),
              showStrikeThroughOnCompleted: false,
            ),
          ],
        ),
      ),
    );
  }
}
