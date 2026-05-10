import 'package:carpe_diem/data/models/project.dart';
import 'package:carpe_diem/providers/project_provider.dart';
import 'package:carpe_diem/providers/task_provider.dart';
import 'package:carpe_diem/ui/dialogs/common/sized_dialog.dart';
import 'package:carpe_diem/ui/widgets/project_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ImportFromMDDialog extends StatefulWidget {
  final Project? project;
  const ImportFromMDDialog({super.key, this.project});

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
      title: 'Import from Markdown',
      onSubmit: _submit,
      submitText: 'Import',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.project == null) ...[
            ProjectPicker(
              projects: projects,
              selectedProjectId: _selectedProjectId,
              onChanged: (id) => setState(() => _selectedProjectId = id),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            maxLines: 10,
            minLines: 3,
            decoration: const InputDecoration(labelText: 'Markdown content'),
            controller: _controller,
          ),
        ],
      ),
    );
  }

  void _submit() {
    context.read<TaskProvider>().importTasksFromMarkdown(_controller.text, widget.project?.id ?? _selectedProjectId!);
    Navigator.pop(context);
  }
}
