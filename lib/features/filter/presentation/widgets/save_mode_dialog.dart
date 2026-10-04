import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:carpe_diem/features/filter/presentation/constants/illegal_mode_names.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_modes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SaveModeDialog extends ConsumerStatefulWidget {
  final String? initialName;

  const SaveModeDialog({super.key, this.initialName});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SaveModeDialogState();
}

class _SaveModeDialogState extends ConsumerState<SaveModeDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Mode name cannot be empty');
      return;
    }
    if (isIllegalModeName(text)) {
      setState(() => _error = 'This mode name is reserved for internal use');
      return;
    }
    if (ref
        .watch(filterModesProvider)
        .modes
        .any((m) => m.name.toLowerCase() == text.toLowerCase())) {
      setState(() => _error = 'A mode with this name already exists');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return SizedDialog(
      title: widget.initialName == null ? 'Save as Mode' : 'Rename Mode',
      maxWidth: 400,
      onSubmit: _submit,
      onCancel: () => Navigator.of(context).pop(),
      submitText: 'Save',
      child: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Mode Name',
          hintText: 'e.g. Work, School, Free Time',
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}
