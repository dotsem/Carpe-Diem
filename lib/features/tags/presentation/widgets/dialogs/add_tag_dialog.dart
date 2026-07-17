import 'package:carpe_diem/features/tags/presentation/constants/tag_icon_constants.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddTagDialog extends ConsumerStatefulWidget {
  const AddTagDialog({super.key});

  @override
  ConsumerState<AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends ConsumerState<AddTagDialog> {
  final nameController = TextEditingController();
  IconData selectedIcon = Icons.tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedDialog(
      title: 'New Tag',
      submitText: 'Create',
      onSubmit: () {
        final name = nameController.text.trim();
        if (name.isNotEmpty) {
          ref.read(tagProvider.notifier).addTag(name, icon: selectedIcon);
          Navigator.pop(context);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Tag Name', hintText: 'Tag name'),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Tag Icon',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableIcons.map((icon) {
              final isSelected = selectedIcon == icon;

              return InkWell(
                onTap: () {
                  setState(() {
                    selectedIcon = icon;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? colorScheme.primary : Colors.transparent, width: 2),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
