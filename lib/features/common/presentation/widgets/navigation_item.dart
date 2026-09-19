import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/shortcut_hint_badge.dart';
import 'package:flutter/material.dart';

class NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? iconColor;
  final double iconSize;
  final EdgeInsets? outerPadding;
  final String? shortcutHint;

  const NavigationItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.iconColor,
    this.iconSize = 20,
    this.outerPadding,
    this.shortcutHint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          outerPadding ??
          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected
            ? AppColors.accent.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                      iconColor ??
                      (isSelected
                          ? AppColors.accent
                          : Theme.of(context).colorScheme.onSurfaceVariant),
                  size: iconSize,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.accent
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (shortcutHint != null)
                  ShortcutHintBadge(
                    label: shortcutHint!,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    fontSize: 12,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
