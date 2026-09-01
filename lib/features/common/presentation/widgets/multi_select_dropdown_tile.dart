import 'package:flutter/material.dart';

class MultiSelectDropdownTile extends StatelessWidget {
  final String name;
  final Widget? leading;
  final bool isSelected;
  final bool isDisabled;
  final bool isHighlighted;
  final VoidCallback onHover;
  final ValueChanged<bool?>? onChanged;

  const MultiSelectDropdownTile({
    super.key,
    required this.name,
    this.leading,
    required this.isSelected,
    required this.isDisabled,
    required this.isHighlighted,
    required this.onHover,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onHover: (_) => onHover(),
      child: Material(
        color: isHighlighted
            ? theme.colorScheme.primary.withAlpha(25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: CheckboxListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(name, style: const TextStyle(fontSize: 13)),
          secondary: leading,
          value: isSelected,
          enabled: !isDisabled,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
