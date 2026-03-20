import 'package:carpe_diem/data/models/label.dart';
import 'package:carpe_diem/providers/label_provider.dart';
import 'package:carpe_diem/ui/widgets/chip/chip.dart';
import 'package:carpe_diem/ui/widgets/chip/label_chip.dart';
import 'package:go_router/go_router.dart';
import 'package:carpe_diem/ui/widgets/context_menu/backlog_context_menu.dart';
import 'package:carpe_diem/ui/widgets/context_menu/task_card_context_menu.dart';
import 'package:carpe_diem/ui/dialogs/edit_task_dialog.dart';
import 'package:carpe_diem/ui/dialogs/bulk_edit_tasks_dialog.dart';
import 'package:carpe_diem/ui/widgets/bulk_action_menu.dart';
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
import 'package:carpe_diem/ui/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/core/utils/toast_utils.dart';

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

  @override
  void initState() {
    super.initState();
    _taskProvider = context.read<TaskProvider>();
    _loadTasks();
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        final project = projectProvider.getById(widget.projectId);

        if (project == null) {
          return const Center(
            child: Text("Project not found", style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        return Shortcuts(
          shortcuts: {
            const CharacterActivator('/'): const _FocusSearchIntent(),
            const CharacterActivator('s'): const _FocusSearchIntent(),
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
              debugLabel: 'ProjectDetailScreenMainFocus',
              child: Scaffold(
                backgroundColor: AppColors.background,
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(context, project),
                    const Divider(color: AppColors.surfaceLight, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: FuzzySearchBar(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        hintText: 'Search backlog tasks... (Press s or / to focus)',
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ),
                    const Divider(color: AppColors.surfaceLight, height: 1),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : TaskListView(
                              tasks: _tasks,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              onContextMenu: (ctx, task, pos, box) {
                                if (task.scheduledDate != null) {
                                  showTaskCardContextMenu(ctx, task, pos, box);
                                } else {
                                  showBacklogContextMenu(ctx, task, pos, box);
                                }
                              },
                              trailingBuilder: (ctx, task) => _taskTrailing(ctx, task),
                              emptyPlaceholder: const Center(
                                child: Text(
                                  "No tasks in this project",
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                              searchQuery: _searchQuery,
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
                            ),
                    ),
                  ],
                ),
                floatingActionButton: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black, blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: () => _showAddTask(context),
                    backgroundColor: project.color,
                    elevation: 0,
                    highlightElevation: 0,
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
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
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.text),
                        ),
                      ),
                      if (_selectedTaskIds.isEmpty) ...[
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                          onPressed: () => _showEditProject(context, project),
                          tooltip: 'Edit Project',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: () => _showDeleteProject(context, project),
                          tooltip: 'Delete Project',
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: AppColors.text,
                          ),
                          onPressed: () {
                            context.read<TaskProvider>().scheduleTasksForToday(_selectedTaskIds).then((_) {
                              setState(() => _selectedTaskIds.clear());
                            });
                          },
                          label: const Text('Plan for today'),
                          icon: const Icon(Icons.calendar_today_rounded),
                        ),
                        const SizedBox(width: 8),
                      ],
                      BulkActionMenu(
                        options: [
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
                          if (value == 'edit') {
                            _showBulkEdit(context);
                          } else if (value == 'delete') {
                            _showBulkDeleteConfirm(context);
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
                  const SizedBox(height: 16),
                  // TODO: add expand button
                  Text(
                    project.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5),
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
              icon: const Icon(Icons.more_vert, size: 18),
              color: AppColors.textSecondary,
              onPressed: () {
                final RenderBox renderBox = buttonContext.findRenderObject() as RenderBox;
                const localPosition = Offset.zero;
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
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete ${_selectedTaskIds.length} tasks?'),
        backgroundColor: AppColors.surfaceLight,
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
}
