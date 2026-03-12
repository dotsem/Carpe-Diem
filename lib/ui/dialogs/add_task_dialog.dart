import 'package:carpe_diem/ui/widgets/project_picker.dart';
import 'package:carpe_diem/ui/widgets/blocker_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:carpe_diem/data/models/task.dart';
import 'package:carpe_diem/data/models/priority.dart';
import 'package:carpe_diem/providers/task_provider.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:carpe_diem/ui/widgets/priority_picker.dart';
import 'package:carpe_diem/ui/widgets/date_picker_button.dart';
import 'package:carpe_diem/ui/widgets/label_picker.dart';
import 'package:carpe_diem/ui/dialogs/common/sized_dialog.dart';

class AddTaskDialog extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialProjectId;

  const AddTaskDialog({super.key, this.initialDate, this.initialProjectId});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedProjectId;
  Priority _priority = Priority.none;
  DateTime? _deadline;
  String? _blockedById;
  List<Task> _projectTasks = [];
  List<String> _selectedLabelIds = [];
  List<String> _inheritedLabelIds = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedProjectId = widget.initialProjectId;
    if (_selectedProjectId != null) _loadProjectDetails();
  }

  Future<void> _loadProjectDetails() async {
    if (_selectedProjectId == null) {
      setState(() {
        _projectTasks = [];
        _blockedById = null;
        _inheritedLabelIds = [];
      });
      return;
    }
    final tasks = await context.read<TaskProvider>().getTasksForProject(_selectedProjectId!);
    if (!mounted) return;
    final project = context.read<ProjectProvider>().getById(_selectedProjectId!);
    setState(() {
      _projectTasks = tasks;
      _inheritedLabelIds = project?.labelIds ?? [];
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  DateTime get _maxDate => DateTime.now().add(const Duration(days: AppConstants.maxPlanningDaysAhead));

  @override
  Widget build(BuildContext context) {
    final projects = context.read<ProjectProvider>().projects;

    return SizedDialog(
      onSubmit: _submit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Task', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Task title'),
            style: const TextStyle(color: AppColors.text),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(hintText: 'Description (optional)'),
            style: const TextStyle(color: AppColors.text),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Text('Priority', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          PriorityPicker(selected: _priority, onChanged: (p) => setState(() => _priority = p)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DatePickerButton(
                  label: 'Schedule date',
                  date: _selectedDate,
                  lastDate: _maxDate,
                  onChanged: (d) => setState(() => _selectedDate = d),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ProjectPicker(
                  projects: projects,
                  selectedProjectId: _selectedProjectId,
                  onChanged: (id) {
                    setState(() => _selectedProjectId = id);
                    _loadProjectDetails();
                  },
                ),
              ),
            ],
          ),
          if (_selectedProjectId != null) ...[
            const SizedBox(height: 12),
            BlockerPicker(
              availableTasks: _projectTasks,
              selectedBlockerId: _blockedById,
              onChanged: (id) => setState(() => _blockedById = id),
            ),
          ],
          const SizedBox(height: 16),
          Text('Labels', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          LabelPicker(
            selectedLabelIds: _selectedLabelIds,
            inheritedLabelIds: _inheritedLabelIds,
            onSelected: (ids) => setState(() => _selectedLabelIds = ids),
          ),
          const SizedBox(height: 12),
          DatePickerButton(
            label: 'Deadline',
            date: _deadline,
            firstDate: DateTime.now(),
            onChanged: (d) => setState(() => _deadline = d),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              const SizedBox(width: 12),
              FilledButton(onPressed: _submit, child: const Text('Add Task')),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    context.read<TaskProvider>().addTask(
      title: title,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      scheduledDate: _selectedDate,
      projectId: _selectedProjectId,
      priority: _priority,
      deadline: _deadline,
      blockedById: _blockedById,
      labelIds: _selectedLabelIds,
    );
    Navigator.of(context).pop();
  }
}
