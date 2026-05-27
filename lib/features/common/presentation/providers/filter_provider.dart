import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/data/models/task_filter.dart';

class FilterState {
  final TaskFilter filter;
  final bool isBypassed;

  const FilterState({this.filter = const TaskFilter(), this.isBypassed = false});

  TaskFilter get activeFilter => isBypassed ? const TaskFilter() : filter;

  FilterState copyWith({TaskFilter? filter, bool? isBypassed}) {
    return FilterState(
      filter: filter ?? this.filter,
      isBypassed: isBypassed ?? this.isBypassed,
    );
  }
}

class FilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() {
    return const FilterState();
  }

  void setFilter(TaskFilter filter) {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter);
  }

  void toggleBypass() {
    state = state.copyWith(isBypassed: !state.isBypassed);
  }

  void clearFilter() {
    if (state.filter.isEmpty) return;
    state = const FilterState(filter: TaskFilter(), isBypassed: false);
  }
}

final filterProvider = NotifierProvider<FilterNotifier, FilterState>(() {
  return FilterNotifier();
});
