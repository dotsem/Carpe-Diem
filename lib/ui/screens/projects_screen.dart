import 'package:carpe_diem/data/models/task_filter.dart';
import 'package:carpe_diem/ui/dialogs/filter_dialog.dart';
import 'package:carpe_diem/ui/widgets/filter_bar.dart';
import 'package:carpe_diem/ui/widgets/project_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:carpe_diem/ui/widgets/fuzzy_search_bar.dart';
import 'package:carpe_diem/ui/shortcuts/app_shortcuts.dart';
import 'package:flutter/services.dart';
import 'package:carpe_diem/ui/dialogs/add_project_dialog.dart';

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _UnfocusSearchIntent extends Intent {
  const _UnfocusSearchIntent();
}

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _mainFocusNode = FocusNode();
  String _searchQuery = '';
  TaskFilter _filter = const TaskFilter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().loadProjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mainFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        const CharacterActivator('/'): const _FocusSearchIntent(),
        const SingleActivator(LogicalKeyboardKey.escape): const _UnfocusSearchIntent(),
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
        },
        child: Focus(
          focusNode: _mainFocusNode,
          autofocus: true,
          debugLabel: 'ProjectsScreenMainFocus',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: FuzzySearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  hintText: 'Search projects... (Press / to focus)',
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              FilterBar(
                filter: _filter,
                onFilterTap: () => _showFilterDialog(context),
                onClearFilter: () => setState(() => _filter = const TaskFilter()),
              ),
              const Divider(height: 1),
              Expanded(child: _projectGrid()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Text('Projects', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => _showAddProject(context),
            icon: const Icon(Icons.add),
            label: const Text('New Project'),
          ),
        ],
      ),
    );
  }

  Widget _projectGrid() {
    return Consumer<ProjectProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredBySearch = provider.projects.where((p) {
          if (_searchQuery.isEmpty) return true;
          final query = _searchQuery.toLowerCase();
          return p.name.toLowerCase().contains(query) || (p.description?.toLowerCase().contains(query) ?? false);
        }).toList();

        final filteredProjects = filteredBySearch.where((p) => _filter.applyToProject(p)).toList();
        final activeProjects = filteredProjects.where((p) => p.isActive).toList();
        final inactiveProjects = filteredProjects.where((p) => !p.isActive).toList();

        if (filteredProjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_open, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  provider.projects.isEmpty ? 'No projects yet' : 'No projects match your filter',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (provider.projects.isEmpty)
                  TextButton(onPressed: () => _showAddProject(context), child: const Text('Create your first project')),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: ListView(
            scrollDirection: Axis.vertical,
            children: [
              if (activeProjects.isNotEmpty)
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: activeProjects
                      .map((p) => ProjectCard(project: p, onTap: () => context.go('/projects/${p.id}')))
                      .toList(),
                ),
              if (inactiveProjects.isNotEmpty) ...[
                const SizedBox(height: 48),
                Text(
                  'ARCHIVED',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: inactiveProjects
                      .map((p) => ProjectCard(project: p, onTap: () => context.go('/projects/${p.id}')))
                      .toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showAddProject(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          ChangeNotifierProvider.value(value: context.read<ProjectProvider>(), child: const AddProjectDialog()),
    );
  }

  void _showFilterDialog(BuildContext context) async {
    final result = await showDialog<TaskFilter>(
      context: context,
      builder: (_) => FilterDialog(initialFilter: _filter, showProjectFilter: false),
    );
    if (result != null) {
      setState(() => _filter = result);
    }
  }
}
