import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/common/sized_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/common/delete_dialog.dart';
import 'package:carpe_diem/features/common/presentation/shortcuts/app_shortcuts.dart';
import 'package:carpe_diem/features/common/presentation/widgets/color_picker.dart';
import 'package:carpe_diem/features/common/presentation/widgets/priority_picker.dart';
import 'package:carpe_diem/features/labels/presentation/widgets/label_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carpe_diem/features/common/presentation/widgets/date_picker_button.dart';
import 'package:carpe_diem/core/utils/toast_utils.dart';
import 'package:provider/provider.dart';

class EditProjectDialog extends StatefulWidget {
  final Project project;
  const EditProjectDialog({super.key, required this.project});

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  late Color _selectedColor;
  late Priority _priority;
  List<String> _selectedLabelIds = [];
  DateTime? _deadline;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.project.name;
    _descController.text = widget.project.description ?? '';
    _selectedColor = widget.project.color;
    _priority = widget.project.priority;
    _selectedLabelIds = List<String>.from(widget.project.labelIds);
    _deadline = widget.project.deadline;
    _isActive = widget.project.isActive;
  }

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
        title: 'Edit Project',
        onSubmit: _submit,
        submitText: 'Save Changes',
        actions: [
          TextButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => DeleteDialog(
                title: 'Delete Project',
                message: 'Are you sure you want to delete this project?',
                onConfirm: () async {
                  final provider = context.read<ProjectProvider>();
                  await provider.deleteProject(widget.project);
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Pop from edit dialog
                    ToastUtils.showSuccess('Project "${widget.project.name}" deleted', context: context);
                  }
                },
              ),
            ),
            icon: const Icon(Icons.delete),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            label: const Text("Delete"),
          ),
        ],
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
              DatePickerButton(
                label: 'Deadline',
                date: _deadline,
                onChanged: (d) => setState(() => _deadline = d),
                firstDate: widget.project.createdAt,
              ),
              const SizedBox(height: 16),
              _ActiveToggle(isActive: _isActive, onChanged: (v) => setState(() => _isActive = v)),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final project = Project(
      id: widget.project.id,
      name: name,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      color: _selectedColor,
      priority: _priority,
      labelIds: _selectedLabelIds,
      deadline: _deadline,
      createdAt: widget.project.createdAt,
      updatedAt: DateTime.now(),
      isActive: _isActive,
    );
    context.read<ProjectProvider>().updateProject(project);
    Navigator.of(context).pop();
  }
}

class _ActiveToggle extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const _ActiveToggle({required this.isActive, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!isActive),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Project status', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    isActive ? 'Tasks can be added to this project' : 'Project is archived. Tasks cannot be added.',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Switch(value: isActive, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
