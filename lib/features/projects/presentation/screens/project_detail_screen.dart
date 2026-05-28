import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/import_from_md_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog_context_menu.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card_context_menu.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/edit_task_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/bulk_edit_tasks_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/bulk_planning_bar.dart';
import 'package:carpe_diem/features/common/presentation/widgets/fuzzy_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_list_view.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/dialogs/edit_project_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/add_task_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:flutter/services.dart';
import 'package:carpe_diem/core/utils/toast_utils.dart';
import 'package:carpe_diem/features/common/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/common/data/models/task_filter.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/filter_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/filter_bar.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/features/common/presentation/providers/window_title_provider.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_detail_header.dart';

class _NewTaskIntent extends Intent {
  const _NewTaskIntent();
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _UnfocusSearchIntent extends Intent {
  const _UnfocusSearchIntent();
}

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _mainFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isLoading = true;
  List<Task> _tasks = [];
  final List<String> _selectedTaskIds = [];
  final FocusNode _firstItemFocusNode = FocusNode(debugLabel: 'ProjectDetailFirstItem');
  final List<String> _orderedItemIds = [];
  final Map<String, FocusNode> _itemFocusNodes = {};

  @override
  void initState() {
    super.initState();
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
  void dispose() {
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

  Future<void> _loadTasks({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }
    final tasks = await ref.read(taskProvider.notifier).getTasksForProject(widget.projectId);
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
    ref.listen(taskProvider, (previous, next) {
      _loadTasks(showLoading: false);
    });

    final project = ref.watch(projectProvider).getById(widget.projectId);

    if (project == null) {
      return Center(
        child: Text("Project not found", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }

    final selectedTasksAlreadyScheduled = _selectedTaskIds
        .map((id) => _tasks.firstWhere((t) => t.id == id))
        .every((task) => task.scheduledDate != null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(windowTitleProvider.notifier).updateTitle(subtitle: 'Project: ${project.name}');
    });

    return AppShortcutRegistrar(
      shortcuts: projectDetailShortcutEntries,
      child: Shortcuts(
        shortcuts: {
          const CharacterActivator(SearchKeys.char): const _FocusSearchIntent(),
          const SingleActivator(AppKeyBindings.escape): const _UnfocusSearchIntent(),
          if (project.isActive) const CharacterActivator(AddKeys.char): const _NewTaskIntent(),
          if (project.isActive) const CharacterActivator(AddKeys.upper): const _NewTaskIntent(),
          const CharacterActivator(DownKeys.char): const MoveNextIntent(),
          const CharacterActivator(UpKeys.char): const MovePrevIntent(),
          const SingleActivator(AppKeyBindings.arrowDown): const MoveNextIntent(),
          const SingleActivator(AppKeyBindings.arrowUp): const MovePrevIntent(),
          const CharacterActivator(FilterKeys.char): const FilterIntent(),
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
                      ProjectDetailHeader(
                        project: project,
                        onEdit: () => _showEditProject(context, project),
                        onDelete: () => _showDeleteProject(context, project),
                        onImportMd: () {
                          showDialog(
                            context: context,
                            builder: (_) => ImportFromMDDialog(project: project),
                          ).then((_) => setState(() {}));
                        },
                      ),
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
                      () {
                        final filterState = ref.watch(filterProvider);
                        return FilterBar(
                          filter: filterState.filter,
                          isBypassed: filterState.isBypassed,
                          ignoreProjects: true,
                          onFilterTap: () => _showFilterDialog(context),
                          onClearFilter: () => ref.read(filterProvider.notifier).clearFilter(),
                        );
                      }(),
                      Divider(color: Theme.of(context).colorScheme.surfaceContainerHigh, height: 1),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Builder(
                                builder: (context) {
                                  final filter = ref.watch(filterProvider).activeFilter.limitTo(projects: false);
                                  final filteredTasks = _tasks
                                      .where((t) => filter.applyToTask(t, project.labelIds))
                                      .toList();
                                  return TaskListView(
                                    tasks: filteredTasks,
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    onContextMenu: (ctx, task, pos, box) {
                                      if (task.scheduledDate != null) {
                                        showTaskCardContextMenu(ctx, ref, task, pos, box);
                                      } else {
                                        showBacklogContextMenu(ctx, ref, task, pos, box);
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
                                    onClearSelection: () => setState(() => _selectedTaskIds.clear()),
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
                        ref.read(taskProvider.notifier).scheduleTasksForToday(_selectedTaskIds).then((_) {
                          setState(() => _selectedTaskIds.clear());
                        });
                      },
                      onScheduleTomorrow: () {
                        ref.read(taskProvider.notifier).scheduleTasksForTomorrow(_selectedTaskIds).then((_) {
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
                                ref.read(taskProvider.notifier).deleteTask(task);
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
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black, blurRadius: 15, spreadRadius: 2, offset: Offset(0, 4)),
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
                if (task.scheduledDate != null) {
                  showTaskCardContextMenu(context, ref, task, localPosition, renderBox);
                } else {
                  showBacklogContextMenu(context, ref, task, localPosition, renderBox);
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
      builder: (_) => EditTaskDialog(task: task),
    );
  }

  void _showBulkEdit(BuildContext context) async {
    final result = await showDialog<BulkEditResult>(
      context: context,
      builder: (_) => BulkEditTasksDialog(taskIds: _selectedTaskIds),
    );

    if (result != null && context.mounted) {
      await ref
          .read(taskProvider.notifier)
          .bulkUpdateTasks(
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
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () async {
              await ref.read(taskProvider.notifier).bulkDeleteTasks(_selectedTaskIds);
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

  void _showEditProject(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (_) => EditProjectDialog(project: project),
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
          final notifier = ref.read(projectProvider.notifier);

          await notifier.deleteProject(project);

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
      builder: (_) => AddTaskDialog(initialProjectId: widget.projectId),
    );
  }

  void _showFilterDialog(BuildContext context) async {
    final filterNotifier = ref.read(filterProvider.notifier);
    final result = await showDialog<TaskFilter>(
      context: context,
      builder: (_) => FilterDialog(initialFilter: ref.read(filterProvider).filter, showProjectFilter: false),
    );
    if (result != null) {
      filterNotifier.setFilter(result);
    }
  }
}
