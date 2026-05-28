import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/import_from_md_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog_context_menu.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card_context_menu.dart';
import 'package:carpe_diem/features/common/presentation/widgets/bulk_planning_bar.dart';
import 'package:carpe_diem/features/common/presentation/widgets/fuzzy_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_list/task_list_view.dart';
import 'package:flutter/services.dart';
import 'package:carpe_diem/features/common/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/filter_bar.dart';
import 'package:carpe_diem/features/common/presentation/providers/window_title_provider.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_detail/project_detail_header.dart';
import 'package:carpe_diem/features/projects/presentation/shortcuts/project_detail_shortcuts.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_detail/project_detail_dialog_handlers.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_detail/project_task_trailing_button.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_detail/project_detail_fab.dart';
import 'package:carpe_diem/core/utils/focus_utils.dart';

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
      if (event is KeyDownEvent &&
          (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.enter) &&
          _tasks.isNotEmpty) {
        _firstItemFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mainFocusNode.dispose();
    for (final node in {..._itemFocusNodes.values, _firstItemFocusNode}) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProjectDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) _loadTasks();
  }

  Future<void> _loadTasks({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _isLoading = true);
    final tasks = await ref.read(taskProvider.notifier).getTasksForProject(widget.projectId);
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    }
  }

  void _moveFocus(int delta) => FocusUtils.moveFocus(
    orderedItemIds: _orderedItemIds,
    itemFocusNodes: _itemFocusNodes,
    delta: delta,
    firstItemFocusNode: _firstItemFocusNode,
    debugLabelPrefix: 'ProjectTask',
  );

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

    return ProjectDetailShortcuts(
      project: project,
      onMoveNext: () => _moveFocus(1),
      onMovePrev: () => _moveFocus(-1),
      onFocusSearch: () => _searchFocusNode.requestFocus(),
      onUnfocusSearch: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          if (_tasks.isNotEmpty) {
            _firstItemFocusNode.requestFocus();
          } else {
            _mainFocusNode.requestFocus();
          }
        }
      },
      onNewTask: () => ProjectDetailDialogHandlers.showAddTask(context, widget.projectId),
      onShowFilter: () => ProjectDetailDialogHandlers.showFilterDialog(context, ref),
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
                    onEdit: () => ProjectDetailDialogHandlers.showEditProject(context, project),
                    onDelete: () => ProjectDetailDialogHandlers.showDeleteProject(context, ref, project),
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
                  FilterBar(
                    filter: ref.watch(filterProvider).filter,
                    isBypassed: ref.watch(filterProvider).isBypassed,
                    ignoreProjects: true,
                    onFilterTap: () => ProjectDetailDialogHandlers.showFilterDialog(context, ref),
                    onClearFilter: () => ref.read(filterProvider.notifier).clearFilter(),
                  ),
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
                                onContextMenu: (ctx, task, pos, box) => task.scheduledDate != null
                                    ? showTaskCardContextMenu(ctx, ref, task, pos, box)
                                    : showBacklogContextMenu(ctx, ref, task, pos, box),
                                trailingBuilder: (ctx, task) => ProjectTaskTrailingButton(task: task),
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
                                onSelectedChanged: (task) => setState(() {
                                  _selectedTaskIds.contains(task.id)
                                      ? _selectedTaskIds.remove(task.id)
                                      : _selectedTaskIds.add(task.id);
                                }),
                                onEdit: (task) => ProjectDetailDialogHandlers.showEditTask(context, task),
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
                      ProjectDetailDialogHandlers.showEditTask(context, task);
                    } else {
                      ProjectDetailDialogHandlers.showBulkEdit(
                        context: context,
                        ref: ref,
                        selectedTaskIds: _selectedTaskIds,
                        onCompleted: () => setState(() => _selectedTaskIds.clear()),
                      );
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
                      ProjectDetailDialogHandlers.showBulkDeleteConfirm(
                        context: context,
                        ref: ref,
                        selectedTaskIds: _selectedTaskIds,
                        onCompleted: () => setState(() => _selectedTaskIds.clear()),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: ProjectDetailFab(
            isActive: project.isActive,
            color: project.color,
            onPressed: () => ProjectDetailDialogHandlers.showAddTask(context, widget.projectId),
          ),
        ),
      ),
    );
  }
}
