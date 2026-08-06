import 'package:carpe_diem/features/common/presentation/widgets/section_card.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_picker.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/widgets/blocker_picker.dart';
import 'package:flutter/material.dart';

class ProjectsAndBlockersSection extends StatelessWidget {
  final List<Project> projects;
  final List<Task> availableTasks;
  final dynamic Function(String?) onChangedProject;
  final dynamic Function(String?) onChangedBlockers;
  final String? currentTaskId;
  final String? selectedBlockerId;
  final String? selectedProjectId;
  final MenuController? projectMenuController;
  final MenuController? blockerMenuController;

  const ProjectsAndBlockersSection({
    super.key,
    required this.projects,
    required this.onChangedProject,
    required this.availableTasks,
    required this.onChangedBlockers,
    required this.currentTaskId,
    required this.selectedBlockerId,
    required this.selectedProjectId,
    this.projectMenuController,
    this.blockerMenuController,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      margin: const EdgeInsets.symmetric(vertical: 8),
      items: [
        SectionItem(
          icon: Icons.folder,
          title: "Projects",
          child: ProjectPicker(
            borderless: true,
            onChanged: onChangedProject,
            projects: projects,
            menuController: projectMenuController,
            selectedProjectId: selectedProjectId,
          ),
        ),
        SectionItem(
          icon: Icons.block,
          title: "Blockers",
          child: BlockerPicker(
            borderless: true,
            availableTasks: availableTasks,
            onChanged: onChangedBlockers,
            currentTaskId: currentTaskId,
            selectedBlockerId: selectedBlockerId,
            menuController: blockerMenuController,
          ),
        ),
      ],
    );
  }
}
