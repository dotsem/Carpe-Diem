import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/settings_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilteringSection extends ConsumerWidget {
  const FilteringSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        SettingsSection(
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
                  child: Text('Left/Right Click (Left to Include, Right to Exclude)'),
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
                if (value) {
                  settingsNotifier.setPersistentFilterValues(
                    ref.read(filterProvider).filter.toMap(),
                  );
                } else {
                  settingsNotifier.setPersistentFilterValues({});
                }
                settingsNotifier.setPersistentFilter(value);
              },
            ),
          ],
        ),
      ],
    );
  }
}
