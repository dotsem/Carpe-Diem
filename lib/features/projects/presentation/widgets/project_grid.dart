import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_card.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/dialogs/add_project_dialog.dart';

class ProjectGrid extends ConsumerStatefulWidget {
  final String searchQuery;
  final FocusNode searchFocusNode;
  final FocusNode mainFocusNode;

  const ProjectGrid({super.key, required this.searchQuery, required this.searchFocusNode, required this.mainFocusNode});

  @override
  ConsumerState<ProjectGrid> createState() => ProjectGridState();
}

class ProjectGridState extends ConsumerState<ProjectGrid> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _archivedHeaderKey = GlobalKey();
  final Map<String, FocusNode> _itemFocusNodes = {};
  final List<String> _orderedItemIds = [];
  bool _temporarilyShowArchived = false;

  @override
  void initState() {
    super.initState();
    widget.searchFocusNode.onKeyEvent = (node, event) {
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
    for (final node in _itemFocusNodes.values) {
      node.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void requestFirstItemFocus() {
    if (_orderedItemIds.isNotEmpty) {
      _itemFocusNodes[_orderedItemIds.first]?.requestFocus();
    } else {
      widget.mainFocusNode.requestFocus();
    }
  }

  void moveFocus(int dx, int dy) {
    if (_orderedItemIds.isEmpty) return;

    String? currentId;
    FocusNode? currentNode;
    for (var entry in _itemFocusNodes.entries) {
      if (entry.value.hasFocus) {
        currentId = entry.key;
        currentNode = entry.value;
        break;
      }
    }

    if (currentNode == null || currentNode.context == null) {
      final targetIndex = (dx + dy) > 0 ? 0 : _orderedItemIds.length - 1;
      final id = _orderedItemIds[targetIndex];
      _itemFocusNodes.putIfAbsent(id, () => FocusNode(debugLabel: 'Project_$id')).requestFocus();
      return;
    }

    final currentBox = currentNode.context!.findRenderObject() as RenderBox;
    final currentCenter = currentBox.localToGlobal(currentBox.size.center(Offset.zero));

    String? bestId;
    double bestScore = double.infinity;

    for (final id in _orderedItemIds) {
      if (id == currentId) continue;
      final node = _itemFocusNodes[id];
      if (node == null || node.context == null) continue;

      final box = node.context!.findRenderObject() as RenderBox;
      final center = box.localToGlobal(box.size.center(Offset.zero));
      final diff = center - currentCenter;

      bool inDirection = false;
      if (dx > 0) {
        inDirection = diff.dx > 20;
      } else if (dx < 0) {
        inDirection = diff.dx < -20;
      } else if (dy > 0) {
        inDirection = diff.dy > 20;
      } else if (dy < 0) {
        inDirection = diff.dy < -20;
      }

      if (inDirection) {
        double score = diff.distanceSquared;
        if (dx != 0) score += diff.dy.abs() * 5000;
        if (dy != 0) score += diff.dx.abs() * 5000;

        if (score < bestScore) {
          bestScore = score;
          bestId = id;
        }
      }
    }

    if (bestId != null) {
      _itemFocusNodes[bestId]?.requestFocus();
    }
  }

  void _showAddProject(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddProjectDialog());
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(projectProvider);
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredBySearch = provider.projects.where((p) {
      if (widget.searchQuery.isEmpty) return true;
      final query = widget.searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(query) || (p.description?.toLowerCase().contains(query) ?? false);
    }).toList();

    final filter = ref.watch(filterProvider).activeFilter.limitTo(projects: false);
    final filteredProjects = filteredBySearch.where((p) => filter.applyToProject(p)).toList();
    final activeProjects = filteredProjects.where((p) => p.isActive).toList();
    final inactiveProjects = filteredProjects.where((p) => !p.isActive).toList();

    if (filteredProjects.isEmpty) {
      _orderedItemIds.clear();
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              provider.projects.isEmpty ? 'No projects yet' : 'No projects match your filter',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (provider.projects.isEmpty)
              TextButton(onPressed: () => _showAddProject(context), child: const Text('Create your first project')),
          ],
        ),
      );
    }

    _orderedItemIds.clear();
    for (final p in activeProjects) {
      _orderedItemIds.add(p.id);
    }
    for (final p in inactiveProjects) {
      _orderedItemIds.add(p.id);
    }

    final settings = ref.watch(settingsProvider);
    final showActiveOnly = settings.showActiveProjectsOnly;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.vertical,
        children: [
          if (activeProjects.isNotEmpty)
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: activeProjects.map((p) {
                final focusNode = _itemFocusNodes.putIfAbsent(p.id, () => FocusNode(debugLabel: 'Project_${p.id}'));
                return ProjectCard(project: p, focusNode: focusNode, onTap: () => context.go('/projects/${p.id}'));
              }).toList(),
            ),
          if ((!showActiveOnly || _temporarilyShowArchived) && inactiveProjects.isNotEmpty) ...[
            const SizedBox(height: 48),
            Text(
              'ARCHIVED',
              key: _archivedHeaderKey,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: inactiveProjects.map((p) {
                final focusNode = _itemFocusNodes.putIfAbsent(p.id, () => FocusNode(debugLabel: 'Project_${p.id}'));
                return ProjectCard(project: p, focusNode: focusNode, onTap: () => context.go('/projects/${p.id}'));
              }).toList(),
            ),
          ],
          if (showActiveOnly && !_temporarilyShowArchived && inactiveProjects.isNotEmpty)
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() => _temporarilyShowArchived = true);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_archivedHeaderKey.currentContext != null) {
                      Scrollable.ensureVisible(
                        _archivedHeaderKey.currentContext!,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  });
                },
                child: const Text('Show archived projects'),
              ),
            ),
        ],
      ),
    );
  }
}
