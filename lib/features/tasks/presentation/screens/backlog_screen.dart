import 'package:carpe_diem/core/utils/focus_utils.dart';
import 'package:carpe_diem/core/utils/search_navigation_utils.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/presentation/providers/hidden_counts_provider.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/dialogs/filter_dialog.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/filter_bar.dart';
import 'package:carpe_diem/features/tasks/domain/task_selection_utils.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/actions/task_schedule_actions.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/backlog_label_tab_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/shortcuts/backlog_shortcuts.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog/backlog_dialog_handlers.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog/backlog_header.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog/backlog_label_tab_bar.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog/backlog_list.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_bulk_actions_bar.dart';
import 'package:dotmaterial/dotmaterial.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  String? _lastSelectedTaskId;
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
    debugLabelPrefix: 'BacklogTask',
  );

  String? _getFocusedTaskId() {
    if (_orderedItemIds.isEmpty) return null;
    for (var i = 0; i < _orderedItemIds.length; i++) {
      final node = _itemFocusNodes[_orderedItemIds[i]];
      if (node?.hasFocus ?? false) return _orderedItemIds[i];
    }
    return null;
  }

  Future<void> _scheduleTasks(
    Future<void> Function(List<String>) action,
  ) async {
    final ids = _selectedTaskIds.isNotEmpty
        ? List<String>.of(_selectedTaskIds)
        : [_getFocusedTaskId()].whereType<String>().toList();
    if (ids.isNotEmpty) {
      await action(ids);
      if (mounted && _selectedTaskIds.isNotEmpty) {
        setState(_selectedTaskIds.clear);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(taskProvider);

    _highlightedTaskId = SearchNavigationUtils.syncHighlight(
      isSearching: _searchFocusNode.hasFocus,
      orderedIds: _orderedItemIds,
      current: _highlightedTaskId,
    );
    ref.listen(backlogLabelTabProvider, (previous, next) {
      setState(
        _selectedTaskIds.clear,
      ); // TODO: cheap hack, maybe cary them over with an indicator in the multi select bar
    });

    return BacklogShortcuts(
      onMoveNext: () => _moveFocus(1),
      onMovePrev: () => _moveFocus(-1),
      onPrevTab: () => ref.read(backlogLabelTabProvider.notifier).prevTab(),
      onNextTab: () => ref.read(backlogLabelTabProvider.notifier).nextTab(),
      onShowFilter: () => showFilterDialog(context, ref),
      onFocusSearch: _searchFocusNode.requestFocus,
      onUnfocusSearch: () {
        if (_searchFocusNode.hasFocus) _leaveSearch();
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
                BacklogHeader(searchQuery: _searchQuery),
                const BacklogLabelTabBar(),
                FilterBar(
                  filter: ref.watch(filterProvider).filter,
                  isBypassed: ref.watch(filterProvider).isBypassed,
                  hiddenCount: ref.watch(hiddenUnscheduledTasksCountProvider),
                  hiddenItemType: 'tasks',
                  onFilterTap: () => showFilterDialog(context, ref),
                  onClearFilter: () =>
                      ref.read(filterProvider.notifier).clearFilter(),
                ),
                const Divider(height: 1),
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
                const Divider(height: 1),
                Expanded(
                  child: BacklogList(
                    searchQuery: _searchQuery,
                    highlightedTaskId: _highlightedTaskId,
                    selectedTaskIds: _selectedTaskIds,
                    onSelectedChanged: (task) => setState(() {
                      final isShift = HardwareKeyboard.instance.isShiftPressed;
                      final updated = TaskSelectionUtils.handleSelection(
                        task: task,
                        lastSelectedTaskId: _lastSelectedTaskId,
                        orderedIds: _orderedItemIds,
                        currentSelectedIds: _selectedTaskIds.toSet(),
                        allTasks: provider.unscheduledTasks,
                        isShiftPressed: isShift,
                      );
                      if (!isShift || _lastSelectedTaskId == null) {
                        _lastSelectedTaskId = task.id;
                      }
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
                      final next = SearchNavigationUtils.syncHighlight(
                        isSearching: _searchFocusNode.hasFocus,
                        orderedIds: ids,
                        current: _highlightedTaskId,
                      );
                      if (next != _highlightedTaskId) {
                        setState(() => _highlightedTaskId = next);
                      }
                    },
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
                tasks: provider.unscheduledTasks,
                onClearSelection: () => setState(() {
                  _selectedTaskIds.clear();
                  _lastSelectedTaskId = null;
                }),
                onActionCompleted: () => setState(_selectedTaskIds.clear),
                onScheduleToday: () => _scheduleTasks(
                  ref.read(taskProvider.notifier).scheduleTasksForToday,
                ),
                onScheduleTomorrow: () => _scheduleTasks(
                  ref.read(taskProvider.notifier).scheduleTasksForTomorrow,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
