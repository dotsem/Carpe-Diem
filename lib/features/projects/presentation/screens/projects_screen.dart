import 'package:carpe_diem/features/common/data/models/task_filter.dart';
import 'package:carpe_diem/features/common/presentation/widgets/filter_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/fuzzy_search_bar.dart';
import 'package:carpe_diem/features/common/presentation/widgets/screen_header.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:flutter/services.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/add_project_dialog.dart';
import 'package:carpe_diem/features/common/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_grid.dart';

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _UnfocusSearchIntent extends Intent {
  const _UnfocusSearchIntent();
}

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _mainFocusNode = FocusNode();
  final GlobalKey<ProjectGridState> _gridKey = GlobalKey<ProjectGridState>();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectProvider.notifier).loadProjects();
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
              _gridKey.currentState?.moveFocus(0, 1);
            }),
            MovePrevIntent: NonTypingAction<MovePrevIntent>((_) {
              _gridKey.currentState?.moveFocus(0, -1);
            }),
            MoveLeftIntent: NonTypingAction<MoveLeftIntent>((_) {
              _gridKey.currentState?.moveFocus(-1, 0);
            }),
            MoveRightIntent: NonTypingAction<MoveRightIntent>((_) {
              _gridKey.currentState?.moveFocus(1, 0);
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
                  _gridKey.currentState?.requestFirstItemFocus();
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
                      icon: const Icon(Icons.add),
                      label: const Text('New Project'),
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
                      _gridKey.currentState?.requestFirstItemFocus();
                    },
                  ),
                ),
                () {
                  final filterState = ref.watch(filterProvider);
                  return FilterBar(
                    filter: filterState.filter,
                    isBypassed: filterState.isBypassed,
                    ignoreProjects: true,
                    onFilterTap: () => _showFilterDialog(context),
                    onClearFilter: () => ref.read(filterProvider.notifier).clearFilter(),
                  );
                }(),
                const Divider(height: 1),
                Expanded(
                  child: ProjectGrid(
                    key: _gridKey,
                    searchQuery: _searchQuery,
                    searchFocusNode: _searchFocusNode,
                    mainFocusNode: _mainFocusNode,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddProject(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AddProjectDialog(),
    );
  }

  void _showFilterDialog(BuildContext context) async {
    final filterNotifier = ref.read(filterProvider.notifier);
    final result = await showDialog<TaskFilter>(
      context: context,
      builder: (_) => FilterDialog(initialFilter: ref.read(filterProvider).filter, showProjectFilter: false),
    );
    if (result != null) {
      filterNotifier.setFilter(result);
    }
  }
}
