import 'package:carpe_diem/core/utils/project_reorder_utils.dart';
import 'package:carpe_diem/features/common/presentation/widgets/platform_draggable.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_card.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_card_placeholder.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_drag_proxy.dart';
import 'package:flutter/material.dart';

class ProjectGridSection extends StatefulWidget {
  final List<Project> projects;
  final Map<String, FocusNode> itemFocusNodes;
  final ValueChanged<String> onProjectTap;
  final void Function(Project project, String newSortOrder) onReorder;

  const ProjectGridSection({
    super.key,
    required this.projects,
    required this.itemFocusNodes,
    required this.onProjectTap,
    required this.onReorder,
  });

  @override
  State<ProjectGridSection> createState() => _ProjectGridSectionState();
}

class _ProjectGridSectionState extends State<ProjectGridSection> {
  Project? _draggedProject;
  int? _hoverIndex;

  void _handleDrop(Project project, int targetIndex) {
    final newSortOrder = ProjectReorderUtils.handleReorder(
      projects: widget.projects,
      draggedProject: project,
      newIndex: targetIndex,
    );

    setState(() {
      _draggedProject = null;
      _hoverIndex = null;
    });

    if (newSortOrder != null && newSortOrder != project.sortOrder) {
      widget.onReorder(project, newSortOrder);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.projects.isEmpty) return const SizedBox.shrink();

    final isDragging = _draggedProject != null;

    if (!isDragging) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: widget.projects.map((p) {
          final focusNode = widget.itemFocusNodes.putIfAbsent(
            p.id,
            () => FocusNode(debugLabel: 'Project_${p.id}'),
          );
          final cardWidget = ProjectCard(
            project: p,
            focusNode: focusNode,
            onTap: () => widget.onProjectTap(p.id),
          );
          return PlatformDraggable<Project>(
            data: p,
            feedback: ProjectDragProxy(project: p),
            childWhenDragging: Opacity(opacity: 0.3, child: cardWidget),
            onDragStarted: () {
              final idx = widget.projects.indexWhere((item) => item.id == p.id);
              setState(() {
                _draggedProject = p;
                _hoverIndex = idx >= 0 ? idx : 0;
              });
            },
            onDragEnd: (_) {
              if (mounted) {
                setState(() {
                  _draggedProject = null;
                  _hoverIndex = null;
                });
              }
            },
            child: cardWidget,
          );
        }).toList(),
      );
    }

    final dragged = _draggedProject!;
    final oldIndex = widget.projects.indexWhere((p) => p.id == dragged.id);
    final remainingProjects = widget.projects
        .where((p) => p.id != dragged.id)
        .toList();

    final totalSlots = widget.projects.length;
    final clampedHover = (_hoverIndex ?? oldIndex).clamp(0, totalSlots - 1);

    final List<Widget> gridItems = [];

    for (int slot = 0; slot < totalSlots; slot++) {
      final slotIndex = slot;

      if (slot == clampedHover) {
        gridItems.add(
          DragTarget<Project>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (details) {
              _handleDrop(details.data, slotIndex);
            },
            builder: (context, candidateData, rejectedData) {
              return const ProjectCardPlaceholder();
            },
          ),
        );
      } else {
        final remainingIdx = slot < clampedHover ? slot : slot - 1;
        final p =
            remainingProjects[remainingIdx.clamp(
              0,
              remainingProjects.length - 1,
            )];
        final focusNode = widget.itemFocusNodes.putIfAbsent(
          p.id,
          () => FocusNode(debugLabel: 'Project_${p.id}'),
        );
        final cardWidget = ProjectCard(
          project: p,
          focusNode: focusNode,
          onTap: () => widget.onProjectTap(p.id),
        );

        gridItems.add(
          DragTarget<Project>(
            onWillAcceptWithDetails: (_) {
              if (_hoverIndex != slotIndex) {
                setState(() => _hoverIndex = slotIndex);
              }
              return true;
            },
            onAcceptWithDetails: (details) {
              _handleDrop(details.data, slotIndex);
            },
            builder: (context, candidateData, rejectedData) {
              return Opacity(opacity: 0.8, child: cardWidget);
            },
          ),
        );
      }
    }

    return Wrap(spacing: 16, runSpacing: 16, children: gridItems);
  }
}
