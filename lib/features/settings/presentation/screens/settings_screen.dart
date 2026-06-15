import 'package:carpe_diem/features/projects/presentation/widgets/project_picker.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/labels/presentation/widgets/label_picker.dart';
import 'package:carpe_diem/features/common/presentation/widgets/screen_header.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/settings_components.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/interactive_task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final projects = ref.watch(projectProvider).projects.where((p) => p.isActive).toList();

    return Column(
      children: [
        const ScreenHeader(title: 'Settings', subtitle: 'Manage your application preferences'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              SettingsSection(
                title: 'Appearance',
                children: [
                  SettingsDropdownTile<ThemeMode>(
                    icon: Icons.palette_outlined,
                    title: 'Theme Mode',
                    subtitle: 'Choose your preferred theme',
                    value: settings.themeMode,
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                    ],
                    onChanged: (value) {
                      if (value != null) settingsNotifier.setThemeMode(value);
                    },
                  ),
                  SettingsSwitchTile(
                    icon: Icons.compress_outlined,
                    title: 'Compact Mode',
                    subtitle: 'Reduce card size and text density',
                    value: settings.compactMode,
                    onChanged: (value) => settingsNotifier.setCompactMode(value),
                  ),
                  SettingsSwitchTile(
                    icon: Icons.description_outlined,
                    title: 'Show Descriptions',
                    subtitle: 'Display task descriptions on cards',
                    value: settings.showDescriptionOnCard,
                    onChanged: (value) => settingsNotifier.setShowDescriptionOnCard(value),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Card Gradient Width',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Drag on the card below to adjust project color intensity',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        InteractiveTaskCard(
                          initialWidth: settings.taskGradientWidth,
                          onChanged: (val) => settingsNotifier.setTaskGradientWidth(val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SettingsSection(
                title: 'Labels',
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: LabelPicker(selectedLabelIds: const [], onSelected: (_) {}, isManageMode: true),
                  ),
                ],
              ),
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
              SettingsSection(
                title: 'Defaults',
                children: [
                  SettingsDropdownTile<String>(
                    icon: Icons.flag_outlined,
                    title: 'Default Priority',
                    subtitle: 'Priority for new tasks',
                    value: settings.defaultPriority,
                    items: Priority.values.map((p) => DropdownMenuItem(value: p.name, child: Text(p.label))).toList(),
                    onChanged: (value) {
                      if (value != null) settingsNotifier.setDefaultPriority(value);
                    },
                  ),
                  SettingsCustomWidgetTile(
                    icon: Icons.folder_outlined,
                    title: 'Default Project',
                    subtitle: 'Project for new tasks',
                    child: SizedBox(
                      width: 200,
                      child: ProjectPicker(
                        selectedProjectId: settings.defaultProjectId,
                        onChanged: (value) => settingsNotifier.setDefaultProjectId(value),
                        projects: projects,
                      ),
                    ),
                  ),
                ],
              ),
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
                ],
              ),

            ],
          ),
        ),
      ],
    );
  }
}
