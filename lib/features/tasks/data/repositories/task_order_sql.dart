import 'package:carpe_diem/features/tasks/data/models/task_status.dart';

/// Builds the `ORDER BY` clause body shared by task list queries.
String taskOrderBy({
  String? tableAlias,
  bool prioritizeDeadlines = true,
  bool prioritizeOverdue = false,
  DateTime? today,
  bool isPlanOrder = false,
}) {
  final prefix = tableAlias != null ? '$tableAlias.' : '';
  final urgentPart = '(${prefix}isUrgent = 1) DESC';
  final sortCol = isPlanOrder
      ? "COALESCE(NULLIF(${prefix}planSortOrder, ''), NULLIF(${prefix}sortOrder, ''), '~')"
      : "CASE WHEN ${prefix}sortOrder = '' THEN '~' ELSE ${prefix}sortOrder END";
  final sortOrderPart = '$sortCol ASC, ${prefix}createdAt DESC';
  final deadlinePart = '(${prefix}deadline IS NULL), ${prefix}deadline ASC';

  final t = today ?? DateTime.now();
  final todayStr = DateTime(t.year, t.month, t.day).toIso8601String();
  final overduePart =
      "(CASE WHEN ${prefix}status != ${TaskStatus.done.index} AND ((${prefix}scheduledDate IS NOT NULL AND ${prefix}scheduledDate < '$todayStr' AND (${prefix}deadline IS NULL OR ${prefix}deadline < '$todayStr')) OR (${prefix}deadline IS NOT NULL AND ${prefix}deadline < '$todayStr')) THEN 1 ELSE 0 END) DESC";

  final parts = <String>[urgentPart];
  if (prioritizeOverdue) {
    parts.add(overduePart);
  }
  if (prioritizeDeadlines && !isPlanOrder) {
    parts.add(deadlinePart);
  }
  parts.add(sortOrderPart);
  if (!prioritizeDeadlines || isPlanOrder) {
    parts.add(deadlinePart);
  }
  return parts.join(', ');
}
