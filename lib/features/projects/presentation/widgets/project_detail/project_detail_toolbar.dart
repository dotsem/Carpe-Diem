import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/filter_bar.dart';
import 'package:dotmaterial/dotmaterial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Search bar and filter bar under the project detail header.
class ProjectDetailToolbar extends ConsumerWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final int hiddenCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onShowFilter;

  const ProjectDetailToolbar({
    required this.searchController,
    required this.searchFocusNode,
    required this.hiddenCount,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onShowFilter,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final divider = Divider(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      height: 1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        divider,
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: FuzzySearchBar(
            controller: searchController,
            focusNode: searchFocusNode,
            hintText: 'Search backlog tasks... (Press / to focus)',
            onChanged: onSearchChanged,
            onSubmitted: onSearchSubmitted,
          ),
        ),
        FilterBar(
          filter: ref.watch(filterProvider).filter,
          isBypassed: ref.watch(filterProvider).isBypassed,
          ignoreProjects: true,
          hiddenCount: hiddenCount,
          hiddenItemType: 'tasks',
          onFilterTap: onShowFilter,
          onClearFilter: () => ref.read(filterProvider.notifier).clearFilter(),
        ),
        divider,
      ],
    );
  }
}
