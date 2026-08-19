import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:carpe_diem/features/settings/presentation/providers/settings_provider.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_provider.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';
import 'package:carpe_diem/features/tags/presentation/widgets/dialogs/create_tags_prompt_dialog.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_placement.dart';
import 'package:carpe_diem/features/tasks/presentation/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract final class TaskFormSubmitHandler {
  static Future<bool> submit({
    required BuildContext context,
    required WidgetRef ref,
    required String rawTitle,
    required String? description,
    required DateTime? scheduledDate,
    required DateTime? deadline,
    required String? blockedById,
    required String? selectedProjectId,
    required String? parentId,
    required List<String> selectedLabelIds,
    required List<String> selectedTagIds,
    required TaskPlacement placement,
    required Task? initialTask,
  }) async {
    final parsedTagNames = TagParser.parseTags(rawTitle);
    final existingTags = ref.read(tagProvider).tags;
    final existingNamesSet = existingTags
        .map((t) => t.name.toLowerCase())
        .toSet();
    final newTagNames = parsedTagNames
        .where((name) => !existingNamesSet.contains(name.toLowerCase()))
        .toList();

    List<String> finalTagIds = List.from(selectedTagIds);
    final List<String> tagsToStrip = [];

    if (newTagNames.isNotEmpty) {
      final result = await showDialog<CreateTagsPromptResult>(
        context: context,
        builder: (_) => CreateTagsPromptDialog(newTagNames: newTagNames),
      );

      if (result == null || result == CreateTagsPromptResult.cancel) {
        return false;
      }

      if (result == CreateTagsPromptResult.createAndSave) {
        for (final name in newTagNames) {
          final newTag = await ref.read(tagProvider.notifier).addTag(name);
          finalTagIds.add(newTag.id);
        }
      } else if (result == CreateTagsPromptResult.saveWithoutTags) {
        tagsToStrip.addAll(newTagNames);
      }
    }

    final settings = ref.read(settingsProvider);
    var titleToSave = settings.keepTagsInTitle
        ? rawTitle
        : TagParser.stripTags(rawTitle);
    if (settings.keepTagsInTitle && tagsToStrip.isNotEmpty) {
      titleToSave = TagParser.stripSpecificTags(titleToSave, tagsToStrip);
    }

    final trimmedDesc = (description?.trim().isEmpty ?? true)
        ? null
        : description!.trim();

    if (initialTask != null) {
      ref
          .read(taskProvider.notifier)
          .updateTask(
            initialTask.copyWith(
              title: titleToSave,
              description: trimmedDesc ?? "",
              scheduledDate: scheduledDate,
              clearScheduledDate: scheduledDate == null,
              deadline: deadline,
              clearDeadline: deadline == null,
              blockedById: blockedById,
              clearBlockedBy: blockedById == null,
              projectId: selectedProjectId,
              labelIds: selectedLabelIds,
              tagIds: finalTagIds,
              isUrgent: placement == TaskPlacement.urgent,
            ),
          );
    } else {
      ref
          .read(taskProvider.notifier)
          .addTask(
            title: titleToSave,
            description: trimmedDesc,
            scheduledDate: scheduledDate,
            projectId: selectedProjectId,
            placement: placement,
            deadline: deadline,
            blockedById: blockedById,
            parentId: parentId,
            labelIds: selectedLabelIds,
            tagIds: finalTagIds,
          );
    }

    if (parentId != null && initialTask == null) {
      final sidebarState = ref.read(rightSidebarProvider);
      if (sidebarState.history.isNotEmpty &&
          sidebarState.history.last == EditTaskPanel(parentId)) {
        ref.read(rightSidebarProvider.notifier).pop();
      } else {
        ref.read(rightSidebarProvider.notifier).open(EditTaskPanel(parentId));
      }
    } else {
      ref.read(rightSidebarProvider.notifier).close();
    }
    return true;
  }
}
