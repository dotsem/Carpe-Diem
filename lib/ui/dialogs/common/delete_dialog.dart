import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/ui/dialogs/common/sized_dialog.dart';
import 'package:flutter/material.dart';

class DeleteDialog extends StatelessWidget {
  final String title;
  final String message;
  final Function() onConfirm;
  const DeleteDialog({super.key, required this.title, required this.message, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return SizedDialog(
      onSubmit: () {
        Navigator.of(context).pop();
        onConfirm();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.text),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
