import 'package:flutter/material.dart';

class FilterButton extends StatelessWidget {
  final bool isBypassed;
  final VoidCallback onFilterTap;
  final VoidCallback onToggleBypass;
  final VoidCallback onClear;

  const FilterButton({
    required this.isBypassed,
    required this.onFilterTap,
    required this.onToggleBypass,
    required this.onClear,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final errColor = Theme.of(context).colorScheme.error.withValues(alpha: 0.9);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Tooltip(
            message:
                'Right click: toggle passthrough · Middle click: clear filters',
            child: GestureDetector(
              onSecondaryTap: onToggleBypass,
              onTertiaryTapUp: (_) => onClear(),
              child: ActionChip(
                avatar: Icon(
                  isBypassed ? Icons.filter_list_off : Icons.filter_list,
                  size: 16,
                  color: isBypassed ? errColor : null,
                ),
                label: Text(
                  'Filter',
                  style: TextStyle(
                    color: isBypassed ? errColor : null,
                    decoration: isBypassed ? TextDecoration.lineThrough : null,
                  ),
                ),
                onPressed: isBypassed ? null : onFilterTap,
                mouseCursor: isBypassed
                    ? SystemMouseCursors.basic
                    : SystemMouseCursors.click,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHigh,
                side: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
