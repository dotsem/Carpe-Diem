import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TagRepository extends ITagRepository {
  final Database db;

  TagRepository(this.db);

  @override
  String get repositoryName => 'tag';

  @override
  Future<List<Tag>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query('tags');
    return List.generate(maps.length, (i) => Tag.fromMap(maps[i]));
  }

  @override
  Future<Tag?> getById(String id) async {
    final List<Map<String, dynamic>> maps = await db.query('tags', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Tag.fromMap(maps.first);
  }

  @override
  Future<void> insert(Tag tag) async {
    await db.insert('tags', tag.toMap());
  }

  @override
  Future<void> update(Tag tag) async {
    await db.update('tags', tag.toMap(), where: 'id = ?', whereArgs: [tag.id]);
  }

  @override
  Future<void> delete(String id) async {
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }
}
