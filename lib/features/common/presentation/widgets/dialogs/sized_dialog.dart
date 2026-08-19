import 'package:carpe_diem/features/common/presentation/shortcuts/hardware_shortcuts.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SizedDialog extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool showDefaultActions;
  final VoidCallback? onSubmit;
  final VoidCallback? onCancel;
  final String submitText;
  final ButtonStyle? submitStyle;
  final EdgeInsets? padding;
  final double maxWidth;
  final double? minWidth;

  const SizedDialog({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.onSubmit,
    this.onCancel,
    this.submitText = 'Confirm',
    this.submitStyle,
    this.padding = const EdgeInsets.all(24),
    this.maxWidth = 640,
    this.minWidth,
    this.showDefaultActions = true,
  });

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent || !isControlOrMetaPressed()) return false;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      onSubmit?.call();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, minWidth: minWidth ?? 0),
      child: SingleChildScrollView(padding: padding!, child: child),
    );

    final dialog = AlertDialog(
      title: title != null ? Text(title!) : null,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: content,
      actions: (actions != null || onCancel != null || onSubmit != null)
          ? [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (actions != null) ...actions!,
                    if (showDefaultActions) ...[
                      const Spacer(),
                      TextButton(
                        onPressed:
                            onCancel ??
                            () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed:
                            onSubmit ??
                            () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                        style: submitStyle,
                        child: Text(submitText),
                      ),
                    ],
                  ],
                ),
              ),
            ]
          : null,
    );

    if (onSubmit == null) return dialog;

    return HardwareShortcuts(onKeyEvent: _handleKeyEvent, child: dialog);
  }
}
