import 'package:carpe_diem/ui/shortcuts/app_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/data/models/priority.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:carpe_diem/ui/widgets/priority_picker.dart';
import 'package:carpe_diem/ui/widgets/color_picker.dart';
import 'package:carpe_diem/ui/widgets/label_picker.dart';
import 'package:carpe_diem/ui/widgets/date_picker_button.dart';
import 'package:carpe_diem/ui/dialogs/common/sized_dialog.dart';

class AddProjectDialog extends StatefulWidget {
  const AddProjectDialog({super.key});

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  Color _selectedColor = AppColors.accent;
  Priority _priority = Priority.none;
  List<String> _selectedLabelIds = [];
  DateTime? _deadline;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShortcutRegistrar(
      shortcuts: projectDialogShortcutEntries,
      child: SizedDialog(
        title: 'New Project',
        onSubmit: _submit,
        submitText: 'Create Project',
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
                setState(() => _priority = Priority.none),
            const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
                setState(() => _priority = Priority.low),
            const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
                setState(() => _priority = Priority.medium),
            const SingleActivator(LogicalKeyboardKey.digit4, control: true): () =>
                setState(() => _priority = Priority.high),
            const SingleActivator(LogicalKeyboardKey.digit5, control: true): () =>
                setState(() => _priority = Priority.urgent),
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Project name'),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(hintText: 'Description (optional)'),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text('Color', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              ProjectColorPicker(selected: _selectedColor, onChanged: (c) => setState(() => _selectedColor = c)),
              const SizedBox(height: 16),
              Text('Priority', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              PriorityPicker(selected: _priority, onChanged: (p) => setState(() => _priority = p)),
              const SizedBox(height: 16),
              Text('Labels', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              LabelPicker(
                selectedLabelIds: _selectedLabelIds,
                onSelected: (ids) => setState(() => _selectedLabelIds = ids),
              ),
              const SizedBox(height: 16),
              DatePickerButton(label: 'Deadline', date: _deadline, onChanged: (d) => setState(() => _deadline = d)),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    context.read<ProjectProvider>().addProject(
      name: name,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      color: _selectedColor,
      priority: _priority,
      labelIds: _selectedLabelIds,
      deadline: _deadline,
    );
    Navigator.of(context).pop();
  }
}
