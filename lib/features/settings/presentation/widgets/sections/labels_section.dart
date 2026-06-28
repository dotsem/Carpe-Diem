import 'package:carpe_diem/features/labels/presentation/widgets/label_picker.dart';
import 'package:carpe_diem/features/settings/presentation/widgets/settings_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LabelsSection extends ConsumerWidget {
  const LabelsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        SettingsSection(
          title: 'Labels',
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LabelPicker(selectedLabelIds: [], onSelected: (_) {}, isManageMode: true),
            ),
          ],
        ),
      ],
    );
  }
}
