import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/add_task_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/filter_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/import_from_md_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/bulk_edit_tasks_dialog.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog_context_menu.dart';
import 'package:carpe_diem/features/common/presentation/widgets/filter_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/utils/toast_utils.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/common/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/edit_task_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/bulk_action_menu.dart';
import 'package:carpe_diem/features/common/presentation/widgets/bulk_planning_bar.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/task_card/task_card.dart';
import 'package:carpe_diem/core/utils/fuzzy_search_utils.dart';
import 'package:carpe_diem/features/common/presentation/widgets/fuzzy_search_bar.dart';
import 'package:carpe_diem/features/common/presentation/widgets/screen_header.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/core/utils/focus_utils.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/common/data/models/task_filter.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog_list.dart';

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _UnfocusSearchIntent extends Intent {
  const _UnfocusSearchIntent();
}

class _NewTaskIntent extends Intent {
  const _NewTaskIntent();
}

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
        orderedItemIds: _orderedItemIds, itemFocusNodes: _itemFocusNodes,
        delta: delta, debugLabelPrefix: 'BacklogTask',
      );

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return AppShortcutRegistrar(
      shortcuts: backlogShortcutEntries,
      child: Shortcuts(
        shortcuts: {
          const CharacterActivator(SearchKeys.char): const _FocusSearchIntent(),
          const SingleActivator(AppKeyBindings.escape): const _UnfocusSearchIntent(),
          const CharacterActivator(AddKeys.char): const _NewTaskIntent(),
          const CharacterActivator(AddKeys.upper): const _NewTaskIntent(),
          const CharacterActivator(DownKeys.char): const MoveNextIntent(),
          const CharacterActivator(UpKeys.char): const MovePrevIntent(),
          const CharacterActivator(FilterKeys.char): const FilterIntent(),
          const SingleActivator(TodayKeys.keyboardKey, control: true): const PlanTaskIntent(),
          const SingleActivator(TodayKeys.keyboardKey, control: true, shift: true): const PlanTaskTomorrowIntent(),
          const SingleActivator(AppKeyBindings.arrowDown): const MoveNextIntent(),
          const SingleActivator(AppKeyBindings.arrowUp): const MovePrevIntent(),
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
                ref.read(taskProvider.notifier).scheduleTasksForToday(List.from(_selectedTaskIds)).then((_) {
                  setState(() => _selectedTaskIds.clear());
                });
              } else {
                final taskId = _getFocusedTaskId();
                if (taskId != null) {
                  ref.read(taskProvider.notifier).scheduleTasksForToday([taskId]);
                }
              }
            }),
            PlanTaskTomorrowIntent: NonTypingAction<PlanTaskTomorrowIntent>((_) {
              if (_selectedTaskIds.isNotEmpty) {
                ref.read(taskProvider.notifier).scheduleTasksForTomorrow(List.from(_selectedTaskIds)).then((_) {
                  setState(() => _selectedTaskIds.clear());
                });
              } else {
                final taskId = _getFocusedTaskId();
                if (taskId != null) {
                  ref.read(taskProvider.notifier).scheduleTasksForTomorrow([taskId]);
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
                            icon: const Icon(Icons.casino_rounded),
                            tooltip: 'Give me a random task!',
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
                    FilterBar(
                      filter: ref.watch(filterProvider).filter,
                      isBypassed: ref.watch(filterProvider).isBypassed,
                      onFilterTap: () => _showFilterDialog(context),
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
                        final provider = ref.read(taskProvider);
                        final task = provider.unscheduledTasks.firstWhere((t) => t.id == _selectedTaskIds.first);
                        _showEditTask(context, task);
                      } else {
                        _showBulkEdit(context);
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
        if (value == 'import') {
          _showImportFromMD(context);
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

  void _showEditTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (_) => EditTaskDialog(task: task),
    );
  }

  void _showAddTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AddTaskDialog(),
    );
  }

  void _showImportFromMD(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const ImportFromMDDialog(),
    );
  }

  void _showFilterDialog(BuildContext context) async {
    final filterProviderVal = ref.read(filterProvider);
    final result = await showDialog<TaskFilter>(
      context: context,
      builder: (_) => FilterDialog(initialFilter: filterProviderVal.filter),
    );
    if (result != null) {
      ref.read(filterProvider.notifier).setFilter(result);
    }
  }

  void _showBulkEdit(BuildContext context) async {
    final result = await showDialog<BulkEditResult>(
      context: context,
      builder: (_) => BulkEditTasksDialog(taskIds: _selectedTaskIds),
    );

    if (result != null && context.mounted) {
      await ref.read(taskProvider.notifier).bulkUpdateTasks(
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
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        contentTextStyle: Theme.of(context).textTheme.bodyMedium,
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

  void _pickRandomTask(BuildContext context) async {
    final taskProviderVal = ref.read(taskProvider);
    final projectProviderVal = ref.read(projectProvider);
    final filter = ref.read(filterProvider).activeFilter;

    var availableTasks = taskProviderVal.unscheduledTasks.where((t) {
      final project = t.projectId != null ? projectProviderVal.getById(t.projectId!) : null;
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

    final randomTask = await ref.read(taskProvider.notifier).pickAndScheduleRandomTask(availableTasks);

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
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Great!'))],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TaskCard(
              task: randomTask,
              project: randomTask.projectId != null ? projectProviderVal.getById(randomTask.projectId!) : null,
              onToggle: (_) {},
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
