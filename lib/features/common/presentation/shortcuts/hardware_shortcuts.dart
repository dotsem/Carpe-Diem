import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HardwareShortcuts extends StatefulWidget {
  final Widget child;
  final bool Function(KeyEvent event) onKeyEvent;
  final bool enabled;

  const HardwareShortcuts({
    super.key,
    required this.child,
    required this.onKeyEvent,
    this.enabled = true,
  });

  @override
  State<HardwareShortcuts> createState() => _HardwareShortcutsState();
}

class _HardwareShortcutsState extends State<HardwareShortcuts> {
  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    }
  }

  @override
  void didUpdateWidget(HardwareShortcuts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.enabled && widget.enabled) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    } else if (oldWidget.enabled && !widget.enabled) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }
  }

  @override
  void dispose() {
    if (widget.enabled) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!widget.enabled) return false;
    return widget.onKeyEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
