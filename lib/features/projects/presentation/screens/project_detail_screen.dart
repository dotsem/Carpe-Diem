import 'dart:async';

import 'package:carpe_diem/core/utils/focus_utils.dart';
import 'package:carpe_diem/core/utils/search_navigation_utils.dart';
import 'package:carpe_diem/features/common/presentation/providers/window_title_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/dialogs/filter_dialog.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/projects/presentation/shortcuts/project_detail_shortcuts.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_detail/project_detail_header.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_detail/project_detail_task_list.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_detail/project_detail_toolbar.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/domain/task_selection_utils.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/actions/task_schedule_actions.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_bulk_actions_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({required this.projectId, super.key});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _mainFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isLoading = true;
  List<Task> _tasks = [];
  final List<String> _selectedTaskIds = [];
  String? _lastSelectedTaskId;
  final List<String> _orderedItemIds = [];
  final Map<String, FocusNode> _itemFocusNodes = {};
  String? _highlightedTaskId;

  @override
  void initState() {
    super.initState();
    _loadTasks();

    _searchFocusNode.addListener(_handleSearchFocusChange);
    _searchFocusNode.onKeyEvent = (node, event) {
      return SearchNavigationUtils.handleSearchKeyEvent(
        event: event,
        orderedIds: _orderedItemIds,
        currentHighlightId: _highlightedTaskId,
        itemFocusNodes: _itemFocusNodes,
        onHighlightChanged: (newId) =>
            setState(() => _highlightedTaskId = newId),
        onSelect: () {
          if (_highlightedTaskId != null) _openHighlightedTask();
        },
        onEscape: _leaveSearch,
      );
    };
  }

  void _handleSearchFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChange);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mainFocusNode.dispose();
    for (final node in _itemFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProjectDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _selectedTaskIds.clear();
      _lastSelectedTaskId = null;
      _loadTasks();
    }
  }

  Future<void> _loadTasks({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _isLoading = true);
    final tasks = await ref
        .read(taskProvider.notifier)
        .getTasksForProject(widget.projectId);
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    }
  }

  void _leaveSearch() {
    _searchFocusNode.unfocus();
    setState(() => _highlightedTaskId = null);
    if (_orderedItemIds.isNotEmpty) {
      _itemFocusNodes[_orderedItemIds.first]?.requestFocus();
    } else {
      _mainFocusNode.requestFocus();
    }
  }

  void _moveFocus(int delta) => FocusUtils.moveFocus(
    orderedItemIds: _orderedItemIds,
    itemFocusNodes: _itemFocusNodes,
    delta: delta,
    debugLabelPrefix: 'ProjectTask',
  );

  void _openHighlightedTask() {
    final task = _tasks.where((t) => t.id == _highlightedTaskId).firstOrNull;
    if (task != null) context.openRightSidebar(EditTaskPanel(task.id));
  }

  Future<void> _scheduleSelected(
    Future<void> Function(List<String>) action,
  ) async {
    await action(List<String>.of(_selectedTaskIds));
    if (mounted) setState(_selectedTaskIds.clear);
  }

  void _clearSelection() => setState(() {
    _selectedTaskIds.clear();
    _lastSelectedTaskId = null;
  });

  void _showFilter() =>
      unawaited(showFilterDialog(context, ref, showProjectFilter: false));

  void _onSearchSubmitted(String _) {
    if (_highlightedTaskId != null) {
      _openHighlightedTask();
    } else if (_orderedItemIds.isNotEmpty) {
      _itemFocusNodes[_orderedItemIds.first]?.requestFocus();
    }
  }

  void _onOrderedIdsChanged(List<String> ids) {
    _orderedItemIds.clear();
    _orderedItemIds.addAll(ids);
    final next = SearchNavigationUtils.syncHighlight(
      isSearching: _searchFocusNode.hasFocus,
      orderedIds: ids,
      current: _highlightedTaskId,
    );
    if (next != _highlightedTaskId) setState(() => _highlightedTaskId = next);
  }

  void _onSelectedChanged(Task task) => setState(() {
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final updated = TaskSelectionUtils.handleSelection(
      task: task,
      lastSelectedTaskId: _lastSelectedTaskId,
      orderedIds: _orderedItemIds,
      currentSelectedIds: _selectedTaskIds.toSet(),
      allTasks: _tasks,
      isShiftPressed: isShift,
    );
    if (!isShift || _lastSelectedTaskId == null) {
      _lastSelectedTaskId = task.id;
    }
    _selectedTaskIds
      ..clear()
      ..addAll(updated);
  });

  @override
  Widget build(BuildContext context) {
    ref.listen(taskProvider, (previous, next) {
      _loadTasks(showLoading: false);
    });

    _highlightedTaskId = SearchNavigationUtils.syncHighlight(
      isSearching: _searchFocusNode.hasFocus,
      orderedIds: _orderedItemIds,
      current: _highlightedTaskId,
    );

    final project = ref.watch(projectProvider).getById(widget.projectId);

    if (project == null) {
      return Center(
        child: Text(
          'Project not found',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(windowTitleProvider.notifier)
          .updateTitle(subtitle: 'Project: ${project.name}');
    });

    final filter = ref
        .watch(filterProvider)
        .activeFilter
        .limitTo(projects: false);
    final filteredTasks = _tasks
        .where((t) => filter.applyToTask(t, project.labelIds))
        .toList();

    final hiddenCount = _tasks
        .where((t) => !project.isActive || !t.isCompleted)
        .where((t) => !filteredTasks.contains(t))
        .length;

    void clearSelection() => setState(_selectedTaskIds.clear);

    return ProjectDetailShortcuts(
      project: project,
      onMoveNext: () => _moveFocus(1),
      onMovePrev: () => _moveFocus(-1),
      onFocusSearch: _searchFocusNode.requestFocus,
      onUnfocusSearch: () {
        if (_searchFocusNode.hasFocus) _leaveSearch();
      },
      onNewTask: () => context.openRightSidebar(
        AddTaskPanel(initialProjectId: widget.projectId),
      ),
      onShowFilter: _showFilter,
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
                  ProjectDetailHeader(project: project),
                  ProjectDetailToolbar(
                    searchController: _searchController,
                    searchFocusNode: _searchFocusNode,
                    hiddenCount: hiddenCount,
                    onSearchChanged: (value) =>
                        setState(() => _searchQuery = value),
                    onSearchSubmitted: _onSearchSubmitted,
                    onShowFilter: _showFilter,
                  ),
                  Expanded(
                    child: ProjectDetailTaskList(
                      project: project,
                      allTasks: _tasks,
                      filteredTasks: filteredTasks,
                      isLoading: _isLoading,
                      searchQuery: _searchQuery,
                      highlightedTaskId: _highlightedTaskId,
                      itemFocusNodes: _itemFocusNodes,
                      selectedTaskIds: _selectedTaskIds.toSet(),
                      onOrderedIdsChanged: _onOrderedIdsChanged,
                      onClearSelection: _clearSelection,
                      onSelectedChanged: _onSelectedChanged,
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: TaskBulkActionsBar(
                  selectedTaskIds: _selectedTaskIds,
                  tasks: _tasks,
                  onClearSelection: _clearSelection,
                  onActionCompleted: clearSelection,
                  onScheduleToday: () => _scheduleSelected(
                    ref.read(taskProvider.notifier).scheduleTasksForToday,
                  ),
                  onScheduleTomorrow: () => _scheduleSelected(
                    ref.read(taskProvider.notifier).scheduleTasksForTomorrow,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
