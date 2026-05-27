import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/color_picker.dart';
import 'package:carpe_diem/features/common/presentation/widgets/common/sized_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditLabelDialog extends ConsumerStatefulWidget {
  final Label label;
  const EditLabelDialog({super.key, required this.label});

  @override
  ConsumerState<EditLabelDialog> createState() => _EditLabelDialogState();
}

class _EditLabelDialogState extends ConsumerState<EditLabelDialog> {
  late TextEditingController nameController;
  Color selectedColor = AppColors.accent;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.label.name);
    selectedColor = widget.label.color;
  }

  @override
  Widget build(BuildContext context) {
    return SizedDialog(
      title: 'Edit Label',
      onSubmit: _submit,
      submitText: 'Save',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Label name'),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          ProjectColorPicker(selected: selectedColor, onChanged: (c) => setState(() => selectedColor = c)),
        ],
      ),
    );
  }

  void _submit() {
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    ref.read(labelProvider.notifier).updateLabel(widget.label.copyWith(name: name, color: selectedColor));
    Navigator.of(context).pop();
  }
}
