import 'package:carpe_diem/features/common/data/database/migration.dart';
import 'migrations/2026_07_31_133028_add_parentid_to_tasks.dart';

final List<Migration> allMigrations = [
  Migration_2026_07_31_133028_AddParentidToTasks(),
];
