import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/utils/focus_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/common/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog_list.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog_dialog_handlers.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog_context_menu.dart';
import 'package:carpe_diem/features/common/presentation/widgets/filter_bar.dart';
import 'package:carpe_diem/features/common/presentation/widgets/bulk_action_menu.dart';
import 'package:carpe_diem/features/common/presentation/widgets/bulk_planning_bar.dart';
import 'package:carpe_diem/features/common/presentation/widgets/fuzzy_search_bar.dart';
import 'package:carpe_diem/features/common/presentation/widgets/screen_header.dart';
import 'package:carpe_diem/features/tasks/presentation/shortcuts/backlog_shortcuts.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskProvider.notifier).loadUnscheduledTasks();
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

  Future<void> _scheduleTasks(Future<void> Function(List<String>) action) async {
    final List<String> ids = _selectedTaskIds.isNotEmpty
        ? List.from(_selectedTaskIds)
        : [_getFocusedTaskId()].whereType<String>().toList();
    if (ids.isNotEmpty) {
      await action(ids);
      if (mounted && _selectedTaskIds.isNotEmpty) setState(() => _selectedTaskIds.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return BacklogShortcuts(
      onMoveNext: () => _moveFocus(1),
      onMovePrev: () => _moveFocus(-1),
      onShowFilter: () => BacklogDialogHandlers.showFilterDialog(context, ref),
      onFocusSearch: () => _searchFocusNode.requestFocus(),
      onUnfocusSearch: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          if (_orderedItemIds.isNotEmpty) {
            _itemFocusNodes[_orderedItemIds.first]?.requestFocus();
          } else {
            _mainFocusNode.requestFocus();
          }
        }
      },
      onNewTask: () => BacklogDialogHandlers.showAddTask(context),
      onPlanTask: () => _scheduleTasks(ref.read(taskProvider.notifier).scheduleTasksForToday),
      onPlanTaskTomorrow: () => _scheduleTasks(ref.read(taskProvider.notifier).scheduleTasksForTomorrow),
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
                        onPressed: () => BacklogDialogHandlers.pickRandomTask(context, ref, _searchQuery),
                        icon: const Icon(Icons.casino_rounded),
                        tooltip: 'Give me a random task!',
                      ),
                      const SizedBox(width: 8),
                    ],
                    FilledButton.icon(
                      onPressed: () => BacklogDialogHandlers.showAddTask(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Task'),
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderActions(context),
                  ],
                ),
                FilterBar(
                  filter: ref.watch(filterProvider).filter,
                  isBypassed: ref.watch(filterProvider).isBypassed,
                  onFilterTap: () => BacklogDialogHandlers.showFilterDialog(context, ref),
                  onClearFilter: () => ref.read(filterProvider.notifier).clearFilter(),
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
                Expanded(
                  child: BacklogList(
                    searchQuery: _searchQuery,
                    selectedTaskIds: _selectedTaskIds,
                    onSelectedChanged: (task) => setState(() {
                      _selectedTaskIds.contains(task.id)
                          ? _selectedTaskIds.remove(task.id)
                          : _selectedTaskIds.add(task.id);
                    }),
                    onEdit: (task) => BacklogDialogHandlers.showEditTask(context, task),
                    itemFocusNodes: _itemFocusNodes,
                    onOrderedIdsChanged: (ids) {
                      _orderedItemIds.clear();
                      _orderedItemIds.addAll(ids);
                    },
                    trailingBuilder: (ctx, task) => _taskTrailing(ctx, task),
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
                onScheduleToday: () => _scheduleTasks(ref.read(taskProvider.notifier).scheduleTasksForToday),
                onScheduleTomorrow: () => _scheduleTasks(ref.read(taskProvider.notifier).scheduleTasksForTomorrow),
                onBulkEdit: () {
                  if (_selectedTaskIds.length == 1) {
                    final provider = ref.read(taskProvider);
                    final task = provider.unscheduledTasks.firstWhere((t) => t.id == _selectedTaskIds.first);
                    BacklogDialogHandlers.showEditTask(context, task);
                  } else {
                    BacklogDialogHandlers.showBulkEdit(context, ref, _selectedTaskIds, () {
                      setState(() => _selectedTaskIds.clear());
                    });
                  }
                },
                onBulkDelete: () {
                  if (_selectedTaskIds.length == 1) {
                    final provider = ref.read(taskProvider);
                    final task = provider.unscheduledTasks.firstWhere((t) => t.id == _selectedTaskIds.first);
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
                    BacklogDialogHandlers.showBulkDeleteConfirm(context, ref, _selectedTaskIds, () {
                      setState(() => _selectedTaskIds.clear());
                    });
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
        BulkActionOption(value: 'import', icon: Icons.download_rounded, label: 'Import from MD', enabled: true),
      ],
      onOptionSelected: (value) {
        if (value == 'import') {
          BacklogDialogHandlers.showImportFromMD(context);
        }
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              onPressed: () {
                final RenderBox renderBox = buttonContext.findRenderObject() as RenderBox;
                final localPosition = Offset.zero;
                showBacklogContextMenu(
                  context,
                  ref,
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
}
