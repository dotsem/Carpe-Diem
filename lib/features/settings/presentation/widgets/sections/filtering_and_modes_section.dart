import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:carpe_diem/features/filter/data/models/filter_mode.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_modes_provider.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/filter_dialog.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/save_mode_dialog.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/settings_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilteringAndModesSection extends StatelessWidget {
  const FilteringAndModesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: const [FilteringOptionsSection(), ModesSection()],
    );
  }
}

class FilteringOptionsSection extends ConsumerWidget {
  const FilteringOptionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return SettingsSection(
      title: 'Filtering',
      children: [
        SettingsDropdownTile<FilterInteractionMethod>(
          icon: Icons.filter_alt_outlined,
          title: 'Filter Tap Interaction',
          subtitle: 'Choose how tapping filter chips in the dialog behaves',
          value: settings.filterInteractionMethod,
          items: const [
            DropdownMenuItem(
              value: FilterInteractionMethod.cycle,
              child: Text('Cycle (None -> Include -> Exclude)'),
            ),
            DropdownMenuItem(
              value: FilterInteractionMethod.leftRightClick,
              child: Text(
                'Left/Right Click (Left to Include, Right to Exclude)',
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              settingsNotifier.setFilterInteractionMethod(value);
            }
          },
        ),
        SettingsSwitchTile(
          icon: Icons.save_outlined,
          title: 'Persistent Filters',
          subtitle: 'Remembers filters between app sessions',
          value: settings.persistentFilter,
          onChanged: (value) {
            settingsNotifier.setPersistentFilter(value);
            if (value) {
              ref.read(filterProvider.notifier).saveFilter();
            } else {
              ref.read(filterProvider.notifier).clearPersistedFilter();
            }
          },
        ),
      ],
    );
  }
}

class ModesSection extends ConsumerWidget {
  const ModesSection({super.key});

  String _buildFilterSummary(TaskFilter filter) {
    if (filter.isEmpty) return 'No filter constraints';

    final parts = <String>[];
    if (filter.isUrgent == true) parts.add('Urgent only');
    if (filter.isUrgent == false) parts.add('Non-urgent only');

    final projCount =
        filter.projectIdsIncluded.length + filter.projectIdsExcluded.length;
    if (projCount > 0) parts.add('$projCount project(s)');

    final labelCount =
        filter.labelIdsIncluded.length + filter.labelIdsExcluded.length;
    if (labelCount > 0) parts.add('$labelCount label(s)');

    final tagCount =
        filter.tagIdsIncluded.length + filter.tagIdsExcluded.length;
    if (tagCount > 0) parts.add('$tagCount tag(s)');

    return parts.join(' • ');
  }

  Future<void> _createMode(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => const SaveModeDialog(),
    );
    if (name == null || name.isEmpty) return;

    if (!context.mounted) return;
    final configuredFilter = await showDialog<TaskFilter>(
      context: context,
      builder: (ctx) => const FilterDialog(initialFilter: TaskFilter()),
    );

    if (configuredFilter != null) {
      await ref
          .read(filterModesProvider.notifier)
          .createMode(name: name, filter: configuredFilter);
    }
  }

  Future<void> _renameMode(
    BuildContext context,
    WidgetRef ref,
    FilterMode mode,
  ) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => SaveModeDialog(initialName: mode.name),
    );
    if (newName != null && newName.isNotEmpty) {
      await ref
          .read(filterModesProvider.notifier)
          .updateMode(mode.copyWith(name: newName));
    }
  }

  Future<void> _editModeFilter(
    BuildContext context,
    WidgetRef ref,
    FilterMode mode,
  ) async {
    final updatedFilter = await showDialog<TaskFilter>(
      context: context,
      builder: (ctx) => FilterDialog(initialFilter: mode.filter),
    );
    if (updatedFilter != null) {
      await ref
          .read(filterModesProvider.notifier)
          .updateMode(mode.copyWith(filter: updatedFilter));
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, FilterMode mode) {
    showDialog(
      context: context,
      builder: (ctx) => DeleteDialog(
        title: 'Delete Mode',
        message: 'Are you sure you want to delete "${mode.name}"?',
        onConfirm: () {
          ref.read(filterModesProvider.notifier).deleteMode(mode.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modes = ref.watch(filterModesProvider).modes;

    return SettingsSection(
      title: 'Filter Modes',
      children: [
        if (modes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  const Text(
                    'No filter modes created yet.',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Modes let you quickly switch filter presets between school, work, free time, and more.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create Mode'),
                    onPressed: () => _createMode(context, ref),
                  ),
                ],
              ),
            ),
          )
        else ...[
          for (final mode in modes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tune),
              title: Text(mode.name),
              subtitle: Text(
                _buildFilterSummary(mode.filter),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_alt_outlined, size: 20),
                    tooltip: 'Edit filter constraints',
                    onPressed: () => _editModeFilter(context, ref, mode),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Rename mode',
                    onPressed: () => _renameMode(context, ref, mode),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Delete mode',
                    onPressed: () => _confirmDelete(context, ref, mode),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.add),
                label: const Text('New Mode'),
                onPressed: () => _createMode(context, ref),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
