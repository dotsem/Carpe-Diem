import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:flutter/material.dart';

enum CreateTagsPromptResult { createAndSave, saveWithoutTags, cancel }

class CreateTagsPromptDialog extends StatelessWidget {
  final List<String> newTagNames;

  const CreateTagsPromptDialog({super.key, required this.newTagNames});

  @override
  Widget build(BuildContext context) {
    return SizedDialog(
      title: 'Create New Tag${newTagNames.length > 1 ? 's' : ''}?',
      showDefaultActions: false,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(CreateTagsPromptResult.cancel),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(CreateTagsPromptResult.saveWithoutTags),
          child: Text('Save Without Tag${newTagNames.length > 1 ? 's' : ''}'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(CreateTagsPromptResult.createAndSave),
          child: Text('Create & Save${newTagNames.length > 1 ? 's' : ''}'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The following ${newTagNames.length} tag${newTagNames.length > 1 ? 's' : ''} do${newTagNames.length > 1 ? '' : 'es'} not exist yet. Would you like to create them${newTagNames.length > 1 ? '' : 'se'}?',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: newTagNames.map((name) {
              return Chip(
                label: Text('#$name', style: const TextStyle(fontWeight: FontWeight.w600)),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
