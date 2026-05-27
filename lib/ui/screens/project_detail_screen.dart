import 'package:carpe_diem/data/models/label.dart';
import 'package:carpe_diem/providers/label_provider.dart';
import 'package:carpe_diem/ui/dialogs/import_from_md_dialog.dart';
import 'package:carpe_diem/ui/widgets/chip/chip.dart';
import 'package:carpe_diem/ui/widgets/chip/label_chip.dart';
import 'package:go_router/go_router.dart';
import 'package:carpe_diem/ui/widgets/context_menu/backlog_context_menu.dart';
import 'package:carpe_diem/ui/widgets/context_menu/task_card_context_menu.dart';
import 'package:carpe_diem/ui/dialogs/edit_task_dialog.dart';
import 'package:carpe_diem/ui/dialogs/bulk_edit_tasks_dialog.dart';
import 'package:carpe_diem/ui/widgets/bulk_action_menu.dart';
import 'package:carpe_diem/ui/widgets/bulk_planning_bar.dart';
import 'package:carpe_diem/ui/widgets/fuzzy_search_bar.dart';
import 'package:carpe_diem/ui/widgets/priority_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/data/models/project.dart';
import 'package:carpe_diem/data/models/task.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:carpe_diem/providers/task_provider.dart';
import 'package:carpe_diem/ui/widgets/task_list_view.dart';
import 'package:carpe_diem/ui/dialogs/edit_project_dialog.dart';
import 'package:carpe_diem/ui/dialogs/add_task_dialog.dart';
import 'package:carpe_diem/ui/dialogs/common/delete_dialog.dart';
import 'package:flutter/services.dart';
import 'package:carpe_diem/core/utils/toast_utils.dart';
import 'package:carpe_diem/providers/filter_provider.dart';
import 'package:carpe_diem/data/models/task_filter.dart';
import 'package:carpe_diem/ui/dialogs/filter_dialog.dart';
import 'package:carpe_diem/ui/widgets/filter_bar.dart';
import 'package:carpe_diem/ui/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/providers/window_title_provider.dart';

class _NewTaskIntent extends Intent {
  const _NewTaskIntent();
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _UnfocusSearchIntent extends Intent {
  const _UnfocusSearchIntent();
}

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _mainFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isLoading = true;
  List<Task> _tasks = [];
  late TaskProvider _taskProvider;
  final List<String> _selectedTaskIds = [];
  final FocusNode _firstItemFocusNode = FocusNode(debugLabel: 'ProjectDetailFirstItem');
  final List<String> _orderedItemIds = [];
  final Map<String, FocusNode> _itemFocusNodes = {};

