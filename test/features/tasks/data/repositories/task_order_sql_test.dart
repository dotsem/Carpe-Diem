import 'package:carpe_diem/features/tasks/data/repositories/task_order_sql.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 5, 10, 14);
  const urgent = '(t.isUrgent = 1) DESC';
  const deadline = '(t.deadline IS NULL), t.deadline ASC';
  const sort =
      "CASE WHEN t.sortOrder = '' THEN '~' ELSE t.sortOrder END ASC, t.createdAt DESC";
  const planSort =
      "COALESCE(NULLIF(t.planSortOrder, ''), NULLIF(t.sortOrder, ''), '~') ASC, t.createdAt DESC";

  test('deadlines first by default', () {
    expect(taskOrderBy(tableAlias: 't'), '$urgent, $deadline, $sort');
  });

  test('deadlines last when not prioritized', () {
    expect(
      taskOrderBy(tableAlias: 't', prioritizeDeadlines: false),
      '$urgent, $sort, $deadline',
    );
  });

  test('plan order uses planSortOrder and puts deadline last', () {
    expect(
      taskOrderBy(tableAlias: 't', isPlanOrder: true),
      '$urgent, $planSort, $deadline',
    );
  });

  test('overdue part is inserted after urgent, relative to today', () {
    final sql = taskOrderBy(
      tableAlias: 't',
      prioritizeOverdue: true,
      today: today,
    );
    final overdue = sql.split(', ')[1];
    expect(overdue, startsWith('(CASE WHEN t.status != '));
    expect(overdue, contains("'2026-05-10T00:00:00.000'"));
    expect(sql, endsWith('$deadline, $sort'));
  });

  test('no alias omits the prefix', () {
    expect(
      taskOrderBy(),
      startsWith('(isUrgent = 1) DESC, (deadline IS NULL)'),
    );
  });
}
