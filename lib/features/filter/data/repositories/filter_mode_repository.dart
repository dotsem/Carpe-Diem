import 'dart:convert';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/filter/data/models/filter_mode.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FilterModeRepository implements IFilterModeRepository {
  final Database db;

  FilterModeRepository(this.db);

  @override
  String get repositoryName => 'filter_mode';

  @override
  Future<List<FilterMode>> getAll() async {
    final maps = await db.query('filter_modes', orderBy: 'name ASC');
    return maps.map(_fromDbMap).toList();
  }

  @override
  Future<FilterMode?> getById(String id) async {
    final maps = await db.query(
      'filter_modes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _fromDbMap(maps.first);
  }

  @override
  Future<void> insert(FilterMode mode) async {
    await db.insert('filter_modes', _toDbMap(mode));
  }

  @override
  Future<void> update(FilterMode mode) async {
    await db.update(
      'filter_modes',
      _toDbMap(mode),
      where: 'id = ?',
      whereArgs: [mode.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await db.delete('filter_modes', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, dynamic> _toDbMap(FilterMode mode) {
    return {
      'id': mode.id,
      'name': mode.name,
      'icon_code_point': mode.iconCodePoint,
      'filter': jsonEncode(mode.filter.toMap()),
      'is_default': mode.isDefault ? 1 : 0,
    };
  }

  FilterMode _fromDbMap(Map<String, dynamic> map) {
    TaskFilter filter = const TaskFilter();
    final filterRaw = map['filter'] as String?;
    if (filterRaw != null && filterRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(filterRaw) as Map<String, dynamic>;
        filter = TaskFilter.fromMap(decoded);
      } catch (_) {}
    }

    return FilterMode(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      iconCodePoint: map['icon_code_point'] as int?,
      filter: filter,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
    );
  }
}
