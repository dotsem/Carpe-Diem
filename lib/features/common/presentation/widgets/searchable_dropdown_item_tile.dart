import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SearchableDropdownItemTile<T> extends StatelessWidget {
  final String label;
  final bool isHighlighted;
  final Widget? leading;
  final VoidCallback onTap;
  final VoidCallback onHover;

  const SearchableDropdownItemTile({
    super.key,
    required this.label,
    required this.isHighlighted,
    this.leading,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      onHover: (hovering) {
        if (hovering) onHover();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppColors.accent.withAlpha(25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isHighlighted
                      ? AppColors.accent
                      : theme.colorScheme.onSurface,
                  fontWeight: isHighlighted
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
