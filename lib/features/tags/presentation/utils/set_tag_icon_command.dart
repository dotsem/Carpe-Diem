import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:flutter/widgets.dart';

class SetTagIconCommand implements Command {
  final ITagIconRepository repo;
  final String tagName;
  final IconData iconData;
  IconData? _previousIconData;

  SetTagIconCommand({
    required this.repo,
    required this.tagName,
    required this.iconData,
  });

  @override
  Future<void> execute() async {
    final allIcons = await repo.getAllIconDatas();
    _previousIconData = allIcons[tagName.trim().toLowerCase()];
    await repo.setIconDataForTag(tagName, iconData);
  }

  @override
  Future<void> undo() async {
    if (_previousIconData != null) {
      await repo.setIconDataForTag(tagName, _previousIconData!);
    } else {
      await repo.deleteIconDataForTag(tagName);
    }
  }

  @override
  String get description => 'Set icon for tag: "#$tagName"';
}
