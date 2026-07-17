import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';
import 'package:flutter/widgets.dart';

class DeleteTagCommand implements Command {
  final ITagRepository tagRepo;
  final ITagIconRepository iconRepo;
  final ITaskRepository taskRepo;
  final Tag tag;

  IconData? _deletedIcon;
  bool _hadIcon = false;
  final List<String> _associatedTaskIds = [];
  final Map<String, String> _originalTitles = {};

  DeleteTagCommand({
    required this.tagRepo,
    required this.iconRepo,
    required this.taskRepo,
    required this.tag,
  });

  @override
  Future<void> execute() async {
    final cleanName = tag.name.trim().toLowerCase();
    final allIcons = await iconRepo.getAllIconDatas();
    _deletedIcon = allIcons[cleanName];
    _hadIcon = allIcons.containsKey(cleanName);

    if (_hadIcon) {
      await iconRepo.deleteIconDataForTag(cleanName);
    }

    final tasks = await taskRepo.getAll(prioritizeDeadlines: false);

    _associatedTaskIds.clear();
    _originalTitles.clear();

    for (final task in tasks) {
      final hasTagInIds = task.tagIds.contains(tag.id);
      final hasTagInTitle = TagParser.containsTag(task.title, tag.name);

      if (hasTagInIds || hasTagInTitle) {
        _associatedTaskIds.add(task.id);
        if (hasTagInTitle) {
          _originalTitles[task.id] = task.title;
        }

        var newTitle = task.title;
        if (hasTagInTitle) {
          newTitle = TagParser.stripSpecificTags(task.title, [tag.name]);
        }
        final newTagIds = List<String>.from(task.tagIds)..remove(tag.id);

        await taskRepo.update(task.copyWith(title: newTitle, tagIds: newTagIds));
      }
    }

    await tagRepo.delete(tag.id);
  }

  @override
  Future<void> undo() async {
    await tagRepo.insert(tag);

    if (_hadIcon && _deletedIcon != null) {
      final cleanName = tag.name.trim().toLowerCase();
      await iconRepo.setIconDataForTag(cleanName, _deletedIcon!);
    }

    for (final taskId in _associatedTaskIds) {
      final task = await taskRepo.getById(taskId);
      if (task != null) {
        final originalTitle = _originalTitles[taskId] ?? task.title;
        final newTagIds = List<String>.from(task.tagIds);
        if (!newTagIds.contains(tag.id)) {
          newTagIds.add(tag.id);
        }
        await taskRepo.update(task.copyWith(title: originalTitle, tagIds: newTagIds));
      }
    }
  }

  @override
  String get description => 'Delete tag: "#${tag.name}"';
}
