import 'package:carpe_diem/features/common/data/database/migration.dart';
import 'migrations/2026_07_31_133028_add_parentid_to_tasks.dart';
import 'migrations/2026_08_21_161256_backfill_sort_orders.dart';
import 'migrations/2026_08_22_215332_add_sort_index.dart';

final List<Migration> allMigrations = [
  Migration_2026_07_31_133028_AddParentidToTasks(),
  Migration_2026_08_21_161256_BackfillSortOrders(),
  Migration_2026_08_22_215332_AddSortIndex(),
];
