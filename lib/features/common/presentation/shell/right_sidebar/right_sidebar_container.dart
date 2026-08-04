import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_panel_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';

class RightSidebarContainer extends ConsumerWidget {
  const RightSidebarContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rightSidebarProvider);
    final panel = state.activePanel;

    if (panel == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(left: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, ref, state, panel),
            const Divider(height: 1),
            Expanded(child: RightSidebarPanelBody(panel: panel)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, RightSidebarState state, RightSidebarPanel panel) {
    final theme = Theme.of(context);
    final title = _getPanelTitle(panel);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (state.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back',
              onPressed: () => ref.read(rightSidebarProvider.notifier).pop(),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
              ref.read(rightSidebarProvider.notifier).close();
            },
          ),
        ],
      ),
    );
  }

  String _getPanelTitle(RightSidebarPanel panel) {
    return switch (panel) {
      AddTaskPanel() => 'New Task',
      EditTaskPanel() => 'Edit Task',
      EditProjectPanel() => 'Edit Project',
      ActionHistoryPanel() => 'Action History',
    };
  }
}
