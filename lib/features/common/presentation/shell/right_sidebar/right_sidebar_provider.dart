import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';

class RightSidebarNotifier extends Notifier<RightSidebarState> {
  @override
  RightSidebarState build() {
    return const RightSidebarState();
  }

  void open(RightSidebarPanel panel) {
    if (state.activePanel == panel) return;
    if (state.activePanel == null) {
      state = RightSidebarState(activePanel: panel, history: const []);
    } else {
      state = RightSidebarState(
        activePanel: panel,
        history: [...state.history, state.activePanel!],
      );
    }
  }

  void close() {
    state = const RightSidebarState();
  }

  void pop() {
    if (state.history.isEmpty) {
      close();
    } else {
      final newHistory = List<RightSidebarPanel>.from(state.history);
      final lastPanel = newHistory.removeLast();
      state = RightSidebarState(activePanel: lastPanel, history: newHistory);
    }
  }
}

final rightSidebarProvider =
    NotifierProvider<RightSidebarNotifier, RightSidebarState>(
      RightSidebarNotifier.new,
    );

extension RightSidebar on BuildContext {
  void openRightSidebar(RightSidebarPanel panel, [WidgetRef? ref]) {
    final notifier = ref != null
        ? ref.read(rightSidebarProvider.notifier)
        : ProviderScope.containerOf(
            this,
            listen: false,
          ).read(rightSidebarProvider.notifier);
    notifier.open(panel);
  }
}
