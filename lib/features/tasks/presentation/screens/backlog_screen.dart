import 'package:carpe_diem/features/tasks/presentation/providers/backlog_label_tab_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog/backlog_label_tab_bar.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/context_menu/task_card_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/utils/focus_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/presentation/providers/hidden_counts_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog/backlog_list.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog/backlog_dialog_handlers.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/filter_bar.dart';
import 'package:carpe_diem/features/common/presentation/widgets/bulk_action_menu.dart';
import 'package:carpe_diem/features/common/presentation/widgets/bulk_planning_bar.dart';
import 'package:carpe_diem/features/common/presentation/widgets/fuzzy_search_bar.dart';
import 'package:carpe_diem/features/common/presentation/widgets/screen_header.dart';
import 'package:carpe_diem/features/tasks/presentation/shortcuts/backlog_shortcuts.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:carpe_diem/core/utils/task_selection_utils.dart';
import 'package:carpe_diem/core/utils/search_navigation_utils.dart';

class BacklogScreen extends ConsumerStatefulWidget {
  const BacklogScreen({super.key});

  @override
  ConsumerState<BacklogScreen> createState() => _BacklogScreenState();
}

class _BacklogScreenState extends ConsumerState<BacklogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _mainFocusNode = FocusNode();

  final Map<String, FocusNode> _itemFocusNodes = {};
  final List<String> _orderedItemIds = [];

  String _searchQuery = '';
  final List<String> _selectedTaskIds = [];
  String? _highlightedTaskId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskProvider.notifier).loadUnscheduledTasks();
    });

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
          if (_highlightedTaskId != null) {
            final tasks = ref.read(taskProvider).unscheduledTasks;
            final task = tasks
                .where((t) => t.id == _highlightedTaskId)
                .firstOrNull;
            if (task != null) {
              BacklogDialogHandlers.showEditTask(context, task);
            }
          }
        },
        onEscape: () {
          _searchFocusNode.unfocus();
          setState(() => _highlightedTaskId = null);
          if (_orderedItemIds.isNotEmpty) {
            _itemFocusNodes[_orderedItemIds.first]?.requestFocus();
          } else {
            _mainFocusNode.requestFocus();
          }
        },
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

  void _moveFocus(int delta) => FocusUtils.moveFocus(
    orderedItemIds: _orderedItemIds,
    itemFocusNodes: _itemFocusNodes,
    delta: delta,
    debugLabelPrefix: 'BacklogTask',
  );

  String? _getFocusedTaskId() {
    if (_orderedItemIds.isEmpty) return null;
    for (int i = 0; i < _orderedItemIds.length; i++) {
      final node = _itemFocusNodes[_orderedItemIds[i]];
      if (node?.hasFocus ?? false) return _orderedItemIds[i];
    }
    return null;
  }

  Future<void> _scheduleTasks(
    Future<void> Function(List<String>) action,
  ) async {
    final List<String> ids = _selectedTaskIds.isNotEmpty
        ? List.from(_selectedTaskIds)
        : [_getFocusedTaskId()].whereType<String>().toList();
    if (ids.isNotEmpty) {
      await action(ids);
      if (mounted && _selectedTaskIds.isNotEmpty) {
        setState(() => _selectedTaskIds.clear());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final provider = ref.watch(taskProvider);

    final isSearching = _searchFocusNode.hasFocus;
    if (isSearching && _orderedItemIds.isNotEmpty) {
      if (_highlightedTaskId == null ||
          !_orderedItemIds.contains(_highlightedTaskId)) {
        _highlightedTaskId = _orderedItemIds.first;
      }
    } else if (!isSearching) {
      _highlightedTaskId = null;
    }
    ref.listen(backlogLabelTabProvider, (previous, next) {
      setState(
        () => _selectedTaskIds.clear(),
      ); // TODO: cheap hack, maybe cary them over with an indicator in the multi select bar
    });

    return BacklogShortcuts(
      onMoveNext: () => _moveFocus(1),
      onMovePrev: () => _moveFocus(-1),
      onPrevTab: () => ref.read(backlogLabelTabProvider.notifier).prevTab(),
      onNextTab: () => ref.read(backlogLabelTabProvider.notifier).nextTab(),
      onShowFilter: () => BacklogDialogHandlers.showFilterDialog(context, ref),
      onFocusSearch: () => _searchFocusNode.requestFocus(),
      onUnfocusSearch: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          setState(() => _highlightedTaskId = null);
          if (_orderedItemIds.isNotEmpty) {
            _itemFocusNodes[_orderedItemIds.first]?.requestFocus();
          } else {
            _mainFocusNode.requestFocus();
          }
        }
      },
      onNewTask: () => BacklogDialogHandlers.showAddTask(context, ref: ref),
      onPlanTask: () =>
          _scheduleTasks(ref.read(taskProvider.notifier).scheduleTasksForToday),
      onPlanTaskTomorrow: () => _scheduleTasks(
        ref.read(taskProvider.notifier).scheduleTasksForTomorrow,
      ),
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
                        onPressed: () => BacklogDialogHandlers.pickRandomTask(
                          context,
                          ref,
                          _searchQuery,
                        ),
                        icon: const Icon(Icons.casino_rounded),
                        tooltip: 'Give me a random task!',
                      ),
                      const SizedBox(width: 8),
                    ],
                    FilledButton.icon(
                      onPressed: () =>
                          BacklogDialogHandlers.showAddTask(context, ref: ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Task'),
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderActions(context),
                  ],
                ),
                BacklogLabelTabBar(),
                FilterBar(
                  filter: ref.watch(filterProvider).filter,
                  isBypassed: ref.watch(filterProvider).isBypassed,
                  hiddenCount: ref.watch(hiddenUnscheduledTasksCountProvider),
                  hiddenItemType: 'tasks',
                  onFilterTap: () =>
                      BacklogDialogHandlers.showFilterDialog(context, ref),
                  onClearFilter: () =>
                      ref.read(filterProvider.notifier).clearFilter(),
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
                      if (_highlightedTaskId != null) {
                        final tasks = ref.read(taskProvider).unscheduledTasks;
                        final task = tasks
                            .where((t) => t.id == _highlightedTaskId)
                            .firstOrNull;
                        if (task != null) {
                          BacklogDialogHandlers.showEditTask(context, task);
                        }
                      } else if (_orderedItemIds.isNotEmpty) {
                        _itemFocusNodes[_orderedItemIds.first]?.requestFocus();
                      }
                    },
                  ),
                ),
                Divider(height: 1),
                Expanded(
                  child: BacklogList(
                    searchQuery: _searchQuery,
                    highlightedTaskId: _highlightedTaskId,
                    selectedTaskIds: _selectedTaskIds,
                    onSelectedChanged: (task) => setState(() {
                      final updated = TaskSelectionUtils.toggleSelection(
                        task: task,
                        allTasks: provider.unscheduledTasks,
                        currentSelectedIds: _selectedTaskIds.toSet(),
                      );
                      _selectedTaskIds
                        ..clear()
                        ..addAll(updated);
                    }),
                    onEdit: (task) =>
                        BacklogDialogHandlers.showEditTask(context, task),
                    itemFocusNodes: _itemFocusNodes,
                    onOrderedIdsChanged: (ids) {
                      _orderedItemIds.clear();
                      _orderedItemIds.addAll(ids);
                      final isSearching = _searchFocusNode.hasFocus;
                      if (isSearching && ids.isNotEmpty) {
                        if (_highlightedTaskId == null ||
                            !ids.contains(_highlightedTaskId)) {
                          setState(() => _highlightedTaskId = ids.first);
                        }
                      } else if (!isSearching && _highlightedTaskId != null) {
                        setState(() => _highlightedTaskId = null);
                      }
                    },
                    trailingBuilder: (ctx, task) =>
                        _taskTrailing(ctx, task, provider.unscheduledTasks),
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
                onClearSelection: () =>
                    setState(() => _selectedTaskIds.clear()),
                onScheduleToday: () => _scheduleTasks(
                  ref.read(taskProvider.notifier).scheduleTasksForToday,
                ),
                onScheduleTomorrow: () => _scheduleTasks(
                  ref.read(taskProvider.notifier).scheduleTasksForTomorrow,
                ),
                onBulkEdit: () {
                  if (_selectedTaskIds.length == 1) {
                    final task = provider.unscheduledTasks.firstWhere(
                      (t) => t.id == _selectedTaskIds.first,
                    );
                    BacklogDialogHandlers.showEditTask(context, task);
                  } else {
                    BacklogDialogHandlers.showBulkEdit(
                      context,
                      ref,
                      _selectedTaskIds,
                      () {
                        setState(() => _selectedTaskIds.clear());
                      },
                    );
                  }
                },
                onBulkDelete: () {
                  if (_selectedTaskIds.length == 1) {
                    final provider = ref.read(taskProvider);
                    final task = provider.unscheduledTasks.firstWhere(
                      (t) => t.id == _selectedTaskIds.first,
                    );
                    final subtasks = ref
                        .read(taskProvider.notifier)
                        .getAllSubtasks(task.id);
                    final message = subtasks.isEmpty
                        ? "Are you sure you want to delete this task?"
                        : "Are you sure you want to delete this task and its ${subtasks.length} subtask${subtasks.length > 1 ? 's' : ''}?";

                    showDialog(
                      context: context,
                      builder: (ctx) => DeleteDialog(
                        title: "Delete Task",
                        message: message,
                        onConfirm: () {
                          ref.read(taskProvider.notifier).deleteTask(task);
                          setState(() => _selectedTaskIds.clear());
                        },
                      ),
                    );
                  } else {
                    BacklogDialogHandlers.showBulkDeleteConfirm(
                      context: context,
                      ref: ref,
                      selectedTaskIds: _selectedTaskIds,
                      onCompleted: () {
                        setState(() => _selectedTaskIds.clear());
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context) {
    return BulkActionMenu(
      options: [
        BulkActionOption(
          value: 'import',
          icon: Icons.download_rounded,
          label: 'Import from MD',
          enabled: true,
        ),
      ],
      onOptionSelected: (value) {
        if (value == 'import') {
          BacklogDialogHandlers.showImportFromMD(context);
        }
      },
    );
  }

  Widget _taskTrailing(BuildContext context, Task task, List<Task> tasks) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Builder(
          builder: (buttonContext) {
            return IconButton(
              icon: const Icon(Icons.more_vert, size: 18),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              onPressed: () {
                final RenderBox renderBox =
                    buttonContext.findRenderObject() as RenderBox;
                final localPosition = Offset.zero;
                showTaskCardContextMenu(
                  context,
                  ref,
                  task,
                  tasks,
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
}
