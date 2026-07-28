import 'package:flutter/material.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';

class TriStateFilterChip extends StatelessWidget {
  final String label;
  final bool isIncluded;
  final bool isExcluded;
  final bool isInherited;
  final bool isIgnored;
  final bool isBypassed;
  final Widget? avatar;
  final Color? color;
  final FilterInteractionMethod interactionMethod;
  final VoidCallback? onCycle;
  final VoidCallback? onLeftClick;
  final VoidCallback? onRightClick;
  final VoidCallback? onTap;
  final String? tooltip;

  const TriStateFilterChip({
    super.key,
    required this.label,
    this.isIncluded = false,
    this.isExcluded = false,
    this.isInherited = false,
    this.isIgnored = false,
    this.isBypassed = false,
    this.avatar,
    this.color,
    this.interactionMethod = FilterInteractionMethod.cycle,
    this.onCycle,
    this.onLeftClick,
    this.onRightClick,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final includedColor = isDark ? Colors.greenAccent : Colors.green.shade700;
    final excludedColor = isDark ? Colors.redAccent : Colors.red.shade700;

    final isDisabled = isInherited || isIgnored || isBypassed;
    final displayLabel = isExcluded
        ? '- $label'
        : (isIncluded ? '+ $label' : label);

    final textColor = isDisabled
        ? Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(150)
        : (isExcluded
              ? excludedColor
              : (isIncluded
                    ? includedColor
                    : Theme.of(context).colorScheme.onSurfaceVariant));

    final backgroundColor = isDisabled
        ? Theme.of(context).colorScheme.surfaceContainerHigh
        : (isExcluded
              ? excludedColor.withAlpha(30)
              : (isIncluded
                    ? includedColor.withAlpha(30)
                    : Theme.of(context).colorScheme.surfaceContainerHigh));

    final side = isDisabled
        ? BorderSide.none
        : (isExcluded
              ? BorderSide(color: excludedColor)
              : (isIncluded
                    ? BorderSide(color: includedColor)
                    : BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      )));

    final textStyle = TextStyle(
      fontSize: 13,
      fontWeight: (isIncluded || isExcluded)
          ? FontWeight.bold
          : FontWeight.normal,
      decoration: (isDisabled || isExcluded)
          ? TextDecoration.lineThrough
          : null,
      color: textColor,
    );

    final bool isClickable =
        !isDisabled &&
        (onTap != null ||
            onCycle != null ||
            onLeftClick != null ||
            onRightClick != null);

    final chipAvatar =
        avatar ??
        (color != null
            ? CircleAvatar(
                backgroundColor: isDisabled ? color!.withAlpha(128) : color,
                radius: 4,
              )
            : null);

    Widget chip = GestureDetector(
      onSecondaryTap: isDisabled
          ? null
          : () {
              if (interactionMethod == FilterInteractionMethod.leftRightClick) {
                onRightClick?.call();
              }
            },
      child: RawChip(
        label: Text(displayLabel, style: textStyle),
        avatar: chipAvatar,
        backgroundColor: backgroundColor,
        side: side,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        visualDensity: VisualDensity.compact,
        showCheckmark: false,
        mouseCursor: isClickable
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onPressed: isDisabled
            ? null
            : () {
                if (onTap != null) {
                  onTap!();
                } else if (interactionMethod == FilterInteractionMethod.cycle) {
                  onCycle?.call();
                } else {
                  onLeftClick?.call();
                }
              },
      ),
    );

    if (tooltip != null) {
      chip = Tooltip(message: tooltip!, child: chip);
    }

    return chip;
  }
}
