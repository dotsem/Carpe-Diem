import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class CheesyToast extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onUndo;
  final ToastificationItem? item;

  const CheesyToast({
    super.key,
    required this.message,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onUndo,
    this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420, minHeight: 48),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: theme.colorScheme.surfaceContainerHigh,
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, color: color),

                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 20, color: color),
                          const SizedBox(width: 12),
                          Flexible(
                            child: _CheesyToastTextColumn(
                              message: message,
                              subtitle: subtitle,
                            ),
                          ),
                          if (onUndo != null && item != null) ...[
                            const SizedBox(width: 8),
                            _CheesyToastUndoButton(
                              onUndo: onUndo!,
                              item: item!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheesyToastTextColumn extends StatelessWidget {
  const _CheesyToastTextColumn({required this.message, this.subtitle});
  final String message;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
                  subtitle!,
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
  }
}

class _CheesyToastUndoButton extends StatelessWidget {
  const _CheesyToastUndoButton({required this.onUndo, required this.item});
  final VoidCallback onUndo;
  final ToastificationItem item;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: () {
        onUndo.call();
        toastification.dismiss(item);
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
    );
  }
}
