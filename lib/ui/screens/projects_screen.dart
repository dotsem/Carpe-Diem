import 'package:carpe_diem/data/models/project.dart';
import 'package:carpe_diem/data/models/task_filter.dart';
import 'package:carpe_diem/ui/dialogs/edit_project_dialog.dart';
import 'package:carpe_diem/ui/dialogs/filter_dialog.dart';
import 'package:carpe_diem/ui/widgets/filter_bar.dart';
import 'package:carpe_diem/ui/widgets/project_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:carpe_diem/ui/dialogs/add_project_dialog.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  TaskFilter _filter = const TaskFilter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context),
        FilterBar(
          filter: _filter,
          onFilterTap: () => _showFilterDialog(context),
          onClearFilter: () => setState(() => _filter = const TaskFilter()),
        ),
        const Divider(height: 1),
        Expanded(child: _projectGrid()),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 16),
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

        final projects = provider.projects.where((p) => _filter.applyToProject(p)).toList();

        if (projects.isEmpty) {
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
          padding: const EdgeInsets.all(32),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: projects
                .map((p) => ProjectCard(project: p, onTap: () => context.go('/projects/${p.id}')))
                .toList(),
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

  void _showEditProject(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ProjectProvider>(),
        child: EditProjectDialog(project: project),
      ),
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
