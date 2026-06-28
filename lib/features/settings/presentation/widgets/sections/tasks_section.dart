import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/settings_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TasksSection extends ConsumerWidget {
  const TasksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        SettingsSection(
          title: 'Tasks',
          children: [
            SettingsSliderTile(
              icon: Icons.timer_outlined,
              title: 'Completion Delay',
              subtitle: 'Seconds to wait before marking task as complete',
              value: settings.taskCompletionDelay.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              labelBuilder: (v) => '${v.round()}s',
              onChanged: (value) => settingsNotifier.setTaskCompletionDelay(value.round()),
            ),
            SettingsSwitchTile(
              icon: Icons.subdirectory_arrow_right_outlined,
              title: 'Inherit Parent Deadline',
              subtitle: 'New subtasks inherit parent deadline',
              value: settings.inheritParentDeadline,
              onChanged: (value) => settingsNotifier.setInheritParentDeadline(value),
            ),
            SettingsSwitchTile(
              icon: Icons.folder_shared_outlined,
              title: 'Inherit Project Deadline',
              subtitle: 'New tasks inherit project deadline',
              value: settings.inheritProjectDeadline,
              onChanged: (value) => settingsNotifier.setInheritProjectDeadline(value),
            ),
            SettingsSwitchTile(
              icon: Icons.priority_high_outlined,
              title: 'Prioritize Deadlines',
              subtitle: 'Sort tasks by deadline first',
              value: settings.prioritizeDeadlines,
              onChanged: (value) => settingsNotifier.setPrioritizeDeadlines(value),
            ),
            SettingsSwitchTile(
              icon: Icons.event_busy_outlined,
              title: 'Prioritize Overdue',
              subtitle: 'Show overdue tasks at the top of lists in kanban view',
              value: settings.prioritizeOverdue,
              onChanged: (value) => settingsNotifier.setPrioritizeOverdue(value),
            ),
          ],
        ),
      ],
    );
  }
}
