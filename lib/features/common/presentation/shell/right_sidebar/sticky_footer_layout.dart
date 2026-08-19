import 'package:flutter/material.dart';

class StickyFooterLayout extends StatelessWidget {
  final Widget child;
  final Widget footer;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry footerPadding;

  const StickyFooterLayout({
    super.key,
    required this.child,
    required this.footer,
    this.contentPadding = const EdgeInsets.all(8),
    this.footerPadding = const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 12,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(padding: contentPadding, child: child),
        ),
        const Divider(height: 1),
        Container(
          padding: footerPadding,
          color: theme.colorScheme.surface,
          child: footer,
        ),
      ],
    );
  }
}
