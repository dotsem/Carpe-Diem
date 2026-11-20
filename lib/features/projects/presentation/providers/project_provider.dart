import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class ProjectState {
  final List<Project> projects;
  final bool isLoading;

  const ProjectState({this.projects = const [], this.isLoading = false});

  ProjectState copyWith({List<Project>? projects, bool? isLoading}) {
    return ProjectState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Project? getById(String id) {
    return projects.where((p) => p.id == id).firstOrNull;
  }
}

class ProjectNotifier extends Notifier<ProjectState> {
  late final IProjectRepository _repo;
  final _uuid = const Uuid();

  @override
  ProjectState build() {
    _repo = ref.watch(projectRepositoryProvider);

    ref.listen<UndoRedoState>(undoRedoProvider, (previous, next) {
      if (previous != null && previous.isProcessing && !next.isProcessing) {
        if (next.lastOperationType == UndoRedoOperationType.undo ||
            next.lastOperationType == UndoRedoOperationType.redo) {
          loadProjects();
        }
      }
    });

    return const ProjectState();
  }

  Future<void> loadProjects() async {
    // Why: only show the spinner on first load, refreshes must not tear down the grid
    if (state.projects.isEmpty) state = state.copyWith(isLoading: true);
    final projects = await _repo.getAll();
    state = ProjectState(projects: projects);
  }

  Future<void> addProject({
    required String name,
    required Color color,
    String? description,
    bool isUrgent = false,
    List<String> labelIds = const [],
    DateTime? deadline,
  }) async {
    final project = Project(
      id: _uuid.v4(),
      name: name,
      description: description,
      color: color,
      isUrgent: isUrgent,
      labelIds: labelIds,
      deadline: deadline,
      createdAt: DateTime.now(),
    );
    await ref
        .read(undoRedoProvider.notifier)
        .execute(
          CreateCommand(
            repo: _repo,
            item: project,
            id: project.id,
            displayName: project.name,
          ),
        );
    await loadProjects();
  }

  Future<void> reorderProject(Project project, String newSortOrder) async {
    if (project.sortOrder == newSortOrder) return;

    final updated = project.copyWith(sortOrder: newSortOrder);

    final currentProjects = state.projects.map((p) {
      return p.id == project.id ? updated : p;
    }).toList()..sort((a, b) => a.compareTo(b));
    state = state.copyWith(projects: currentProjects);

    final oldProject = await _repo.getById(project.id);
    if (oldProject == null) return;

    await ref
        .read(undoRedoProvider.notifier)
        .execute(
          UpdateCommand(
            repo: _repo,
            previous: oldProject,
            next: updated,
            displayName: oldProject.name,
            customDescription: 'Reorder project: "${oldProject.name}"',
          ),
        );
    await loadProjects();
  }

  Future<void> updateProject(Project project) async {
    final oldProject = await _repo.getById(project.id);
    if (oldProject == null) return;
    await ref
        .read(undoRedoProvider.notifier)
        .execute(
          UpdateCommand(
            repo: _repo,
            previous: oldProject,
            next: project,
            displayName: project.name,
          ),
        );
    await loadProjects();
  }

  Future<void> deleteProject(Project project) async {
    await ref
        .read(undoRedoProvider.notifier)
        .execute(
          DeleteCommand(
            repo: _repo,
            item: project,
            id: project.id,
            displayName: project.name,
          ),
        );
    ref.read(filterProvider.notifier).removeProjectFilter(project.id);
    await loadProjects();
  }

  Future<void> toggleProjectActive(Project project) async {
    final updated = project.copyWith(isActive: !project.isActive);
    await updateProject(updated);
  }

  Project? getById(String id) {
    return state.projects.where((p) => p.id == id).firstOrNull;
  }

  List<Label> getLabels(Project project, LabelState labelState) {
    return project.labelIds
        .map((id) {
          return labelState.labels.where((l) => l.id == id).firstOrNull;
        })
        .whereType<Label>()
        .toList();
  }
}

final projectProvider = NotifierProvider<ProjectNotifier, ProjectState>(() {
  return ProjectNotifier();
});

final filteredProjectsProvider = Provider<List<Project>>((ref) {
  final projects = ref.watch(projectProvider).projects;
  final filter = ref
      .watch(filterProvider)
      .activeFilter
      .limitTo(projects: false);

  return projects.where(filter.applyToProject).toList();
});

final activeFilteredProjectsProvider = Provider<List<Project>>((ref) {
  return ref.watch(filteredProjectsProvider).where((p) => p.isActive).toList();
});
