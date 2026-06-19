import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';

class LabelRepository extends ILabelRepository {
  final Database _db;

  LabelRepository(this._db);

  @override
  Future<List<Label>> getAll() async {
    final maps = await _db.query('labels', orderBy: 'name ASC');
    return maps.map(Label.fromMap).toList();
  }

  @override
  Future<Label?> getById(String id) async {
    final maps = await _db.query('labels', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Label.fromMap(maps.first);
  }

  @override
  Future<void> insert(Label label) async {
    await _db.insert('labels', label.toMap());
  }

  @override
  Future<void> update(Label label) async {
    await _db.update('labels', label.toMap(), where: 'id = ?', whereArgs: [label.id]);
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete('labels', where: 'id = ?', whereArgs: [id]);
  }
}