  @override
  void initState() {
    super.initState();
    _taskProvider = context.read<TaskProvider>();
    _loadTasks();

    _searchFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.enter) {
          if (_tasks.isNotEmpty) {
            _firstItemFocusNode.requestFocus();
            return KeyEventResult.handled;
          }
        }
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _taskProvider = context.read<TaskProvider>();
    _taskProvider.removeListener(_onTasksChanged);
    _taskProvider.addListener(_onTasksChanged);
  }

  @override
  void dispose() {
    _taskProvider.removeListener(_onTasksChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mainFocusNode.dispose();

    final uniqueNodes = {..._itemFocusNodes.values, _firstItemFocusNode};
    for (final node in uniqueNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProjectDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _loadTasks();
    }
  }

  void _onTasksChanged() {
    if (mounted) {
      _loadTasks(showLoading: false);
    }
  }

  Future<void> _loadTasks({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }
    final tasks = await _taskProvider.getTasksForProject(widget.projectId);
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    }
  }

  void _moveFocus(int delta) {
    if (_orderedItemIds.isEmpty) return;

    int currentIndex = -1;
    for (int j = 0; j < _orderedItemIds.length; j++) {
      final node = (j == 0) ? _firstItemFocusNode : _itemFocusNodes[_orderedItemIds[j]];
      if (node?.hasFocus ?? false) {
        currentIndex = j;
        break;
      }
    }

    if (currentIndex == -1) {
      final targetIndex = delta > 0 ? 0 : _orderedItemIds.length - 1;
      final id = _orderedItemIds[targetIndex];
      final node = _itemFocusNodes.putIfAbsent(
        id,
        () => (id == _orderedItemIds[0]) ? _firstItemFocusNode : FocusNode(debugLabel: 'ProjectTask_$id'),
      );
      node.requestFocus();
    } else {
      final nextIndex = (currentIndex + delta).clamp(0, _orderedItemIds.length - 1);
      final id = _orderedItemIds[nextIndex];
      final node = _itemFocusNodes.putIfAbsent(id, () => FocusNode(debugLabel: 'ProjectTask_$id'));
      node.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        final project = projectProvider.getById(widget.projectId);

        final selectedTasksAlreadyScheduled = _selectedTaskIds
            .map((id) => _tasks.firstWhere((t) => t.id == id))
            .every((task) => task.scheduledDate != null);

        if (project == null) {
          return Center(
            child: Text("Project not found", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<WindowTitleProvider>().updateTitle(subtitle: 'Project: ${project.name}');
        });

        return AppShortcutRegistrar(
          shortcuts: projectDetailShortcutEntries,
          child: Shortcuts(
            shortcuts: {
              const CharacterActivator('/'): const _FocusSearchIntent(),
              const SingleActivator(LogicalKeyboardKey.escape): const _UnfocusSearchIntent(),
              if (project.isActive) const CharacterActivator('n'): const _NewTaskIntent(),
              if (project.isActive) const CharacterActivator('N'): const _NewTaskIntent(),
              const CharacterActivator('j'): const MoveNextIntent(),
              const CharacterActivator('k'): const MovePrevIntent(),
              const CharacterActivator('f'): const FilterIntent(),
            },
            child: Actions(
              actions: {
                MoveNextIntent: NonTypingAction<MoveNextIntent>((_) {
                  _moveFocus(1);
                }),
                MovePrevIntent: NonTypingAction<MovePrevIntent>((_) {
                  _moveFocus(-1);
                }),
                _FocusSearchIntent: NonTypingAction<_FocusSearchIntent>((_) {
                  _searchFocusNode.requestFocus();
                }),
                _UnfocusSearchIntent: CallbackAction<_UnfocusSearchIntent>(
                  onInvoke: (intent) {
                    if (_searchFocusNode.hasFocus) {
                      _searchFocusNode.unfocus();
                      if (_tasks.isNotEmpty) {
                        _firstItemFocusNode.requestFocus();
                      } else {
                        _mainFocusNode.requestFocus();
                      }
                    }
                    return null;
                  },
                ),
                if (project.isActive)
                  _NewTaskIntent: NonTypingAction<_NewTaskIntent>((_) {
                    _showAddTask(context);
                  }),
                FilterIntent: NonTypingAction<FilterIntent>((_) {
                  _showFilterDialog(context);
                }),
              },
              child: Focus(
                focusNode: _mainFocusNode,
                autofocus: true,
                debugLabel: 'ProjectDetailScreenMainFocus',
                child: Scaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  body: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(context, project),
                          Divider(color: Theme.of(context).colorScheme.surfaceContainerHigh, height: 1),
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
                                if (_tasks.isNotEmpty) {
                                  _firstItemFocusNode.requestFocus();
                                }
                              },
                            ),
                          ),
                          Consumer<FilterProvider>(
                            builder: (context, filterProvider, _) => FilterBar(
                              filter: filterProvider.filter,
                              isBypassed: filterProvider.isBypassed,
                              ignoreProjects: true,
                              onFilterTap: () => _showFilterDialog(context),
                              onClearFilter: () => filterProvider.clearFilter(),
                            ),
                          ),
                          Divider(color: Theme.of(context).colorScheme.surfaceContainerHigh, height: 1),
                          Expanded(
                            child: _isLoading
                                ? Center(child: CircularProgressIndicator())
                                : Builder(
                                    builder: (context) {
                                      final filter = context.watch<FilterProvider>().activeFilter.limitTo(
                                        projects: false,
                                      );
                                      final filteredTasks = _tasks
                                          .where((t) => filter.applyToTask(t, project.labelIds))
                                          .toList();
                                      return TaskListView(
                                        tasks: filteredTasks,
                                        padding: const EdgeInsets.symmetric(vertical: 24),
                                        onContextMenu: (ctx, task, pos, box) {
                                          if (task.scheduledDate != null) {
                                            showTaskCardContextMenu(ctx, task, pos, box);
                                          } else {
                                            showBacklogContextMenu(ctx, task, pos, box);
                                          }
                                        },
                                        trailingBuilder: (ctx, task) => _taskTrailing(ctx, task),
                                        emptyPlaceholder: Center(
                                          child: Text(
                                            "No tasks in this project",
                                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                          ),
                                        ),
                                        onOrderedIdsChanged: (ids) {
                                          _orderedItemIds.clear();
                                          _orderedItemIds.addAll(ids);
                                        },
                                        itemFocusNodes: _itemFocusNodes,
                                        searchQuery: _searchQuery,
                                        enablePlanShortcut: true,
                                        firstNode: _firstItemFocusNode,
                                        showScheduleDate: true,
                                        selectionMode: true,
                                        selectedTaskIds: _selectedTaskIds.toSet(),
                                        onSelectedChanged: (task) {
                                          setState(() {
                                            if (_selectedTaskIds.contains(task.id)) {
                                              _selectedTaskIds.remove(task.id);
                                            } else {
                                              _selectedTaskIds.add(task.id);
                                            }
                                          });
                                        },
                                        onEdit: (task) => _showEditTask(context, task),
                                        isReadOnly: !project.isActive,
                                        initialDoneExpanded: !project.isActive,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 16,
                        child: BulkPlanningBar(
                          selectedCount: _selectedTaskIds.length,
                          onClearSelection: () => setState(() => _selectedTaskIds.clear()),
                          disableScheduling: selectedTasksAlreadyScheduled,
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
                              final task = _tasks.firstWhere((t) => t.id == _selectedTaskIds.first);
                              _showEditTask(context, task);
                            } else {
                              _showBulkEdit(context);
                            }
                          },
                          onBulkDelete: () {
                            if (_selectedTaskIds.length == 1) {
                              final task = _tasks.firstWhere((t) => t.id == _selectedTaskIds.first);
                              showDialog(
                                context: context,
                                builder: (ctx) => DeleteDialog(
                                  title: "Delete Task",
                                  message: "Are you sure you want to delete this task?",
                                  onConfirm: () {
                                    context.read<TaskProvider>().deleteTask(task);
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
                  floatingActionButton: project.isActive
                      ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black,
                                blurRadius: 15,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: FloatingActionButton(
                            onPressed: () => _showAddTask(context),
                            backgroundColor: project.color,
                            elevation: 0,
                            highlightElevation: 0,
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, Project project) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 16),
      child: Stack(
        children: [
          Positioned(left: 0, top: 0, bottom: 0, child: PriorityIndicator(priority: project.priority)),
          Padding(
            padding: const EdgeInsets.only(left: 22), // width of indicator (6) + spacing (16)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: project.color),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          project.name,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        onPressed: () => _showEditProject(context, project),
                        tooltip: 'Edit Project',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () => _showDeleteProject(context, project),
                        tooltip: 'Delete Project',
                      ),
                      const SizedBox(width: 8),
                      BulkActionMenu(
                        options: [
                          BulkActionOption(
                            value: 'import',
                            icon: Icons.download,
                            label: 'Import from Markdown',
                            enabled: true,
                          ),
                        ],
                        onOptionSelected: (value) {
                          if (value == 'import') {
                            showDialog(
                              context: context,
                              builder: (_) => ImportFromMDDialog(project: project),
                            ).then((_) => setState(() {}));
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (project.deadline != null) DeadlineChip(deadline: project.deadline!),
                    ..._getLabels(context, project),
                  ],
                ),
                if (project.description?.isNotEmpty == true) ...[
                  SizedBox(height: 16),
                  // TODO: add expand button
                  Text(
                    project.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getLabels(BuildContext context, Project project) {
    final labelProvider = context.watch<LabelProvider>();
    final labels = project.labelIds.map((id) => labelProvider.getById(id)).whereType<Label>().toList();

    return labels.map((label) => LabelChip(label: label, verticalPadding: 1)).toList();
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
                if (task.scheduledDate != null) {
                  showTaskCardContextMenu(context, task, localPosition, renderBox);
                } else {
                  showBacklogContextMenu(context, task, localPosition, renderBox);
                }
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

  void _showBulkEdit(BuildContext context) async {
    final result = await showDialog<BulkEditResult>(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<TaskProvider>()),
          ChangeNotifierProvider.value(value: context.read<ProjectProvider>()),
        ],
        child: BulkEditTasksDialog(taskIds: _selectedTaskIds),
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

  void _showEditProject(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<ProjectProvider>()),
          ChangeNotifierProvider.value(value: context.read<LabelProvider>()),
        ],
        child: EditProjectDialog(project: project),
      ),
    );
  }

  void _showDeleteProject(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (ctx) => DeleteDialog(
        title: 'Delete Project',
        message:
            'Are you sure you want to delete "${project.name}"? This will not delete the tasks, but they will no longer be associated with this project.',
        onConfirm: () async {
          final provider = context.read<ProjectProvider>();

          await provider.deleteProject(project);

          if (context.mounted) {
            GoRouter.of(context).go('/projects');
            ToastUtils.showSuccess('Project "${project.name}" deleted', context: context);
          }
        },
      ),
    );
  }

  void _showAddTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<TaskProvider>()),
          ChangeNotifierProvider.value(value: context.read<ProjectProvider>()),
        ],
        child: AddTaskDialog(initialProjectId: widget.projectId),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) async {
    final filterProvider = context.read<FilterProvider>();
    final result = await showDialog<TaskFilter>(
      context: context,
      builder: (_) => FilterDialog(initialFilter: filterProvider.filter, showProjectFilter: false),
    );
    if (result != null) {
      filterProvider.setFilter(result);
    }
  }
}
