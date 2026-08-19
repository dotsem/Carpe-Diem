import 'package:carpe_diem/features/common/presentation/shortcuts/shortcut_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/features/common/presentation/widgets/color_picker.dart';
import 'package:carpe_diem/features/common/presentation/widgets/date_picker_button.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/delete_dialog.dart';
import 'package:carpe_diem/features/common/presentation/widgets/urgency_selector.dart';
import 'package:carpe_diem/features/labels/presentation/widgets/label_picker.dart';
import 'package:carpe_diem/features/common/presentation/widgets/section_card.dart';
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
  String? _nameError;

  bool get isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
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

  void _onNameChanged() {
    if (_nameError != null && _nameController.text.trim().isNotEmpty) {
      setState(() => _nameError = null);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
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
              style: IconButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: _onDelete,
            ),
          const Spacer(),
          TextButton(
            onPressed: () => ref.read(rightSidebarProvider.notifier).close(),
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
          const SingleActivator(AppKeyBindings.digit1, control: true): () =>
              setState(() => _isUrgent = false),
          const SingleActivator(AppKeyBindings.digit1, meta: true): () =>
              setState(() => _isUrgent = false),
          const SingleActivator(AppKeyBindings.digit2, control: true): () =>
              setState(() => _isUrgent = true),
          const SingleActivator(AppKeyBindings.digit2, meta: true): () =>
              setState(() => _isUrgent = true),
          const SingleActivator(AppKeyBindings.enter, control: true): _submit,
          const SingleActivator(AppKeyBindings.enter, meta: true): _submit,
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Project name',
                errorText: _nameError,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                hintText: 'Description (optional)',
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SectionCard.single(
              icon: Icons.palette_outlined,
              title: 'Color',
              child: ProjectColorPicker(
                selected: _selectedColor,
                onChanged: (c) => setState(() => _selectedColor = c),
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              items: [
                SectionItem(
                  icon: Icons.warning_amber_rounded,
                  title: 'Urgency',
                  child: UrgencySelector(
                    selected: _isUrgent,
                    onChanged: (v) => setState(() => _isUrgent = v!),
                    allowAll: false,
                  ),
                ),
                if (isEditing)
                  SectionItem(
                    icon: Icons.toggle_on_outlined,
                    title: 'Status',
                    child: _ActiveToggle(
                      isActive: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SectionCard.single(
              icon: Icons.label_outlined,
              title: 'Labels',
              child: LabelPicker(
                selectedLabelIds: _selectedLabelIds,
                onSelected: (ids) => setState(() => _selectedLabelIds = ids),
                isDropdown: true,
              ),
            ),
            const SizedBox(height: 12),
            SectionCard.single(
              icon: Icons.calendar_today_outlined,
              title: 'Planning & Deadline',
              child: DatePickerButton(
                label: 'Deadline',
                icon: Icons.flag_outlined,
                date: _deadline,
                onChanged: (d) => setState(() => _deadline = d),
                firstDate: widget.project?.createdAt,
              ),
            ),
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
    if (name.isEmpty) {
      setState(() => _nameError = 'Project name is required');
      return;
    }

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
      ref
          .read(projectProvider.notifier)
          .addProject(
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
