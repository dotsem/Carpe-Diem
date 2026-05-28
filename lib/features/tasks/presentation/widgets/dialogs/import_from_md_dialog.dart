import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/projects/presentation/providers/project_provider.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:carpe_diem/features/common/presentation/widgets/dialogs/sized_dialog.dart';
import 'package:carpe_diem/features/projects/presentation/widgets/project_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImportFromMDDialog extends ConsumerStatefulWidget {
  final Project? project;
  const ImportFromMDDialog({super.key, this.project});

  @override
  ConsumerState<ImportFromMDDialog> createState() => _ImportFromMDDialogState();
}

class _ImportFromMDDialogState extends ConsumerState<ImportFromMDDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedProjectId;

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectProvider).projects.where((p) => p.isActive).toList();

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
    ref.read(taskProvider.notifier).importTasksFromMarkdown(_controller.text, widget.project?.id ?? _selectedProjectId!);
    Navigator.pop(context);
  }
}
