import 'package:carpe_diem/features/tags/presentation/constants/tag_icon_constants.dart';
import 'package:flutter/material.dart';

class IconPicker extends StatelessWidget {
  final IconData selected;
  final ValueChanged<IconData> onChanged;
  final List<IconData> icons;

  const IconPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.icons = availableIcons,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: icons.map((icon) {
        final isSelected = selected == icon;

        return InkWell(
          onTap: () => onChanged(icon),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }
}
