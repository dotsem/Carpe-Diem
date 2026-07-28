import 'package:carpe_diem/features/filter/presentation/providers/filter_accordion_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterAccordionSection extends ConsumerWidget {
  final String title;
  final String categoryKey;
  final int includedCount;
  final int excludedCount;
  final bool initiallyExpanded;
  final Widget child;

  const FilterAccordionSection({
    super.key,
    required this.title,
    required this.categoryKey,
    this.includedCount = 0,
    this.excludedCount = 0,
    this.initiallyExpanded = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(
      filterAccordionProvider.select(
        (map) => map[categoryKey] ?? initiallyExpanded,
      ),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final incColor = isDark ? Colors.greenAccent : Colors.green.shade700;
    final excColor = isDark ? Colors.redAccent : Colors.red.shade700;

    final hasIncluded = includedCount > 0;
    final hasExcluded = excludedCount > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            ref
                .read(filterAccordionProvider.notifier)
                .toggle(categoryKey, initiallyExpanded);
          },
          borderRadius: BorderRadius.circular(6),
          mouseCursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedOpacity(
                  opacity: !isExpanded && (hasIncluded || hasExcluded)
                      ? 1.0
                      : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasIncluded)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: incColor.withAlpha(35),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: incColor, width: 1),
                          ),
                          child: Text(
                            '+$includedCount',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: incColor,
                            ),
                          ),
                        ),
                      if (hasExcluded)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: excColor.withAlpha(35),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: excColor, width: 1),
                          ),
                          child: Text(
                            '-$excludedCount',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: excColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: isExpanded ? 0.0 : 0.5,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: isExpanded
              ? Padding(padding: const EdgeInsets.only(top: 8), child: child)
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}
