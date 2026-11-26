import 'package:carpe_diem/features/common/presentation/widgets/bulk_action_menu.dart';
import 'package:carpe_diem/features/common/presentation/widgets/screen_header.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/backlog/backlog_dialog_handlers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Title row of the backlog screen with random-task, import and add actions.
class BacklogHeader extends ConsumerWidget {
  final String searchQuery;

  const BacklogHeader({required this.searchQuery, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return ScreenHeader(
      title: 'Backlog',
      subtitle: 'Tasks without a scheduled date',
      actions: [
        if (settings.enableRandomTask) ...[
          IconButton(
            onPressed: () =>
                BacklogDialogHandlers.pickRandomTask(context, ref, searchQuery),
            icon: const Icon(Icons.casino_rounded),
            tooltip: 'Give me a random task!',
          ),
          const SizedBox(width: 8),
        ],
        BulkActionMenu(
          options: const [
            BulkActionOption(
              value: 'import',
              icon: Icons.download_rounded,
              label: 'Import from MD',
              enabled: true,
            ),
          ],
          onOptionSelected: (value) {
            if (value == 'import') {
              BacklogDialogHandlers.showImportFromMD(context);
            }
          },
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => BacklogDialogHandlers.showAddTask(context, ref: ref),
          icon: const Icon(Icons.add),
          label: const Text('Add Task'),
        ),
      ],
    );
  }
}
