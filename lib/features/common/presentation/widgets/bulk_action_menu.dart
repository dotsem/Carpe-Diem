import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

// TODO: rename this
class BulkActionOption {
  final String value;
  final IconData icon;
  final String label;
  final bool enabled;
  final bool isDestructive;

  const BulkActionOption({
    required this.value,
    required this.icon,
    required this.label,
    required this.enabled,
    this.isDestructive = false,
  });
}

class BulkActionMenu extends StatelessWidget {
  final List<BulkActionOption> options;
  final ValueChanged<String> onOptionSelected;
  final String disabledTooltip;

  const BulkActionMenu({
    super.key,
    required this.options,
    required this.onOptionSelected,
    this.disabledTooltip = 'select multiple tasks',
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) {
        return IconButton(
          icon: Icon(Icons.more_horiz, color: Theme.of(context).colorScheme.onSurface),
          tooltip: 'More actions',
          style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () => _showMenu(buttonContext),
        );
      },
    );
  }

  void _showMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;

    // Position underneath
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(0, button.size.height), ancestor: overlay),
        button.localToGlobal(Offset(button.size.width, button.size.height), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: options.map((opt) => _buildPopupMenuItem(context, opt)).toList(),
    ).then((value) {
      if (value != null) {
        onOptionSelected(value);
      }
    });
  }

  PopupMenuItem<String> _buildPopupMenuItem(BuildContext context, BulkActionOption opt) {
    final content = Row(
      children: [
        Icon(
          opt.icon,
          size: 20,
          color: opt.enabled
              ? (opt.isDestructive ? AppColors.error : null)
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Text(
          opt.label,
          style: TextStyle(
            color: opt.enabled
                ? (opt.isDestructive ? AppColors.error : null)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    return PopupMenuItem<String>(
      value: opt.value,
      enabled: opt.enabled,
      child: opt.enabled ? content : Tooltip(message: disabledTooltip, child: content),
    );
  }
}
