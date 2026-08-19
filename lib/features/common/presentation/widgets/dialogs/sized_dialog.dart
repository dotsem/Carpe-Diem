import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SizedDialog extends StatefulWidget {
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

  @override
  State<SizedDialog> createState() => _SizedDialogState();
}

class _SizedDialogState extends State<SizedDialog> {
  @override
  void initState() {
    super.initState();
    if (widget.onSubmit != null) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    }
  }

  @override
  void didUpdateWidget(SizedDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onSubmit == null && widget.onSubmit != null) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    } else if (oldWidget.onSubmit != null && widget.onSubmit == null) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isMeta = HardwareKeyboard.instance.isMetaPressed;
    if (!isCtrl && !isMeta) return false;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      widget.onSubmit?.call();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth,
        minWidth: widget.minWidth ?? 0,
      ),
      child: SingleChildScrollView(
        padding: widget.padding!,
        child: widget.child,
      ),
    );

    return AlertDialog(
      title: widget.title != null ? Text(widget.title!) : null,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: content,
      actions:
          (widget.actions != null ||
              widget.onCancel != null ||
              widget.onSubmit != null)
          ? [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.actions != null) ...widget.actions!,
                    if (widget.showDefaultActions) ...[
                      const Spacer(),
                      TextButton(
                        onPressed:
                            widget.onCancel ??
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
                            widget.onSubmit ??
                            () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                        style: widget.submitStyle,
                        child: Text(widget.submitText),
                      ),
                    ],
                  ],
                ),
              ),
            ]
          : null,
    );
  }
}
