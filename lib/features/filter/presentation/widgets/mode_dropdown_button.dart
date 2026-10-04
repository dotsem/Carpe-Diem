import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:carpe_diem/features/filter/data/models/filter_mode.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_modes_provider.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/presentation/widgets/save_mode_dialog.dart';

class ModeDropdownButton extends ConsumerWidget {
  const ModeDropdownButton({super.key});

  Future<void> _handleSaveMode(BuildContext context, WidgetRef ref) async {
    final currentFilter = ref.read(filterProvider).filter;
    if (currentFilter.isEmpty) return;

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => const SaveModeDialog(),
    );
    if (name != null && name.isNotEmpty) {
      await ref
          .read(filterModesProvider.notifier)
          .createMode(name: name, filter: currentFilter);
    }
  }

  void _handleManageModes(BuildContext context) {
    context.go('/settings?section=filteringAndModes');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filter = ref.watch(filterProvider).filter;
    final modes = ref.watch(filterModesProvider).modes;
    final activeMode = ref.watch(activeFilterModeProvider);

    final String modeLabel;
    final bool isCustom;
    if (activeMode != null) {
      modeLabel = activeMode.name;
      isCustom = false;
    } else if (filter.isEmpty) {
      modeLabel = 'No Mode';
      isCustom = false;
    } else {
      modeLabel = 'Custom';
      isCustom = true;
    }

    final bool hasActiveHighlight = activeMode != null || isCustom;

    return PopupMenuButton<String>(
      tooltip: 'Switch filter mode',
      onSelected: (value) async {
        if (value == '_no_mode') {
          ref.read(filterProvider.notifier).clearFilter();
        } else if (value == '_save') {
          await _handleSaveMode(context, ref);
        } else if (value == '_manage') {
          _handleManageModes(context);
        } else {
          FilterMode? mode;
          for (final m in modes) {
            if (m.id == value) {
              mode = m;
              break;
            }
          }
          if (mode != null) {
            ref.read(filterProvider.notifier).setFilter(mode.filter);
          }
        }
      },
      itemBuilder: (context) {
        return [
          CheckedPopupMenuItem<String>(
            value: '_no_mode',
            checked: filter.isEmpty,
            child: const Text('No Mode'),
          ),
          for (final mode in modes)
            CheckedPopupMenuItem<String>(
              value: mode.id,
              checked: activeMode?.id == mode.id,
              child: Text(mode.name),
            ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: '_save',
            enabled: !filter.isEmpty,
            child: const Row(
              children: [
                Icon(Icons.bookmark_add_outlined, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('Save as mode...')),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: '_manage',
            child: Row(
              children: [
                Icon(Icons.settings_outlined, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('Manage modes...')),
              ],
            ),
          ),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hasActiveHighlight
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune,
              size: 16,
              color: hasActiveHighlight
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'Mode: $modeLabel',
              style: TextStyle(
                fontSize: 13,
                fontWeight: hasActiveHighlight
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: hasActiveHighlight
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: hasActiveHighlight
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
