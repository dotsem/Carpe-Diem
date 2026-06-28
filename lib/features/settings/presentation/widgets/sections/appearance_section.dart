import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/settings_components.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/interactive_task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return ListView(
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Drag on the card below to adjust project color intensity',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
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
      ],
    );
  }
}
