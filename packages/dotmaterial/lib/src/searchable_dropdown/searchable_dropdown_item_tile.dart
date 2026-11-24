import 'package:flutter/material.dart';

class SearchableDropdownItemTile<T> extends StatelessWidget {
  final String label;
  final bool isHighlighted;
  final Widget? leading;
  final VoidCallback onTap;
  final VoidCallback onHover;

  const SearchableDropdownItemTile({
    required this.label,
    required this.isHighlighted,
    required this.onTap,
    required this.onHover,
    super.key,
    this.leading,
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
              ? Theme.of(context).colorScheme.primary.withAlpha(25)
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
                      ? Theme.of(context).colorScheme.primary
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
