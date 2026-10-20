import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class CheesyToast extends StatelessWidget {
  final String message;
  final String? subtitle;
  final VoidCallback? onUndo;
  final ToastificationItem Function()? getItem;
  const CheesyToast({
    super.key,
    required this.message,
    this.subtitle,
    this.onUndo,
    this.getItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.visibility_off_outlined,
                size: 13,
                color: AppColors.warning,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  subtitle ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    if (onUndo == null) return textColumn;

    return Row(
      children: [
        Expanded(child: textColumn),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            onUndo!();
            final item = getItem?.call();
            if (item != null) {
              toastification.dismiss(item);
            }
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Undo',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
