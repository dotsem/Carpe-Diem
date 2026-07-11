import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:carpe_diem/features/labels/presentation/widgets/label_picker.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/settings_components.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LabelsSection extends ConsumerWidget {
  const LabelsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    // TODO: may split up labels and tags into separate sections
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        SettingsSection(
          title: 'Labels',
          children: [
            SettingsCustomListTile(
              title: 'Labels',
              subtitle: 'Manage your labels',
              icon: Icons.label,
              children: [LabelPicker(selectedLabelIds: [], onSelected: (_) {}, isManageMode: true)],
            ),
          ],
        ),
        SettingsSection(
          title: 'Tags',
          children: [
            SettingsCustomListTile(
              title: 'Tags',
              subtitle: 'Manage your tags',
              icon: Icons.tag,
              children: [TagPicker(selectedTagIds: [], onSelected: (_) {}, isManageMode: true)],
            ),
            SettingsDropdownTile<Absorption>(
              icon: Icons.merge,
              title: "Tag Absorption",
              subtitle: "Decide if hashtags typed in the title append to or replace current tag selections.",
              value: settings.tagAbsorption,
              items: const [
                DropdownMenuItem(value: Absorption.replace, child: Text("Replace")),
                DropdownMenuItem(value: Absorption.append, child: Text("Add")),
              ],
              onChanged: (absorption) {
                if (absorption == null) return;
                settingsNotifier.setTagAbsorption(absorption);
              },
            ),
          ],
        ),
      ],
    );
  }
}
