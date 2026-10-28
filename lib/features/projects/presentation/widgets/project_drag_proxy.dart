import 'package:carpe_diem/features/common/presentation/widgets/swinging_drag_proxy.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_card.dart';
import 'package:flutter/material.dart';

class ProjectDragProxy extends StatelessWidget {
  final Project project;
  final double width;

  const ProjectDragProxy({
    super.key,
    required this.project,
    this.width = 240.0,
  });

  @override
  Widget build(BuildContext context) {
    return SwingingDragProxy(
      width: width,
      child: Material(
        color: Colors.transparent,
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: 0.85,
          child: SizedBox(
            width: width,
            child: IgnorePointer(child: ProjectCard(project: project)),
          ),
        ),
      ),
    );
  }
}
