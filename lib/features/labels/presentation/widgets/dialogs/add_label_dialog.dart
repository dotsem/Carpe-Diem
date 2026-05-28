import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/labels/presentation/providers/label_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/color_picker.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddLabelDialog extends ConsumerStatefulWidget {
  const AddLabelDialog({super.key});

  @override
  ConsumerState<AddLabelDialog> createState() => _AddLabelDialogState();
}

class _AddLabelDialogState extends ConsumerState<AddLabelDialog> {
  final nameController = TextEditingController();
  Color selectedColor = AppColors.accent;
  @override
  Widget build(BuildContext context) {
    return SizedDialog(
      title: 'New Label',
      submitText: 'Create',
      onSubmit: () {
        final name = nameController.text.trim();
        if (name.isNotEmpty) {
          ref.read(labelProvider.notifier).addLabel(name: name, color: selectedColor);
          Navigator.pop(context);
        }
      },
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
}
