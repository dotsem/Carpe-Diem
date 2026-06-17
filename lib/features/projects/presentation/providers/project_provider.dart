import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';

class ProjectState {
  final List<Project> projects;
  final bool isLoading;

  const ProjectState({this.projects = const [], this.isLoading = false});

  ProjectState copyWith({List<Project>? projects, bool? isLoading}) {
    return ProjectState(projects: projects ?? this.projects, isLoading: isLoading ?? this.isLoading);
  }

  Project? getById(String id) {
    try {
      return projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
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
    state = state.copyWith(isLoading: true);
    final projects = await _repo.getAll();
    state = ProjectState(projects: projects, isLoading: false);
  }

  Future<void> addProject({
    required String name,
    String? description,
    required Color color,
    Priority priority = Priority.none,
    List<String> labelIds = const [],
    DateTime? deadline,
  }) async {
    final project = Project(
      id: _uuid.v4(),
      name: name,
      description: description,
      color: color,
      priority: priority,
      labelIds: labelIds,
      deadline: deadline,
      createdAt: DateTime.now(),
    );
    await ref
        .read(undoRedoProvider.notifier)
        .execute(CreateCommand(repo: _repo, item: project, id: project.id, displayName: project.name));
    await loadProjects();
  }

  Future<void> updateProject(Project project) async {
    final oldProject = await _repo.getById(project.id);
    if (oldProject == null) return;
    await ref
        .read(undoRedoProvider.notifier)
        .execute(UpdateCommand(repo: _repo, previous: oldProject, next: project, displayName: project.name));
    await loadProjects();
  }

  Future<void> deleteProject(Project project) async {
    await ref
        .read(undoRedoProvider.notifier)
        .execute(DeleteCommand(repo: _repo, item: project, id: project.id, displayName: project.name));
    ref.read(filterProvider.notifier).removeProjectFilter(project.id);
    await ref.read(settingsProvider.notifier).setPersistentFilterValues(ref.read(filterProvider).filter.toMap());
    await loadProjects();
  }

  Future<void> toggleProjectActive(Project project) async {
    final updated = project.copyWith(isActive: !project.isActive);
    await updateProject(updated);
  }

  Project? getById(String id) {
    try {
      return state.projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Label> getLabels(Project project, LabelState labelState) {
    return project.labelIds
        .map((id) {
          try {
            return labelState.labels.firstWhere((l) => l.id == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<Label>()
        .toList();
  }
}

final projectProvider = NotifierProvider<ProjectNotifier, ProjectState>(() {
  return ProjectNotifier();
});
