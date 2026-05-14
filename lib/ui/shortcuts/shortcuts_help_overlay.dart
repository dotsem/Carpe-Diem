import 'package:flutter/material.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/ui/shortcuts/app_shortcuts.dart';

class ShortcutsHelpOverlay extends StatefulWidget {
  const ShortcutsHelpOverlay({super.key});

  @override
  State<ShortcutsHelpOverlay> createState() => ShortcutsHelpOverlayState();
}

class ShortcutsHelpOverlayState extends State<ShortcutsHelpOverlay> with SingleTickerProviderStateMixin {
  bool _visible = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final FocusNode _focusNode = FocusNode(debugLabel: 'ShortcutsHelpOverlay');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  FocusNode? _previousFocus;

  void show() {
    if (_visible) return;
    _previousFocus = FocusManager.instance.primaryFocus;
    setState(() => _visible = true);
    _controller.forward();
    _focusNode.requestFocus();
  }

  void hide() {
    if (!_visible) return;
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() => _visible = false);
        _previousFocus?.requestFocus();
        _previousFocus = null;
      }
    });
  }

  void updateContent() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Focus(
      focusNode: _focusNode,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: () => GlobalShortcuts.of(context).toggleHelp(),
          child: Material(
            color: Colors.black.withValues(alpha: 0.7),
            child: Center(child: _buildContent()),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final globalShortcuts = globalShortcutEntries;
    final contextualShortcuts = GlobalShortcuts.of(context).contextualShortcuts;

    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHigh, width: 1),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.keyboard_rounded, color: AppColors.accent, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Keyboard Shortcuts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                ),
                const Spacer(),
                _KeyBadge(label: 'Esc'),
                const SizedBox(width: 8),
                Text('to close', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader('GLOBAL SHORTCUTS'),
                      ..._groupShortcuts(globalShortcuts),
                    ],
                  ),
                ),
                if (contextualShortcuts.isNotEmpty) ...[
                  const SizedBox(width: 32),
                  Container(width: 1, height: 400, color: Theme.of(context).colorScheme.surfaceContainerHigh),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader('CONTEXTUAL SHORTCUTS'),
                        ..._groupShortcuts(contextualShortcuts),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  List<Widget> _groupShortcuts(List<ShortcutEntry> entries) {
    final grouped = <String, List<ShortcutEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.category, () => []).add(entry);
    }
    return grouped.entries.map((group) => _buildGroup(group.key, group.value)).toList();
  }

  Widget _buildGroup(String title, List<ShortcutEntry> entries) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          ...entries.map((e) => _buildEntry(e)),
        ],
      ),
    );
  }

  Widget _buildEntry(ShortcutEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _KeyBadge(label: entry.key),
          const SizedBox(width: 12),
          Flexible(
            child: Text(entry.description, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}


class _KeyBadge extends StatelessWidget {
  final String label;

  const _KeyBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHigh, width: 1),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
