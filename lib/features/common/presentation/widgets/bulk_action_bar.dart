import 'dart:ui';

import 'package:flutter/material.dart';

/// Floating pill that shows a selection [label], a clear button and [actions].
///
/// It knows nothing about what is selected; callers decide the actions.
class BulkActionBar extends StatelessWidget {
  final String label;
  final VoidCallback onClearSelection;
  final List<Widget> actions;

  const BulkActionBar({
    required this.label,
    required this.onClearSelection,
    this.actions = const [],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer.withValues(
                  alpha: 0.25,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Clear selection',
                    onPressed: onClearSelection,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    height: 24,
                    width: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  for (final action in actions) ...[
                    const SizedBox(width: 8),
                    action,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
