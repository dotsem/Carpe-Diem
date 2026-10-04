import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/common/presentation/widgets/icon_picker.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_icon_provider.dart';
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
  late IconData selectedIcon;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.tag.name);
    selectedIcon =
        ref.read(tagIconProvider)[widget.tag.name.trim().toLowerCase()] ??
        Icons.tag;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedDialog(
      title: 'Edit Tag',
      onSubmit: _submit,
      submitText: 'Save',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Tag Name',
              hintText: 'Tag name',
            ),
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
          IconPicker(
            selected: selectedIcon,
            onChanged: (icon) => setState(() => selectedIcon = icon),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    ref
        .read(tagProvider.notifier)
        .updateTag(widget.tag.copyWith(name: name), icon: selectedIcon);
    Navigator.of(context).pop();
  }
}
