import 'package:flutter/material.dart';

class SectionItem {
  final IconData icon;
  final String title;
  final Widget child;

  const SectionItem({required this.icon, required this.title, required this.child});
}

class SectionCard extends StatelessWidget {
  final List<SectionItem> items;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const SectionCard({super.key, required this.items, this.padding = const EdgeInsets.all(12), this.margin});

  factory SectionCard.single({
    Key? key,
    required IconData icon,
    required String title,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
  }) {
    return SectionCard(
      key: key,
      items: [SectionItem(icon: icon, title: title, child: child)],
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(item.icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              item.child,
              if (!isLast) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
            ],
          );
        }),
      ),
    );
  }
}
