import 'dart:convert';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/settings/presentation/constants/settings_constants.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';

class FilterState {
  final TaskFilter filter;
  final bool isBypassed;

  const FilterState({
    this.filter = const TaskFilter(),
    this.isBypassed = false,
  });

  TaskFilter get activeFilter => isBypassed ? const TaskFilter() : filter;

  FilterState copyWith({TaskFilter? filter, bool? isBypassed}) {
    return FilterState(
      filter: filter ?? this.filter,
      isBypassed: isBypassed ?? this.isBypassed,
    );
  }
}

class FilterNotifier extends Notifier<FilterState> {
  late final IKeyValueRepository _repo;

  @override
  FilterState build() {
    _repo = ref.watch(keyValueRepositoryProvider);
    return const FilterState();
  }

  Future<void> loadFilter() async {
    if (!ref.read(settingsProvider).persistentFilter) return;
    try {
      final raw = await _repo.get(SettingsConstants.keyPersistentFilterValues);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        state = state.copyWith(filter: TaskFilter.fromMap(map));
      }
    } catch (e) {
      debugPrint('Failed to load filter: $e');
    }
  }

  Future<void> saveFilter() async {
    try {
      await _repo.set(
        SettingsConstants.keyPersistentFilterValues,
        jsonEncode(state.filter.toMap()),
      );
    } catch (e) {
      debugPrint('Failed to save filter: $e');
    }
  }

  Future<void> clearPersistedFilter() async {
    try {
      await _repo.delete(SettingsConstants.keyPersistentFilterValues);
    } catch (e) {
      debugPrint('Failed to clear persisted filter: $e');
    }
  }

  void _persistIfEnabled() {
    if (ref.read(settingsProvider).persistentFilter) {
      saveFilter();
    }
  }

  void setFilter(TaskFilter filter) {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter);
    _persistIfEnabled();
  }

  void toggleBypass() {
    state = state.copyWith(isBypassed: !state.isBypassed);
  }

  void clearFilter() {
    if (state.filter.isEmpty) return;
    state = const FilterState(filter: TaskFilter(), isBypassed: false);
    _persistIfEnabled();
  }

  void removeLabelFilter(String labelId) {
    if (state.filter.labelIdsIncluded.contains(labelId)) {
      state = state.copyWith(
        filter: state.filter.copyWith(
          labelIdsIncluded: Set<String>.from(state.filter.labelIdsIncluded)
            ..remove(labelId),
        ),
      );
      _persistIfEnabled();
    } else if (state.filter.labelIdsExcluded.contains(labelId)) {
      state = state.copyWith(
        filter: state.filter.copyWith(
          labelIdsExcluded: Set<String>.from(state.filter.labelIdsExcluded)
            ..remove(labelId),
        ),
      );
      _persistIfEnabled();
    }
  }

  void removeProjectFilter(String projectId) {
    if (state.filter.projectIdsIncluded.contains(projectId)) {
      state = state.copyWith(
        filter: state.filter.copyWith(
          projectIdsIncluded: Set<String>.from(state.filter.projectIdsIncluded)
            ..remove(projectId),
        ),
      );
      _persistIfEnabled();
    } else if (state.filter.projectIdsExcluded.contains(projectId)) {
      state = state.copyWith(
        filter: state.filter.copyWith(
          projectIdsExcluded: Set<String>.from(state.filter.projectIdsExcluded)
            ..remove(projectId),
        ),
      );
      _persistIfEnabled();
    }
  }

  void removeTagFilter(String tagId) {
    if (state.filter.tagIdsIncluded.contains(tagId)) {
      state = state.copyWith(
        filter: state.filter.copyWith(
          tagIdsIncluded: Set<String>.from(state.filter.tagIdsIncluded)
            ..remove(tagId),
        ),
      );
      _persistIfEnabled();
    } else if (state.filter.tagIdsExcluded.contains(tagId)) {
      state = state.copyWith(
        filter: state.filter.copyWith(
          tagIdsExcluded: Set<String>.from(state.filter.tagIdsExcluded)
            ..remove(tagId),
        ),
      );
      _persistIfEnabled();
    }
  }

  void setUrgentFilter(bool? isUrgent) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        isUrgent: isUrgent,
        clearIsUrgent: isUrgent == null,
      ),
    );
    _persistIfEnabled();
  }
}

final filterProvider = NotifierProvider<FilterNotifier, FilterState>(() {
  return FilterNotifier();
});
