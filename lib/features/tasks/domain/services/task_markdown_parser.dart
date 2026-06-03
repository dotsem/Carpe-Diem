import 'package:uuid/uuid.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';

class TaskMarkdownParser {
  static final _uuid = const Uuid();

  static List<Task> parseMarkdown(String markdown) {
    final tasks = <Task>[];
    final lines = markdown.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('- ')) {
        final match = RegExp(r'^- (?:\[([x\s])\]\s+)?(.*)$').firstMatch(trimmed);
        if (match != null) {
          final isDone = match.group(1) == 'x';
          final title = match.group(2)!.trim();
          tasks.add(
            Task(
              id: _uuid.v4(),
              title: title,
              status: isDone ? TaskStatus.done : TaskStatus.todo,
              createdAt: DateTime.now(),
            ),
          );
        }
      }
    }
    return tasks;
  }
}
