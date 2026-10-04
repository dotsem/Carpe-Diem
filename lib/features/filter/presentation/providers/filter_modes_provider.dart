import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/models/filter_mode.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';

const String keyFilterModes =
    'filter_modes_presets'; // TODO: should this be centralized?

class FilterModesState {
  final List<FilterMode> modes;
  final bool isLoading;

  const FilterModesState({this.modes = const [], this.isLoading = false});

  FilterModesState copyWith({List<FilterMode>? modes, bool? isLoading}) {
    return FilterModesState(
      modes: modes ?? this.modes,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FilterModesNotifier extends Notifier<FilterModesState> {
  late final IKeyValueRepository _repo;

  @override
  FilterModesState build() {
    _repo = ref.watch(keyValueRepositoryProvider);
    return const FilterModesState();
  }

  Future<void> loadModes() async {
    try {
      final raw = await _repo.get(keyFilterModes);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final modes = decoded
            .map((item) => FilterMode.fromMap(item as Map<String, dynamic>))
            .toList();
        state = state.copyWith(modes: modes, isLoading: false);
      } else {
        state = state.copyWith(modes: const [], isLoading: false);
      }
    } catch (e) {
      debugPrint('Failed to load filter modes: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<FilterMode> createMode({
    required String name,
    required TaskFilter filter,
  }) async {
    final mode = FilterMode(
      id: const Uuid().v4(),
      name: name.trim(),
      filter: filter,
    );
    final updated = [...state.modes, mode];
    await _saveModes(updated);
    state = state.copyWith(modes: updated);
    return mode;
  }

  Future<void> updateMode(FilterMode updatedMode) async {
    final updated = state.modes.map((m) {
      return m.id == updatedMode.id ? updatedMode : m;
    }).toList();
    await _saveModes(updated);
    state = state.copyWith(modes: updated);
  }

  Future<void> deleteMode(String modeId) async {
    final updated = state.modes.where((m) => m.id != modeId).toList();
    await _saveModes(updated);
    state = state.copyWith(modes: updated);
  }

  Future<void> _saveModes(List<FilterMode> modes) async {
    try {
      final encoded = jsonEncode(modes.map((m) => m.toMap()).toList());
      await _repo.set(keyFilterModes, encoded);
    } catch (e) {
      debugPrint('Failed to save filter modes: $e');
    }
  }
}

final filterModesProvider =
    NotifierProvider<FilterModesNotifier, FilterModesState>(() {
      return FilterModesNotifier();
    });

final activeFilterModeProvider = Provider<FilterMode?>((ref) {
  final filter = ref.watch(filterProvider).filter;
  if (filter.isEmpty) return null;
  final modes = ref.watch(filterModesProvider).modes;
  for (final m in modes) {
    if (m.filter == filter) return m;
  }
  return null;
});
