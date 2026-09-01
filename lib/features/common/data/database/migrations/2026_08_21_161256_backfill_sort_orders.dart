// ignore_for_file: file_names, camel_case_types
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carpe_diem/core/utils/lexorank_utils.dart';
import '../migration.dart';

class Migration_2026_08_21_161256_BackfillSortOrders implements Migration {
  @override
  int get version => 3;

  @override
  Future<void> up(DatabaseExecutor db) async {
    final tasks = await db.rawQuery(
      "SELECT id FROM tasks WHERE sortOrder = '' OR sortOrder IS NULL ORDER BY createdAt ASC",
    );

    if (tasks.isEmpty) return;

    String? currentRank;
    for (final row in tasks) {
      final id = row['id'] as String;
      currentRank = LexoRankUtils.generateBetween(currentRank, null);
      await db.rawUpdate('UPDATE tasks SET sortOrder = ? WHERE id = ?', [
        currentRank,
        id,
      ]);
    }
  }
}
