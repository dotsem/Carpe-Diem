import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/models/filter_mode.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';

const String keyActiveFilterMode =
    'active_filter_mode_id'; // TODO: should this be centralized?

class FilterModesState {
  final List<FilterMode> modes;
  final String? activeModeId;
  final bool isLoading;

  const FilterModesState({
    this.modes = const [],
    this.activeModeId,
    this.isLoading = false,
  });

  FilterModesState copyWith({
    List<FilterMode>? modes,
    String? activeModeId,
    bool clearActiveModeId = false,
    bool? isLoading,
  }) {
    return FilterModesState(
      modes: modes ?? this.modes,
      activeModeId: clearActiveModeId
          ? null
          : (activeModeId ?? this.activeModeId),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FilterModesNotifier extends Notifier<FilterModesState> {
  late final IFilterModeRepository _repo;
  late final IKeyValueRepository _kvRepo;

  @override
  FilterModesState build() {
    _repo = ref.watch(filterModeRepositoryProvider);
    _kvRepo = ref.watch(keyValueRepositoryProvider);
    return const FilterModesState();
  }

  Future<void> loadModes() async {
    try {
      final modes = await _repo.getAll();
      final activeId = await _kvRepo.get(keyActiveFilterMode);
      state = state.copyWith(
        modes: modes,
        activeModeId: activeId,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Failed to load filter modes: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<FilterMode> createMode({
    required String name,
    required TaskFilter filter,
    int? iconCodePoint,
  }) async {
    final mode = FilterMode(
      id: const Uuid().v4(),
      name: name.trim(),
      filter: filter,
      iconCodePoint: iconCodePoint,
    );
    await _repo.insert(mode);
    final updated = [...state.modes, mode];
    state = state.copyWith(modes: updated);
    return mode;
  }

  Future<void> updateMode(FilterMode updatedMode) async {
    await _repo.update(updatedMode);
    final updated = state.modes.map((m) {
      return m.id == updatedMode.id ? updatedMode : m;
    }).toList();
    state = state.copyWith(modes: updated);
  }

  Future<void> deleteMode(String modeId) async {
    await _repo.delete(modeId);
    if (state.activeModeId == modeId) {
      await setActiveModeId(null);
    }
    final updated = state.modes.where((m) => m.id != modeId).toList();
    state = state.copyWith(modes: updated);
  }

  Future<void> setActiveModeId(String? id) async {
    if (state.activeModeId == id) return;
    try {
      if (id != null) {
        await _kvRepo.set(keyActiveFilterMode, id);
      } else {
        await _kvRepo.delete(keyActiveFilterMode);
      }
    } catch (e) {
      debugPrint('Failed to persist active filter mode: $e');
    }
    state = state.copyWith(activeModeId: id, clearActiveModeId: id == null);
  }
}

final filterModesProvider =
    NotifierProvider<FilterModesNotifier, FilterModesState>(() {
      return FilterModesNotifier();
    });

final activeFilterModeProvider = Provider<FilterMode?>((ref) {
  final filter = ref.watch(filterProvider).filter;
  if (filter.isEmpty) return null;
  final modesState = ref.watch(filterModesProvider);
  final activeId = modesState.activeModeId;
  if (activeId != null) {
    for (final m in modesState.modes) {
      if (m.id == activeId) {
        if (m.filter == filter) return m;
        break;
      }
    }
  }
  for (final m in modesState.modes) {
    if (m.filter == filter) return m;
  }
  return null;
});
