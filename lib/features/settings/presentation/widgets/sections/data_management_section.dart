import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/settings_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DataManagementSection extends ConsumerWidget {
  const DataManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        SettingsSection(
          title: 'Data Management',
          children: [
            SettingsDropdownTile<String>(
              icon: Icons.analytics_outlined,
              title: 'Default Stats Period',
              subtitle: 'Initial timeframe for history and statistics',
              value: settings.defaultStatsPeriod,
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (value) {
                if (value != null) settingsNotifier.setDefaultStatsPeriod(value);
              },
            ),
            SettingsDropdownTile<int>(
              icon: Icons.auto_delete_outlined,
              title: 'History Retention',
              subtitle: 'Automatically delete old completed tasks',
              value: settings.historyRetention,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Keep Forever')),
                DropdownMenuItem(value: 30, child: Text('30 Days')),
                DropdownMenuItem(value: 90, child: Text('90 Days')),
                DropdownMenuItem(value: 365, child: Text('1 Year')),
              ],
              onChanged: (value) {
                if (value != null) settingsNotifier.setHistoryRetention(value);
              },
            ),
            SettingsSwitchTile(
              icon: Icons.filter_alt_outlined,
              title: 'Hide archived projects',
              subtitle: 'They can still be temporarily shown by clicking "Show archived projects" button',
              value: settings.showActiveProjectsOnly,
              onChanged: (value) => settingsNotifier.setShowActiveProjectsOnly(value),
            ),
          ],
        ),
      ],
    );
  }
}
