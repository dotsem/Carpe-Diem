import 'package:flutter/material.dart';
import 'package:carpe_diem/features/command_palette/models/palette_command.dart';

class CommandPaletteListTile extends StatelessWidget {
  final PaletteCommand command;
  final bool isSelected;
  final VoidCallback onTap;

  const CommandPaletteListTile({
    super.key,
    required this.command,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.6)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              command.icon,
              size: 20,
              color:
                  command.iconColor ??
                  (isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    command.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                  if (command.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      command.subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.8,
                              )
                            : colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              command.category.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.keyboard_return, size: 14, color: colorScheme.primary),
            ],
          ],
        ),
      ),
    );
  }
}
