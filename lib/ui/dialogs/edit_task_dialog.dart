import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/data/models/priority.dart';
import 'package:carpe_diem/data/models/task.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:carpe_diem/providers/task_provider.dart';
import 'package:carpe_diem/ui/dialogs/common/delete_dialog.dart';
import 'package:carpe_diem/ui/widgets/blocker_picker.dart';
import 'package:carpe_diem/ui/widgets/priority_picker.dart';
import 'package:carpe_diem/ui/widgets/label_picker.dart';
import 'package:carpe_diem/ui/dialogs/common/sized_dialog.dart';
import 'package:carpe_diem/ui/widgets/project_picker.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/ui/widgets/date_picker_button.dart';
import 'package:provider/provider.dart';

class EditTaskDialog extends StatefulWidget {
  final Task task;
  const EditTaskDialog({super.key, required this.task});

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  late Priority _priority;
  DateTime? _scheduledDate;
  DateTime? _deadline;
  String? _selectedProjectId;
  String? _blockedById;
  List<Task> _projectTasks = [];
  List<String> _selectedLabelIds = [];
  List<String> _inheritedLabelIds = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.task.title;
    _descController.text = widget.task.description ?? '';
    _priority = widget.task.priority;
    _scheduledDate = widget.task.scheduledDate;
    _deadline = widget.task.deadline;
    _selectedProjectId = widget.task.projectId;
    _blockedById = widget.task.blockedById;
    _selectedLabelIds = List.from(widget.task.labelIds);
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
          Text('Edit Task', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Task name'),
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
                  label: 'Schedule Date',
                  date: _scheduledDate,
                  onChanged: (d) => setState(() => _scheduledDate = d),
                  lastDate: _maxDate,
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
              currentTaskId: widget.task.id,
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
            label: 'Deadline (Optional)',
            date: _deadline,
            onChanged: (d) => setState(() => _deadline = d),
            firstDate: widget.task.createdAt,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => DeleteDialog(
                    title: 'Delete Task',
                    message: 'Are you sure you want to delete this task?',
                    onConfirm: () {
                      Navigator.of(context).pop();
                      context.read<TaskProvider>().deleteTask(widget.task);
                    },
                  ),
                ),
                icon: const Icon(Icons.delete),
                style: FilledButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                label: const Text("Delete"),
              ),
              const Spacer(),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              const SizedBox(width: 12),
              FilledButton(onPressed: _submit, child: const Text('Save Changes')),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) return;
    context.read<TaskProvider>().updateTask(
      widget.task.copyWith(
        title: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty ? "" : _descController.text.trim(),
        priority: _priority,
        scheduledDate: _scheduledDate,
        clearScheduledDate: _scheduledDate == null,
        deadline: _deadline,
        clearDeadline: _deadline == null,
        blockedById: _blockedById,
        clearBlockedBy: _blockedById == null,
        projectId: _selectedProjectId,
        labelIds: _selectedLabelIds,
      ),
    );
    Navigator.of(context).pop();
  }
}
