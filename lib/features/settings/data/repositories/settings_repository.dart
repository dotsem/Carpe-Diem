import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';

class SettingsRepository implements ISettingsRepository {
  final Database _db;

  SettingsRepository(this._db);

  @override
  Future<void> set(String key, String value) async {
    await _db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<String?> get(String key) async {
    final maps = await _db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  @override
  Future<Map<String, String>> getAll() async {
    final maps = await _db.query('settings');
    return {for (var map in maps) map['key'] as String: map['value'] as String};
  }

  @override
  Future<void> delete(String key) async {
    await _db.delete('settings', where: 'key = ?', whereArgs: [key]);
  }
}
