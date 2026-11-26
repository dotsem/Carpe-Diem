import 'package:carpe_diem/features/common/presentation/widgets/bulk_action_bar.dart'
    show BulkActionBar;
import 'package:flutter/material.dart';

/// Icon-and-label button used inside a [BulkActionBar].
class BulkActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;
  final bool disabled;

  const BulkActionButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.color,
    required this.onPressed,
    this.disabled = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: TextButton.icon(
        onPressed: disabled ? null : onPressed,
        icon: Icon(
          icon,
          size: 20,
          color: disabled
              ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
              : color,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: disabled
                ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
