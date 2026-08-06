import 'package:carpe_diem/features/common/presentation/widgets/section_card.dart';
import 'package:carpe_diem/features/labels/presentation/widgets/label_picker.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_picker.dart';
import 'package:flutter/material.dart';

class CategorizationSection extends StatelessWidget {
  final List<String> selectedLabelIds;
  final List<String> inheritedLabelIds;
  final ValueChanged<List<String>> onLabelsSelected;
  final List<String> selectedTagIds;
  final ValueChanged<List<String>> onTagsSelected;

  const CategorizationSection({
    super.key,
    required this.selectedLabelIds,
    required this.inheritedLabelIds,
    required this.onLabelsSelected,
    required this.selectedTagIds,
    required this.onTagsSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      margin: const EdgeInsets.symmetric(vertical: 8),
      items: [
        SectionItem(
          icon: Icons.label_outlined,
          title: 'Labels',
          child: LabelPicker(
            selectedLabelIds: selectedLabelIds,
            inheritedLabelIds: inheritedLabelIds,
            onSelected: onLabelsSelected,
            isDropdown: true,
          ),
        ),
        SectionItem(
          icon: Icons.tag,
          title: 'Tags',
          child: TagPicker(
            selectedTagIds: selectedTagIds,
            onSelected: onTagsSelected,
            isDropdown: true,
          ),
        ),
      ],
    );
  }
}
