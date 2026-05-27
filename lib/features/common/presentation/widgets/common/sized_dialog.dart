import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _SubmitIntent extends Intent {
  const _SubmitIntent();
}

class _SubmitAction extends Action<_SubmitIntent> {
  final VoidCallback onSubmit;

  _SubmitAction(this.onSubmit);

  @override
  Object? invoke(_SubmitIntent intent) {
    onSubmit();
    return null;
  }
}

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
  final FocusScopeNode _focusScopeNode = FocusScopeNode(debugLabel: 'SizedDialogScope');

  @override
  void dispose() {
    _focusScopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth, minWidth: widget.minWidth ?? 0),
      child: Padding(padding: widget.padding!, child: widget.child),
    );

    final dialog = AlertDialog(
      title: widget.title != null ? Text(widget.title!) : null,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: widget.onSubmit != null
          ? GestureDetector(
              onTap: () => _focusScopeNode.requestFocus(),
              behavior: HitTestBehavior.opaque,
              child: content,
            )
          : content,
      actions: (widget.actions != null || widget.onCancel != null || widget.onSubmit != null)
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
                        onPressed: widget.onCancel ?? () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: widget.onSubmit ?? () => Navigator.pop(context),
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

    if (widget.onSubmit == null) return dialog;

    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): const _SubmitIntent(),
        const SingleActivator(LogicalKeyboardKey.numpadEnter, control: true): const _SubmitIntent(),
      },
      child: Actions(
        actions: {_SubmitIntent: _SubmitAction(widget.onSubmit!)},
        child: FocusScope(node: _focusScopeNode, autofocus: true, child: dialog),
      ),
    );
  }
}
