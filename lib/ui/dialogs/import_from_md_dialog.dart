import 'package:carpe_diem/providers/project_provider.dart';
import 'package:carpe_diem/providers/task_provider.dart';
import 'package:carpe_diem/ui/dialogs/common/sized_dialog.dart';
import 'package:carpe_diem/ui/widgets/project_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ImportFromMDDialog extends StatefulWidget {
  const ImportFromMDDialog({super.key});

  @override
  State<ImportFromMDDialog> createState() => _ImportFromMDDialogState();
}

class _ImportFromMDDialogState extends State<ImportFromMDDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedProjectId;

  @override
  Widget build(BuildContext context) {
    final projects = context.read<ProjectProvider>().projects;

    return SizedDialog(
      maxWidth: 800,
      onSubmit: _submit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Import from Markdown'),
          const SizedBox(height: 16),
          ProjectPicker(
            projects: projects,
            selectedProjectId: _selectedProjectId,
            onChanged: (id) => setState(() => _selectedProjectId = id),
          ),
          const SizedBox(height: 16),

          TextField(
            maxLines: 10,
            minLines: 3,
            decoration: const InputDecoration(labelText: 'Markdown content'),
            controller: _controller,
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              const SizedBox(width: 8),
              FilledButton(onPressed: _submit, child: const Text('Import')),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    context.read<TaskProvider>().importTasksFromMarkdown(_controller.text, _selectedProjectId);
    Navigator.pop(context);
  }
}
