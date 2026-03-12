import 'package:carpe_diem/core/theme/app_theme.dart';
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
  final EdgeInsets? padding;
  final double maxWidth;
  final double? minWidth;
  final VoidCallback? onSubmit;

  const SizedDialog({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.maxWidth = 640,
    this.minWidth,
    this.onSubmit,
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
      contentPadding: EdgeInsets.zero,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: widget.onSubmit != null
          ? GestureDetector(
              onTap: () => _focusScopeNode.requestFocus(),
              behavior: HitTestBehavior.opaque,
              child: content,
            )
          : content,
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
