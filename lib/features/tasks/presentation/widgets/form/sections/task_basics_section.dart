import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_autocomplete_text_field.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/tag_highlighting_controller.dart';
import 'package:carpe_diem/features/tasks/presentation/widgets/dialogs/widgets/parent_task_link.dart';
import 'package:flutter/material.dart';

/// Parent link, title and description fields of the task form.
class TaskBasicsSection extends StatelessWidget {
  final String? parentId;
  final VoidCallback onClearParent;
  final TagHighlightingController titleController;
  final TextEditingController descController;
  final String? titleError;
  final ValueChanged<Tag> onTagSelected;

  const TaskBasicsSection({
    required this.parentId,
    required this.onClearParent,
    required this.titleController,
    required this.descController,
    required this.titleError,
    required this.onTagSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(color: Theme.of(context).colorScheme.onSurface);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parentId != null) ...[
          ParentTaskLink(parentId: parentId!, onClear: onClearParent),
          const SizedBox(height: 8),
        ],
        TagAutocompleteTextField(
          controller: titleController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Task name',
            errorText: titleError,
          ),
          style: textStyle,
          onTagSelected: onTagSelected,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: descController,
          decoration: const InputDecoration(hintText: 'Description (optional)'),
          style: textStyle,
          maxLines: 2,
        ),
      ],
    );
  }
}
