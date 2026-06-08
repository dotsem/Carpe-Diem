import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carpe_diem/core/utils/fuzzy_search_utils.dart';
import 'package:carpe_diem/features/common/presentation/widgets/fuzzy_search_bar.dart';

class ProjectPicker extends StatefulWidget {
  final List<Project> projects;
  final Function(String?) onChanged;
  final String? selectedProjectId;
  final MenuController? menuController;

  const ProjectPicker({
    super.key,
    this.selectedProjectId,
    required this.onChanged,
    required this.projects,
    this.menuController,
  });

  @override
  State<ProjectPicker> createState() => _ProjectPickerState();
}

class _ProjectPickerState extends State<ProjectPicker> {
  final MenuController _localMenuController = MenuController();
  MenuController get _menuController => widget.menuController ?? _localMenuController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  int _selectedIndex = -1;

  List<Project?> get _filteredProjects {
    final all = [null, ...widget.projects];
    if (_searchQuery.isEmpty) return all;

    return FuzzySearchUtils.search<Project?>(
      query: _searchQuery,
      items: all,
      itemToString: (project) => project?.name ?? 'No project',
      threshold: 0.3,
    );
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          setState(() {
            _selectedIndex = (_selectedIndex + 1) % _filteredProjects.length;
          });
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          setState(() {
            _selectedIndex = (_selectedIndex - 1 + _filteredProjects.length) % _filteredProjects.length;
          });
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (_selectedIndex >= 0 && _selectedIndex < _filteredProjects.length) {
            _onProjectSelected(_filteredProjects[_selectedIndex]);
            return KeyEventResult.handled;
          }
        }
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onProjectSelected(Project? project) {
    widget.onChanged(project?.id);
    _menuController.close();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.projects.isEmpty) {
      return InputDecorator(
        decoration: _inputDecoration().copyWith(hintText: 'No projects yet'),
        child: Text('No projects yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }

    final selectedProject = widget.selectedProjectId == null
        ? null
        : widget.projects.firstWhere((p) => p.id == widget.selectedProjectId, orElse: () => widget.projects.first);

    return MenuAnchor(
      controller: _menuController,
      onOpen: () {
        _searchFocusNode.requestFocus();
        setState(() => _selectedIndex = 0);
      },
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.surfaceContainerHigh),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 8),
                SizedBox(
                  height: 250,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _filteredProjects.isEmpty
                          ? [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: Text(
                                    'No results found',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                ),
                              ),
                            ]
                          : List.generate(_filteredProjects.length, (index) {
                              final project = _filteredProjects[index];
                              final isHighlighted = index == _selectedIndex;
                              return _buildProjectItem(project, isHighlighted, index);
                            }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: InputDecorator(
            decoration: _inputDecoration(),
            child: Row(
              children: [
                if (selectedProject != null) ...[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: selectedProject.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(selectedProject.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ] else
                  const Expanded(child: Text('No project', maxLines: 1, overflow: TextOverflow.ellipsis)),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return FuzzySearchBar(
      controller: _searchController,
      focusNode: _searchFocusNode,
      hintText: 'Search projects...',
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
          _selectedIndex = 0;
        });
      },
      onSubmitted: (_) {
        if (_selectedIndex >= 0 && _selectedIndex < _filteredProjects.length) {
          _onProjectSelected(_filteredProjects[_selectedIndex]);
        } else {
          _searchFocusNode.requestFocus();
        }
      },
    );
  }

  Widget _buildProjectItem(Project? project, bool isHighlighted, int index) {
    return InkWell(
      onTap: () => _onProjectSelected(project),
      onHover: (hovering) {
        if (hovering) setState(() => _selectedIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.accent.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (project == null)
              Icon(Icons.block, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)
            else
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: project.color, shape: BoxShape.circle),
              ),
            const SizedBox(width: 8),
            Text(
              project?.name ?? 'No project',
              style: TextStyle(
                color: isHighlighted ? AppColors.accent : Theme.of(context).colorScheme.onSurface,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return const InputDecoration(
      hintText: 'Project',
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
