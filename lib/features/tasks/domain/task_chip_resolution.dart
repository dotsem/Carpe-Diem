import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';

/// Resolves the labels and tags displayed for [task].
({List<Label> labels, List<Tag> tags}) resolveTaskChips({
  required Task task,
  required Label? Function(String id) labelLookup,
  required Tag? Function(String id) tagLookup,
  Project? project,
}) {
  final labelIds = <String>{...task.labelIds, ...?project?.labelIds};
  final labels = labelIds.map(labelLookup).whereType<Label>().toList();
  final tags = task.tagIds.map(tagLookup).whereType<Tag>().toList();
  return (labels: labels, tags: tags);
}
