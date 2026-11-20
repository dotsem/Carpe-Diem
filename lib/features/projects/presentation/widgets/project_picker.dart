import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/flutter_ext/searchable_dropdown/searchable_dropdown.dart';
import 'package:flutter/material.dart';

class ProjectPicker extends StatelessWidget {
  final List<Project> projects;
  final void Function(String?) onChanged;
  final String? selectedProjectId;
  final MenuController? menuController;
  final bool borderless;

  const ProjectPicker({
    required this.onChanged,
    required this.projects,
    super.key,
    this.selectedProjectId,
    this.menuController,
    this.borderless = false,
  });

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return InputDecorator(
        decoration: const InputDecoration(
          hintText: 'No projects yet',
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: Text(
          'No projects yet',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final selectedProject =
        selectedProjectId == null || selectedProjectId!.isEmpty
        ? null
        : projects.where((p) => p.id == selectedProjectId).firstOrNull;

    return SearchableDropdown<Project>(
      borderless: borderless,
      menuController: menuController,
      items: projects,
      selectedItem: selectedProject,
      onChanged: (project) => onChanged(project?.id),
      nameGetter: (p) => p?.name ?? 'No project',
      hintText: 'Project',
      searchHint: 'Search projects...',
      emptyText: 'No results found',
      leadingBuilder: (p) => p == null
          ? Icon(
              Icons.block,
              size: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )
          : Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
            ),
    );
  }
}
