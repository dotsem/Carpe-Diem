import 'package:carpe_diem/data/models/task.dart';
import 'package:carpe_diem/data/models/task_filter.dart';
import 'package:carpe_diem/ui/dialogs/add_task_dialog.dart';
import 'package:carpe_diem/ui/dialogs/filter_dialog.dart';
import 'package:carpe_diem/ui/dialogs/import_from_md_dialog.dart';
import 'package:carpe_diem/ui/widgets/context_menu/backlog_context_menu.dart';
import 'package:carpe_diem/ui/widgets/filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/providers/task_provider.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:carpe_diem/ui/widgets/task_card.dart';
import 'package:carpe_diem/core/utils/fuzzy_search_utils.dart';
import 'package:carpe_diem/ui/widgets/fuzzy_search_bar.dart';
import 'package:carpe_diem/ui/shortcuts/app_shortcuts.dart';
import 'package:flutter/services.dart';

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _UnfocusSearchIntent extends Intent {
  const _UnfocusSearchIntent();
}

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  TaskFilter _filter = const TaskFilter();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadUnscheduledTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        const CharacterActivator('s'): const _FocusSearchIntent(),
        const CharacterActivator('/'): const _FocusSearchIntent(),
        const CharacterActivator('S'): const _FocusSearchIntent(),
        const SingleActivator(LogicalKeyboardKey.escape): const _UnfocusSearchIntent(),
      },
      child: Actions(
        actions: {
          _FocusSearchIntent: NonTypingAction<_FocusSearchIntent>((_) {
            _searchFocusNode.requestFocus();
          }),
          _UnfocusSearchIntent: CallbackAction<_UnfocusSearchIntent>(
            onInvoke: (_) {
              if (_searchFocusNode.hasFocus) {
                _searchFocusNode.unfocus();
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              FilterBar(
                filter: _filter,
                onFilterTap: () => _showFilterDialog(context),
                onClearFilter: () => setState(() => _filter = const TaskFilter()),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: FuzzySearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  hintText: 'Search backlog tasks... (Press s or / to focus)',
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _taskList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Backlog', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Tasks without a scheduled date', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          FilledButton.icon(onPressed: () => _showImportFromMD(context), label: const Text('Import from MD')),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => _showAddTask(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  Widget _taskList() {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final projectProvider = context.read<ProjectProvider>();
        var allTasks = provider.unscheduledTasks.where((t) {
          final project = t.projectId != null ? projectProvider.getById(t.projectId!) : null;
          return _filter.applyToTask(t, project?.labelIds ?? []);
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inbox_rounded, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                const Text('No backlog tasks', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 8),
                TextButton(onPressed: () => _showAddTask(context), child: const Text('Add a task')),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
          children: [
            ...activeTasks.asMap().entries.map(
              (entry) => TaskCard(
                autofocus: entry.key == 0,
                task: entry.value,
                project: entry.value.projectId != null ? projectProvider.getById(entry.value.projectId!) : null,
                onToggle: () => provider.toggleComplete(entry.value),
                onTap: () {},
                onContextMenu: (localPosition, renderBox) =>
                    showBacklogContextMenu(context, entry.value, localPosition, renderBox),
                trailing: _taskTrailing(context, entry.value),
              ),
            ),
            if (completedTasks.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Completed',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              ...completedTasks.map(
                (task) => TaskCard(
                  task: task,
                  project: task.projectId != null ? projectProvider.getById(task.projectId!) : null,
                  onToggle: () => provider.toggleComplete(task),
                  onTap: () {},
                  onContextMenu: (localPosition, renderBox) =>
                      showBacklogContextMenu(context, task, localPosition, renderBox),
                  trailing: _taskTrailing(context, task),
                ),
              ),
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
              icon: const Icon(Icons.more_vert, size: 18),
              color: AppColors.textSecondary,
              onPressed: () {
                final RenderBox renderBox = buttonContext.findRenderObject() as RenderBox;
                const localPosition = Offset.zero;
                showBacklogContextMenu(context, task, localPosition, renderBox);
              },
            );
          },
        ),
      ],
    );
  }

  void _showAddTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TaskProvider>(),
        child: ChangeNotifierProvider.value(value: context.read<ProjectProvider>(), child: const AddTaskDialog()),
      ),
    );
  }

  void _showImportFromMD(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TaskProvider>(),
        child: ChangeNotifierProvider.value(value: context.read<ProjectProvider>(), child: const ImportFromMDDialog()),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) async {
    final result = await showDialog<TaskFilter>(
      context: context,
      builder: (_) => FilterDialog(initialFilter: _filter),
    );
    if (result != null) {
      setState(() => _filter = result);
    }
  }
}
