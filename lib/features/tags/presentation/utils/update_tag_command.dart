import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/presentation/utils/tag_parser.dart';
import 'package:flutter/widgets.dart';

class UpdateTagCommand implements Command {
  final ITagRepository tagRepo;
  final ITagIconRepository iconRepo;
  final ITaskRepository taskRepo;
  final Tag previousTag;
  final Tag nextTag;
  final IconData? newIcon;

  IconData? _previousIcon;
  bool _hadPreviousIcon = false;
  final List<String> _associatedTaskIds = [];
  final Map<String, String> _originalTitles = {};

  UpdateTagCommand({
    required this.tagRepo,
    required this.iconRepo,
    required this.taskRepo,
    required this.previousTag,
    required this.nextTag,
    this.newIcon,
  });

  @override
  Future<void> execute() async {
    await tagRepo.update(nextTag);

    final cleanPrevName = previousTag.name.trim().toLowerCase();
    final cleanNextName = nextTag.name.trim().toLowerCase();

    final allIcons = await iconRepo.getAllIconDatas();
    _previousIcon = allIcons[cleanPrevName];
    _hadPreviousIcon = allIcons.containsKey(cleanPrevName);

    if (_hadPreviousIcon) {
      await iconRepo.deleteIconDataForTag(cleanPrevName);
    }

    final iconToSet = newIcon ?? _previousIcon;
    if (iconToSet != null) {
      await iconRepo.setIconDataForTag(cleanNextName, iconToSet);
    }

    _associatedTaskIds.clear();
    _originalTitles.clear();

    if (cleanPrevName != cleanNextName) {
      final tasks = await taskRepo.getAll(prioritizeDeadlines: false);

      for (final task in tasks) {
        if (TagParser.containsTag(task.title, previousTag.name)) {
          _associatedTaskIds.add(task.id);
          _originalTitles[task.id] = task.title;

          final newTitle = TagParser.renameSpecificTag(task.title, previousTag.name, nextTag.name);
          await taskRepo.update(task.copyWith(title: newTitle));
        }
      }
    }
  }

  @override
  Future<void> undo() async {
    await tagRepo.update(previousTag);

    final cleanPrevName = previousTag.name.trim().toLowerCase();
    final cleanNextName = nextTag.name.trim().toLowerCase();

    await iconRepo.deleteIconDataForTag(cleanNextName);
    if (_hadPreviousIcon && _previousIcon != null) {
      await iconRepo.setIconDataForTag(cleanPrevName, _previousIcon!);
    }

    for (final taskId in _associatedTaskIds) {
      final task = await taskRepo.getById(taskId);
      if (task != null) {
        final originalTitle = _originalTitles[taskId] ?? task.title;
        await taskRepo.update(task.copyWith(title: originalTitle));
      }
    }
  }

  @override
  String get description => 'Rename tag: "#${previousTag.name}" to "#${nextTag.name}"';
}
