import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/settings_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlanningSection extends ConsumerWidget {
  const PlanningSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        SettingsSection(
          title: 'Planning',
          children: [
            SettingsSliderTile(
              icon: Icons.calendar_month_outlined,
              title: 'Planning Horizon',
              subtitle: 'Days ahead to show in the date selector',
              value: settings.maxPlanningDays.toDouble(),
              min: 3,
              max: 14,
              divisions: 11,
              onChanged: (value) => settingsNotifier.setMaxPlanningDays(value.round()),
            ),
            SettingsDropdownTile<int>(
              icon: Icons.first_page_outlined,
              title: 'First Day of Week',
              subtitle: 'Start your week on Monday or Sunday',
              value: settings.firstDayOfWeek,
              items: const [
                DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
                DropdownMenuItem(value: DateTime.sunday, child: Text('Sunday')),
              ],
              onChanged: (value) {
                if (value != null) settingsNotifier.setFirstDayOfWeek(value);
              },
            ),
            SettingsSwitchTile(
              icon: Icons.casino_rounded,
              title: 'Pick Random Task',
              subtitle: 'Enable a button to pick a random task from backlog',
              value: settings.enableRandomTask,
              onChanged: (value) => settingsNotifier.setEnableRandomTask(value),
            ),
          ],
        ),
      ],
    );
  }
}
