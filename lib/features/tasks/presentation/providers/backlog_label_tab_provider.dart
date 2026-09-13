import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';

enum BacklogLabelTabScope { all, label, inbox }

const String keyLastActiveTab =
    "last_active_tab"; // TODO: relocate this to a centralized place

class BacklogLabelTabState {
  final BacklogLabelTabScope scope;
  final String? labelId;

  const BacklogLabelTabState.all()
    : scope = BacklogLabelTabScope.all,
      labelId = null;
  const BacklogLabelTabState.inbox()
    : scope = BacklogLabelTabScope.inbox,
      labelId = null;
  const BacklogLabelTabState.label(String id)
    : scope = BacklogLabelTabScope.label,
      labelId = id;

  /// Reconstruct the state from the string value stored in the repository.
  /// Must be a valid ID
  factory BacklogLabelTabState.fromString(
    String lastActiveTab, {
    Set<String>? validLabelIds,
  }) {
    if (lastActiveTab == 'inbox') {
      return const BacklogLabelTabState.inbox();
    }

    if (validLabelIds != null && validLabelIds.contains(lastActiveTab)) {
      return BacklogLabelTabState.label(lastActiveTab);
    }

    return const BacklogLabelTabState.all();
  }

  int getIndex(List<Label> labels) {
    return switch (scope) {
      BacklogLabelTabScope.all => 0,
      BacklogLabelTabScope.inbox => labels.length + 1,
      BacklogLabelTabScope.label => () {
        final index = labels.indexWhere((l) => l.id == labelId);
        return index >= 0 ? index + 1 : 0;
      }(),
    };
  }
}

class BacklogLabelTabNotifier extends Notifier<BacklogLabelTabState> {
  late final IKeyValueRepository _repo;

  @override
  BacklogLabelTabState build() {
    _repo = ref.watch(keyValueRepositoryProvider);
    ref.listen(labelProvider, (previous, next) {
      if (next.labels.isEmpty && state.scope != BacklogLabelTabScope.all) {
        selectAll();
      } else if (state.scope == BacklogLabelTabScope.label &&
          !next.labels.any((l) => l.id == state.labelId)) {
        selectAll();
      }
    });
    ref.listen(filterProvider, (previous, next) {
      if (next.isBypassed) return;
      final filter = next.filter;
      if (state.scope == BacklogLabelTabScope.label) {
        final isExcluded = filter.labelIdsExcluded.contains(state.labelId);
        final isNotIncluded =
            filter.labelIdsIncluded.isNotEmpty &&
            !filter.labelIdsIncluded.contains(state.labelId);
        if (isExcluded || isNotIncluded) {
          selectAll();
        }
      } else if (state.scope == BacklogLabelTabScope.inbox &&
          filter.labelIdsIncluded.isNotEmpty) {
        selectAll();
      }
    });
    return const BacklogLabelTabState.all();
  }

  Future<void> loadLastActiveTab() async {
    final lastActiveTab = await _repo.get(keyLastActiveTab);
    if (lastActiveTab == null) {
      state = const BacklogLabelTabState.all();
      return;
    }
    final validLabelIds = ref
        .read(labelProvider)
        .labels
        .map((l) => l.id)
        .toSet();
    state = BacklogLabelTabState.fromString(
      lastActiveTab,
      validLabelIds: validLabelIds,
    );
  }

  Future<void> saveLastActiveTab() async {
    try {
      await _repo.set(keyLastActiveTab, state.labelId ?? state.scope.name);
    } catch (e) {
      debugPrint('Failed to save last active tab: $e');
    }
  }

  void selectAll() {
    state = const BacklogLabelTabState.all();
    saveLastActiveTab();
  }

  void selectInbox() {
    state = const BacklogLabelTabState.inbox();
    saveLastActiveTab();
  }

  void selectLabel(String labelId) {
    state = BacklogLabelTabState.label(labelId);
    saveLastActiveTab();
  }
}

final backlogLabelTabProvider =
    NotifierProvider<BacklogLabelTabNotifier, BacklogLabelTabState>(
      BacklogLabelTabNotifier.new,
    );
