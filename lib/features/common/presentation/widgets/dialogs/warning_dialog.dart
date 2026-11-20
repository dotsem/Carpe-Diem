import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/flutter_ext/dialogs/sized_dialog.dart';
import 'package:flutter/material.dart';

class WarningDialog extends StatelessWidget {
  final String title;
  final String message;
  final String warningText;
  final VoidCallback onConfirm;
  const WarningDialog({
    required this.title,
    required this.message,
    required this.onConfirm,
    required this.warningText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedDialog(
      title: title,
      submitText: warningText,
      submitStyle: FilledButton.styleFrom(
        backgroundColor: AppColors.warning,
        foregroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      onSubmit: () {
        Navigator.of(context).pop();
        onConfirm();
      },
      child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
