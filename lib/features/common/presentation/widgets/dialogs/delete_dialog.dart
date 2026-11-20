import 'package:carpe_diem/features/common/presentation/widgets/dialogs/destructive_dialog.dart';
import 'package:flutter/material.dart';

class DeleteDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;
  const DeleteDialog({
    required this.title,
    required this.message,
    required this.onConfirm,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DestructiveDialog(
      title: title,
      message: message,
      destructiveText: 'Delete',
      onConfirm: onConfirm,
    );
  }
}
