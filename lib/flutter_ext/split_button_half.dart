import 'package:flutter/material.dart';

enum SplitSide { leading, trailing }

/// One half of a split button: rounded outer corner, tight inner corner.
class SplitButtonHalf extends StatelessWidget {
  final SplitSide side;
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;

  const SplitButtonHalf({
    required this.side,
    required this.onPressed,
    required this.child,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const outer = Radius.circular(16);
    const inner = Radius.circular(4);
    final leading = side == SplitSide.leading;

    final style = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.horizontal(
          start: leading ? outer : inner,
          end: leading ? inner : outer,
        ),
      ),
      backgroundColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.3),
    );

    final icon = this.icon;
    if (icon == null) {
      return ElevatedButton(onPressed: onPressed, style: style, child: child);
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: style,
      icon: icon,
      label: child,
    );
  }
}
