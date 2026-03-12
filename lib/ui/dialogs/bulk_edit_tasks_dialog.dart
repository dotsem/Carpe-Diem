import 'package:carpe_diem/ui/widgets/project_picker.dart';
import 'package:carpe_diem/ui/widgets/blocker_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carpe_diem/core/constants/app_constants.dart';
import 'package:carpe_diem/data/models/task.dart';
import 'package:carpe_diem/data/models/priority.dart';
import 'package:carpe_diem/providers/task_provider.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:carpe_diem/ui/widgets/priority_picker.dart';
import 'package:carpe_diem/ui/widgets/date_picker_button.dart';
import 'package:carpe_diem/ui/dialogs/common/sized_dialog.dart';

class BulkEditResult {
  final Priority? priority;
  final bool updatePriority;
  final DateTime? scheduledDate;
  final bool updateScheduledDate;
  final bool clearScheduledDate;
  final String? projectId;
  final bool updateProjectId;
  final bool clearProjectId;
  final DateTime? deadline;
  final bool updateDeadline;
  final bool clearDeadline;
  final String? blockedById;
  final bool updateBlockedById;
  final bool clearBlockedById;

  BulkEditResult({
    this.priority,
    this.updatePriority = false,
    this.scheduledDate,
    this.updateScheduledDate = false,
    this.clearScheduledDate = false,
    this.projectId,
    this.updateProjectId = false,
    this.clearProjectId = false,
    this.deadline,
    this.updateDeadline = false,
    this.clearDeadline = false,
    this.blockedById,
    this.updateBlockedById = false,
    this.clearBlockedById = false,
  });
}

class BulkEditTasksDialog extends StatefulWidget {
  final List<String> taskIds;

  const BulkEditTasksDialog({super.key, required this.taskIds});

  @override
  State<BulkEditTasksDialog> createState() => _BulkEditTasksDialogState();
}

class _BulkEditTasksDialogState extends State<BulkEditTasksDialog> {
  bool _enablePriority = false;
  Priority _priority = Priority.none;

  bool _enableScheduledDate = false;
  DateTime? _scheduledDate;

  bool _enableProject = false;
  String? _selectedProjectId;

  bool _enableDeadline = false;
  DateTime? _deadline;

  bool _enableBlocker = false;
  String? _blockedById;
  List<Task> _projectTasks = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadProjectTasks() async {
    if (_selectedProjectId == null) {
      if (mounted) {
        setState(() {
          _projectTasks = [];
          if (_enableBlocker && _blockedById != null) {
            _blockedById = null;
          }
        });
      }
      return;
    }
    final tasks = await context.read<TaskProvider>().getTasksForProject(_selectedProjectId!);
    if (mounted) {
      setState(() => _projectTasks = tasks);
    }
  }

  DateTime get _maxDate => DateTime.now().add(const Duration(days: AppConstants.maxPlanningDaysAhead));

  Widget _buildFieldRow(String label, bool value, ValueChanged<bool?> onChanged, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(value: value, onChanged: onChanged),
            ),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: value ? 1.0 : 0.5,
          child: IgnorePointer(ignoring: !value, child: child),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = context.read<ProjectProvider>().projects;

    return SizedDialog(
      onSubmit: _submit,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bulk Edit ${widget.taskIds.length} Tasks', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),

            _buildFieldRow(
              'Priority',
              _enablePriority,
              (v) => setState(() => _enablePriority = v ?? false),
              PriorityPicker(selected: _priority, onChanged: (p) => setState(() => _priority = p)),
            ),
            const SizedBox(height: 16),

            _buildFieldRow(
              'Schedule date',
              _enableScheduledDate,
              (v) => setState(() => _enableScheduledDate = v ?? false),
              DatePickerButton(
                label: 'Schedule date',
                date: _scheduledDate,
                lastDate: _maxDate,
                onChanged: (d) => setState(() => _scheduledDate = d),
              ),
            ),
            const SizedBox(height: 16),

            _buildFieldRow(
              'Project',
              _enableProject,
              (v) => setState(() {
                _enableProject = v ?? false;
                if (_enableProject) {
                  _loadProjectTasks();
                }
              }),
              ProjectPicker(
                projects: projects,
                selectedProjectId: _selectedProjectId,
                onChanged: (id) {
                  setState(() => _selectedProjectId = id);
                  _loadProjectTasks();
                },
              ),
            ),
            const SizedBox(height: 16),

            if (_enableProject && _selectedProjectId != null) ...[
              _buildFieldRow(
                'Blocked by',
                _enableBlocker,
                (v) => setState(() => _enableBlocker = v ?? false),
                BlockerPicker(
                  availableTasks: _projectTasks,
                  selectedBlockerId: _blockedById,
                  onChanged: (id) => setState(() => _blockedById = id),
                ),
              ),
              const SizedBox(height: 16),
            ],

            _buildFieldRow(
              'Deadline',
              _enableDeadline,
              (v) => setState(() => _enableDeadline = v ?? false),
              DatePickerButton(
                label: 'Deadline',
                date: _deadline,
                firstDate: DateTime.now(),
                onChanged: (d) => setState(() => _deadline = d),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                const SizedBox(width: 12),
                FilledButton(onPressed: _submit, child: const Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final result = BulkEditResult(
      priority: _priority,
      updatePriority: _enablePriority,
      scheduledDate: _scheduledDate,
      updateScheduledDate: _enableScheduledDate,
      clearScheduledDate: _enableScheduledDate && _scheduledDate == null,
      projectId: _selectedProjectId,
      updateProjectId: _enableProject,
      clearProjectId: _enableProject && _selectedProjectId == null,
      deadline: _deadline,
      updateDeadline: _enableDeadline,
      clearDeadline: _enableDeadline && _deadline == null,
      blockedById: _blockedById,
      updateBlockedById: _enableBlocker,
      clearBlockedById: _enableBlocker && _blockedById == null,
    );
    Navigator.of(context).pop(result);
  }
}
