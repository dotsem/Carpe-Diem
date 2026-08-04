import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/color_picker.dart';
import 'package:carpe_diem/features/common/presentation/widgets/date_picker_button.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/urgency_selector.dart';
import 'package:carpe_diem/features/labels/presentation/widgets/label_picker.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/sticky_footer_layout.dart';

class ProjectFormPanel extends ConsumerStatefulWidget {
  final Project? project;

  const ProjectFormPanel({super.key, this.project});

  @override
  ConsumerState<ProjectFormPanel> createState() => _ProjectFormPanelState();
}

class _ProjectFormPanelState extends ConsumerState<ProjectFormPanel> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  late Color _selectedColor;
  late bool _isUrgent;
  List<String> _selectedLabelIds = [];
  DateTime? _deadline;
  late bool _isActive;

  bool get isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    if (p != null) {
      _nameController.text = p.name;
      _descController.text = p.description ?? '';
      _selectedColor = p.color;
      _isUrgent = p.isUrgent;
      _selectedLabelIds = List<String>.from(p.labelIds);
      _deadline = p.deadline;
      _isActive = p.isActive;
    } else {
      _selectedColor = AppColors.accent;
      _isUrgent = false;
      _selectedLabelIds = [];
      _deadline = null;
      _isActive = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StickyFooterLayout(
      footer: Row(
        children: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete Project',
              style: IconButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              onPressed: _onDelete,
            ),
          const Spacer(),
          TextButton(
            onPressed: () =>
                ref.read(rightSidebarProvider.notifier).close(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _submit,
            child: Text(isEditing ? 'Save Changes' : 'Create Project'),
          ),
        ],
      ),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(
            LogicalKeyboardKey.digit1,
            control: true,
          ): () => setState(() => _isUrgent = false),
          const SingleActivator(
            LogicalKeyboardKey.digit2,
            control: true,
          ): () => setState(() => _isUrgent = true),
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Project name'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                hintText: 'Description (optional)',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Text('Color', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            ProjectColorPicker(
              selected: _selectedColor,
              onChanged: (c) => setState(() => _selectedColor = c),
            ),
            const SizedBox(height: 16),
            Text('Urgency', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            UrgencySelector(
              selected: _isUrgent,
              onChanged: (v) => setState(() => _isUrgent = v!),
              allowAll: false,
            ),
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
              firstDate: widget.project?.createdAt,
            ),
            if (isEditing) ...[
              const SizedBox(height: 16),
              _ActiveToggle(
                isActive: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onDelete() {
    final p = widget.project;
    if (p == null) return;

    showDialog(
      context: context,
      builder: (ctx) => DeleteDialog(
        title: 'Delete Project',
        message: 'Are you sure you want to delete this project?',
        onConfirm: () async {
          final provider = ref.read(projectProvider.notifier);
          await provider.deleteProject(p);
          if (ctx.mounted) {
            Navigator.of(ctx).pop();
          }
          ref.read(rightSidebarProvider.notifier).close();
        },
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    if (isEditing) {
      final p = widget.project!;
      final updatedProject = Project(
        id: p.id,
        name: name,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        color: _selectedColor,
        isUrgent: _isUrgent,
        labelIds: _selectedLabelIds,
        deadline: _deadline,
        createdAt: p.createdAt,
        updatedAt: DateTime.now(),
        isActive: _isActive,
      );
      ref.read(projectProvider.notifier).updateProject(updatedProject);
    } else {
      ref.read(projectProvider.notifier).addProject(
            name: name,
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            color: _selectedColor,
            isUrgent: _isUrgent,
            labelIds: _selectedLabelIds,
            deadline: _deadline,
          );
    }

    ref.read(rightSidebarProvider.notifier).close();
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
                  const Text(
                    'Project status',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    isActive
                        ? 'Tasks can be added to this project'
                        : 'Project is archived. Tasks cannot be added.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
