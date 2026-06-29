import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditTagDialog extends ConsumerStatefulWidget {
  final Tag tag;
  const EditTagDialog({super.key, required this.tag});

  @override
  ConsumerState<EditTagDialog> createState() => _EditTagDialogState();
}

class _EditTagDialogState extends ConsumerState<EditTagDialog> {
  late TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.tag.name);
  }

  @override
  Widget build(BuildContext context) {
    return SizedDialog(
      title: 'Edit Tag',
      onSubmit: _submit,
      submitText: 'Save',
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

  void _submit() {
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    ref.read(tagProvider.notifier).updateTag(widget.tag.copyWith(name: name));
    Navigator.of(context).pop();
  }
}
