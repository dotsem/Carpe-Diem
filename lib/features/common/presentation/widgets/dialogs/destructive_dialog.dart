import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:flutter/material.dart';

class DestructiveDialog extends StatelessWidget {
  final String title;
  final String message;
  final String destructiveText;
  final VoidCallback onConfirm;
  const DestructiveDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    required this.destructiveText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedDialog(
      title: title,
      submitText: destructiveText,
      submitStyle: FilledButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
      onSubmit: () {
        Navigator.of(context).pop();
        onConfirm();
      },
      child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
