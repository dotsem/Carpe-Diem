import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/filter/data/models/filter_mode.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_modes_provider.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/routes/keys.dart';

class ModeSelectionDialog extends ConsumerStatefulWidget {
  const ModeSelectionDialog({super.key});

  static Future<void> show([BuildContext? context]) {
    final targetContext = context ?? rootNavigatorKey.currentContext;
    if (targetContext == null) return Future.value();
    return showDialog(
      context: targetContext,
      useRootNavigator: true,
      builder: (_) => const ModeSelectionDialog(),
    );
  }

  @override
  ConsumerState<ModeSelectionDialog> createState() =>
      _ModeSelectionDialogState();
}

class _ModeSelectionDialogState extends ConsumerState<ModeSelectionDialog> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'ModeSelectionFocus');
  int _selectedIndex = 0;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _selectMode(FilterMode? mode) {
    if (mode == null) {
      ref.read(filterProvider.notifier).clearFilter();
      ref.read(filterModesProvider.notifier).setActiveModeId(null);
    } else {
      ref.read(filterProvider.notifier).setFilter(mode.filter);
      ref.read(filterModesProvider.notifier).setActiveModeId(mode.id);
    }
    Navigator.of(context, rootNavigator: true).pop();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final modes = ref.read(filterModesProvider).modes;
    final totalItems = modes.length + 1; // 0 is No Mode

    // Number keys: 0 for No Mode, 1..9 for modes
    if (event.logicalKey == LogicalKeyboardKey.digit0 ||
        event.logicalKey == LogicalKeyboardKey.numpad0) {
      _selectMode(null);
      return KeyEventResult.handled;
    }

    final digitKeys = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    final numpadKeys = [
      LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4,
      LogicalKeyboardKey.numpad5,
      LogicalKeyboardKey.numpad6,
      LogicalKeyboardKey.numpad7,
      LogicalKeyboardKey.numpad8,
      LogicalKeyboardKey.numpad9,
    ];

    for (int i = 0; i < 9; i++) {
      if (event.logicalKey == digitKeys[i] ||
          event.logicalKey == numpadKeys[i]) {
        if (i < modes.length) {
          _selectMode(modes[i]);
          return KeyEventResult.handled;
        }
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.keyJ) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % totalItems;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.keyK) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1 + totalItems) % totalItems;
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_selectedIndex == 0) {
        _selectMode(null);
      } else if (_selectedIndex - 1 < modes.length) {
        _selectMode(modes[_selectedIndex - 1]);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modes = ref.watch(filterModesProvider).modes;
    final activeMode = ref.watch(activeFilterModeProvider);
    final currentFilter = ref.watch(filterProvider).filter;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.tune, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Switch Filter Mode', style: TextStyle(fontSize: 18)),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeTile(
                  title: 'No Mode',
                  icon: Icons.filter_alt_off_outlined,
                  shortcutNum: '0',
                  isSelected: _selectedIndex == 0,
                  isActive: activeMode == null && currentFilter.isEmpty,
                  onTap: () => _selectMode(null),
                ),
                if (modes.isNotEmpty) const Divider(height: 1),
                for (int i = 0; i < modes.length; i++)
                  _buildModeTile(
                    title: modes[i].name,
                    icon: modes[i].icon ?? Icons.tune,
                    shortcutNum: i < 9 ? '${i + 1}' : null,
                    isSelected: _selectedIndex == i + 1,
                    isActive: activeMode?.id == modes[i].id,
                    onTap: () => _selectMode(modes[i]),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTile({
    required String title,
    required IconData icon,
    required String? shortcutNum,
    required bool isSelected,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Colors.transparent,
        child: Row(
          children: [
            if (shortcutNum != null)
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  shortcutNum,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isActive)
              Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
