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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void show() {
    setState(() => _visible = true);
    _controller.forward();
  }

  void hide() {
    _controller.reverse().then((_) {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: () => GlobalShortcuts.of(context).toggleHelp(),
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(child: _buildContent()),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final grouped = <String, List<ShortcutEntry>>{};
    for (final entry in allShortcutEntries) {
      grouped.putIfAbsent(entry.category, () => []).add(entry);
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight, width: 1),
      ),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
              ),
              const Spacer(),
              _KeyBadge(label: 'Esc'),
              const SizedBox(width: 8),
              const Text('to close', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 24),
          ...grouped.entries.map((group) => _buildGroup(group.key, group.value)),
        ],
      ),
    );
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
          Wrap(spacing: 24, runSpacing: 4, children: entries.map((e) => _buildEntry(e)).toList()),
        ],
      ),
    );
  }

  Widget _buildEntry(ShortcutEntry entry) {
    return SizedBox(
      width: 220,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _KeyBadge(label: entry.key),
            const SizedBox(width: 12),
            Flexible(
              child: Text(entry.description, style: const TextStyle(color: AppColors.text, fontSize: 14)),
            ),
          ],
        ),
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.surfaceLight, width: 1),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
