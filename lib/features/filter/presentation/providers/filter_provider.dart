import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';

class FilterState {
  final TaskFilter filter;
  final bool isBypassed;

  const FilterState({this.filter = const TaskFilter(), this.isBypassed = false});

  TaskFilter get activeFilter => isBypassed ? const TaskFilter() : filter;

  FilterState copyWith({TaskFilter? filter, bool? isBypassed}) {
    return FilterState(filter: filter ?? this.filter, isBypassed: isBypassed ?? this.isBypassed);
  }
}

class FilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() {
    if (ref.read(settingsProvider).persistentFilter) {
      final filter = TaskFilter.fromMap(ref.read(settingsProvider).persistentFilterValues);
      return FilterState(filter: filter);
    }
    return const FilterState();
  }

  void _persistIfEnabled() {
    if (ref.read(settingsProvider).persistentFilter) {
      ref.read(settingsProvider.notifier).setPersistentFilterValues(state.filter.toMap());
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
          labelIdsIncluded: Set<String>.from(state.filter.labelIdsIncluded)..remove(labelId),
        ),
      );
      _persistIfEnabled();
    } else if (state.filter.labelIdsExcluded.contains(labelId)) {
      state = state.copyWith(
        filter: state.filter.copyWith(
          labelIdsExcluded: Set<String>.from(state.filter.labelIdsExcluded)..remove(labelId),
        ),
      );
      _persistIfEnabled();
    }
  }

  void removeProjectFilter(String projectId) {
    if (state.filter.projectIdsIncluded.contains(projectId)) {
      state = state.copyWith(
        filter: state.filter.copyWith(
          projectIdsIncluded: Set<String>.from(state.filter.projectIdsIncluded)..remove(projectId),
        ),
      );
      _persistIfEnabled();
    } else if (state.filter.projectIdsExcluded.contains(projectId)) {
      state = state.copyWith(
        filter: state.filter.copyWith(
          projectIdsExcluded: Set<String>.from(state.filter.projectIdsExcluded)..remove(projectId),
        ),
      );
      _persistIfEnabled();
    }
  }

  void removePriorityFilter(Priority priority) {
    if (state.filter.prioritiesIncluded.contains(priority)) {
      state = state.copyWith(
        filter: state.filter.copyWith(
          prioritiesIncluded: Set<Priority>.from(state.filter.prioritiesIncluded)..remove(priority),
        ),
      );
      _persistIfEnabled();
    } else if (state.filter.prioritiesExcluded.contains(priority)) {
      state = state.copyWith(
        filter: state.filter.copyWith(
          prioritiesExcluded: Set<Priority>.from(state.filter.prioritiesExcluded)..remove(priority),
        ),
      );
      _persistIfEnabled();
    }
  }
}

final filterProvider = NotifierProvider<FilterNotifier, FilterState>(() {
  return FilterNotifier();
});
