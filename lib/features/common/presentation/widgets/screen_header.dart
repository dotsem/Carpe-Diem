import 'package:flutter/material.dart';

class ScreenHeader extends StatelessWidget {
  final dynamic title; // String or Widget
  final dynamic subtitle; // String or Widget (optional)
  final List<Widget>? actions;
  final EdgeInsets? padding;

  const ScreenHeader({super.key, required this.title, this.subtitle, this.actions, this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title is String)
                  Text(
                    title as String,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (title is Widget)
                  title as Widget,
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  if (subtitle is String)
                    Text(subtitle as String, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
                  else if (subtitle is Widget)
                    subtitle as Widget,
                ],
              ],
            ),
          ),
          if (actions != null) ...[const SizedBox(width: 16), ...actions!],
        ],
      ),
    );
  }
}
