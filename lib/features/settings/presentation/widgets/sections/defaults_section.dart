import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_picker.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/settings_components.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DefaultsSection extends ConsumerWidget {
  const DefaultsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final projects = ref.watch(projectProvider).projects.where((p) => p.isActive).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        SettingsSection(
          title: 'Defaults',
          children: [

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
      ],
    );
  }
}
