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
  @override
  Widget build(BuildContext context) {
    return SizedDialog(
      title: 'New Tag',
      submitText: 'Create',
      onSubmit: () {
        final name = nameController.text.trim();
        if (name.isNotEmpty) {
          ref.read(tagProvider.notifier).addTag(name);
          Navigator.pop(context);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Tag name'),
            autofocus: true,
          ),
        ],
      ),
    );
  }
}
