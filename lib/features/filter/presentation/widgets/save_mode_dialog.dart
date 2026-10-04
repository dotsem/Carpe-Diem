import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/icon_picker.dart';
import 'package:carpe_diem/features/filter/presentation/constants/illegal_mode_names.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_modes_provider.dart';
import 'package:carpe_diem/features/tags/presentation/constants/tag_icon_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SaveModeResult {
  final String name;
  final int iconCodePoint;

  const SaveModeResult({required this.name, required this.iconCodePoint});

  IconData get icon => availableIconMap[iconCodePoint] ?? Icons.tune;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveModeResult &&
          other.name == name &&
          other.iconCodePoint == iconCodePoint;

  @override
  int get hashCode => Object.hash(name, iconCodePoint);
}

class SaveModeDialog extends ConsumerStatefulWidget {
  final String? initialName;
  final int? initialIconCodePoint;

  const SaveModeDialog({
    super.key,
    this.initialName,
    this.initialIconCodePoint,
  });

  @override
  ConsumerState<SaveModeDialog> createState() => _SaveModeDialogState();
}

class _SaveModeDialogState extends ConsumerState<SaveModeDialog> {
  late final TextEditingController _controller;
  late IconData _selectedIcon;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
    _selectedIcon = widget.initialIconCodePoint != null
        ? (availableIconMap[widget.initialIconCodePoint] ?? Icons.tune)
        : Icons.tune;
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
    final modes = ref.watch(filterModesProvider).modes;
    final isDuplicate = modes.any(
      (m) =>
          m.name.toLowerCase() == text.toLowerCase() &&
          m.name.toLowerCase() != (widget.initialName ?? '').toLowerCase(),
    );
    if (isDuplicate) {
      setState(() => _error = 'A mode with this name already exists');
      return;
    }
    Navigator.of(
      context,
    ).pop(SaveModeResult(name: text, iconCodePoint: _selectedIcon.codePoint));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedDialog(
      title: widget.initialName == null ? 'Save as Mode' : 'Edit Mode',
      maxWidth: 500,
      onSubmit: _submit,
      onCancel: () => Navigator.of(context).pop(),
      submitText: 'Save',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Mode Name',
              hintText: 'e.g. Work, School, Free Time',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Text(
            'Mode Icon',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          IconPicker(
            selected: _selectedIcon,
            onChanged: (icon) => setState(() => _selectedIcon = icon),
          ),
        ],
      ),
    );
  }
}
