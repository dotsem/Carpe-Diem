import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';

class LabelState {
  final List<Label> labels;
  final bool isLoading;

  const LabelState({this.labels = const [], this.isLoading = false});

  LabelState copyWith({List<Label>? labels, bool? isLoading}) {
    return LabelState(
      labels: labels ?? this.labels,
      isLoading: isLoading ?? this.isLoading,
    );
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
    return const LabelState();
  }

  Future<void> loadLabels() async {
    state = state.copyWith(isLoading: true);
    final labels = await _repo.getAll();
    state = LabelState(labels: labels, isLoading: false);
  }

  Future<void> addLabel({required String name, required Color color}) async {
    final label = Label(id: _uuid.v4(), name: name, color: color);
    await _repo.insert(label);
    await loadLabels();
  }

  Future<void> updateLabel(Label label) async {
    await _repo.update(label);
    await loadLabels();
  }

  Future<void> deleteLabel(String id) async {
    await _repo.delete(id);
    await loadLabels();
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
