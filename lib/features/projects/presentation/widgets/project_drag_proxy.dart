import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_card.dart';
import 'package:flutter/material.dart';

class ProjectDragProxy extends StatelessWidget {
  final Project project;

  const ProjectDragProxy({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: 0.85,
        child: SizedBox(
          width: 240,
          child: IgnorePointer(child: ProjectCard(project: project)),
        ),
      ),
    );
  }
}
