import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';

class LabelState {
  final List<Label> labels;
  final bool isLoading;

  const LabelState({this.labels = const [], this.isLoading = false});

  LabelState copyWith({List<Label>? labels, bool? isLoading}) {
    return LabelState(labels: labels ?? this.labels, isLoading: isLoading ?? this.isLoading);
  }

  Label? getById(String? id) {
    if (id == null) return null;
    try {
      return labels.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }
}

class LabelNotifier extends Notifier<LabelState> {
  late final ILabelRepository _repo;
  final _uuid = const Uuid();

  @override
  LabelState build() {
    _repo = ref.watch(labelRepositoryProvider);

    ref.listen<UndoRedoState>(undoRedoProvider, (previous, next) {
      if (previous != null && previous.isProcessing && !next.isProcessing) {
        if (next.lastOperationType == UndoRedoOperationType.undo ||
            next.lastOperationType == UndoRedoOperationType.redo) {
          loadLabels();
        }
      }
    });

    return const LabelState();
  }

  Future<void> loadLabels() async {
    state = state.copyWith(isLoading: true);
    final labels = await _repo.getAll();
    state = LabelState(labels: labels, isLoading: false);
  }

  Future<void> addLabel({required String name, required Color color}) async {
    final label = Label(id: _uuid.v4(), name: name, color: color);
    await ref
        .read(undoRedoProvider.notifier)
        .execute(CreateCommand(repo: _repo, item: label, id: label.id, displayName: label.name));
    await loadLabels();
  }

  Future<void> updateLabel(Label label) async {
    final oldLabel = await _repo.getById(label.id);
    if (oldLabel == null) return;
    await ref
        .read(undoRedoProvider.notifier)
        .execute(UpdateCommand(repo: _repo, previous: oldLabel, next: label, displayName: label.name));
    await loadLabels();
    await ref.read(projectProvider.notifier).loadProjects();
    await ref.read(taskProvider.notifier).refreshTasks();
  }

  Future<void> deleteLabel(String id) async {
    final label = await _repo.getById(id);
    if (label == null) return;
    await ref
        .read(undoRedoProvider.notifier)
        .execute(DeleteCommand(repo: _repo, item: label, id: label.id, displayName: label.name));
    ref.read(filterProvider.notifier).removeLabelFilter(id);
    await ref.read(settingsProvider.notifier).setPersistentFilterValues(ref.read(filterProvider).filter.toMap());
    await loadLabels();
    await ref.read(projectProvider.notifier).loadProjects();
    await ref.read(taskProvider.notifier).refreshTasks();
  }

  Label? getById(String? id) {
    if (id == null) return null;
    try {
      return state.labels.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }
}

final labelProvider = NotifierProvider<LabelNotifier, LabelState>(() {
  return LabelNotifier();
});
