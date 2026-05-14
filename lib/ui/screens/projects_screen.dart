import 'package:carpe_diem/data/models/task_filter.dart';
import 'package:carpe_diem/providers/settings_provider.dart';
import 'package:carpe_diem/ui/dialogs/filter_dialog.dart';
import 'package:carpe_diem/ui/widgets/filter_bar.dart';
import 'package:carpe_diem/ui/widgets/project_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:carpe_diem/ui/widgets/fuzzy_search_bar.dart';
import 'package:carpe_diem/ui/widgets/screen_header.dart';
import 'package:carpe_diem/ui/shortcuts/app_shortcuts.dart';
import 'package:flutter/services.dart';
import 'package:carpe_diem/ui/dialogs/add_project_dialog.dart';
import 'package:carpe_diem/providers/filter_provider.dart';

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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _archivedHeaderKey = GlobalKey();

  final Map<String, FocusNode> _itemFocusNodes = {};
  final List<String> _orderedItemIds = [];

  String _searchQuery = '';
  bool _temporarilyShowArchived = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectProvider>().loadProjects();
    });

    _searchFocusNode.onKeyEvent = (node, event) {
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
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mainFocusNode.dispose();
    for (final node in _itemFocusNodes.values) {
      node.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _moveFocus(int dx, int dy) {
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

  @override
  Widget build(BuildContext context) {
    return AppShortcutRegistrar(
      shortcuts: projectShortcutEntries,
      child: Shortcuts(
        shortcuts: {
          const CharacterActivator('/'): const _FocusSearchIntent(),
          const SingleActivator(LogicalKeyboardKey.escape): const _UnfocusSearchIntent(),
          const CharacterActivator('j'): const MoveNextIntent(),
          const CharacterActivator('k'): const MovePrevIntent(),
          const CharacterActivator('h'): const MoveLeftIntent(),
          const CharacterActivator('l'): const MoveRightIntent(),
          const CharacterActivator('f'): const FilterIntent(),
        },
        child: Actions(
          actions: {
            MoveNextIntent: NonTypingAction<MoveNextIntent>((_) {
              _moveFocus(0, 1);
            }),
            MovePrevIntent: NonTypingAction<MovePrevIntent>((_) {
              _moveFocus(0, -1);
            }),
            MoveLeftIntent: NonTypingAction<MoveLeftIntent>((_) {
              _moveFocus(-1, 0);
            }),
            MoveRightIntent: NonTypingAction<MoveRightIntent>((_) {
              _moveFocus(1, 0);
            }),
            FilterIntent: NonTypingAction<FilterIntent>((_) {
              _showFilterDialog(context);
            }),
            _FocusSearchIntent: NonTypingAction<_FocusSearchIntent>((_) {
              _searchFocusNode.requestFocus();
            }),
            _UnfocusSearchIntent: CallbackAction<_UnfocusSearchIntent>(
              onInvoke: (intent) {
                if (_searchFocusNode.hasFocus) {
                  _searchFocusNode.unfocus();
                  if (_orderedItemIds.isNotEmpty) {
                    _itemFocusNodes[_orderedItemIds.first]?.requestFocus();
                  } else {
                    _mainFocusNode.requestFocus();
                  }
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
                ScreenHeader(
                  title: 'Projects',
                  actions: [
                    FilledButton.icon(
                      onPressed: () => _showAddProject(context),
                      icon: Icon(Icons.add),
                      label: Text('New Project'),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: FuzzySearchBar(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    hintText: 'Search projects... (Press / to focus)',
                    onChanged: (value) => setState(() {
                      _searchQuery = value;
                    }),
                    onSubmitted: (_) {
                      if (_orderedItemIds.isNotEmpty) {
                        _itemFocusNodes[_orderedItemIds.first]?.requestFocus();
                      }
                    },
                  ),
                ),
                Consumer<FilterProvider>(
                  builder: (context, filterProvider, _) => FilterBar(
                    filter: filterProvider.filter,
                    isBypassed: filterProvider.isBypassed,
                    ignoreProjects: true,
                    onFilterTap: () => _showFilterDialog(context),
                    onClearFilter: () => filterProvider.clearFilter(),
                  ),
                ),
                Divider(height: 1),
                Expanded(child: _projectGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _projectGrid() {
    return Consumer<ProjectProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        final filteredBySearch = provider.projects.where((p) {
          if (_searchQuery.isEmpty) return true;
          final query = _searchQuery.toLowerCase();
          return p.name.toLowerCase().contains(query) || (p.description?.toLowerCase().contains(query) ?? false);
        }).toList();

        final filter = context.watch<FilterProvider>().activeFilter.limitTo(projects: false);
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
                SizedBox(height: 16),
                Text(
                  provider.projects.isEmpty ? 'No projects yet' : 'No projects match your filter',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
                ),
                SizedBox(height: 8),
                if (provider.projects.isEmpty)
                  TextButton(onPressed: () => _showAddProject(context), child: Text('Create your first project')),
              ],
            ),
          );
        }

        // Build ordered IDs list explicitly
        _orderedItemIds.clear();
        for (final p in activeProjects) {
          _orderedItemIds.add(p.id);
        }
        for (final p in inactiveProjects) {
          _orderedItemIds.add(p.id);
        }

        final settings = context.watch<SettingsProvider>();
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
                SizedBox(height: 16),
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
                    child: Text('Show archived projects'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddProject(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(value: context.read<ProjectProvider>(), child: AddProjectDialog()),
    );
  }

  void _showFilterDialog(BuildContext context) async {
    final filterProvider = context.read<FilterProvider>();
    final result = await showDialog<TaskFilter>(
      context: context,
      builder: (_) => FilterDialog(initialFilter: filterProvider.filter, showProjectFilter: false),
    );
    if (result != null) {
      filterProvider.setFilter(result);
    }
  }
}
