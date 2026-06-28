import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';

class ProjectRepository extends IProjectRepository {
  final Database _db;

  ProjectRepository(this._db);

  @override
  Future<List<Project>> getAll() async {
    final maps = await _db.query('projects', orderBy: '(deadline IS NULL), deadline ASC, priority DESC, name ASC');

    List<Project> projects = [];
    for (final map in maps) {
      final id = map['id'] as String;
      final labelIds = await _getLabelIds(id);
      projects.add(Project.fromMap(map, labelIds: labelIds));
    }
    return projects;
  }

  @override
  Future<Project?> getById(String id) async {
    final maps = await _db.query('projects', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;

    final labelIds = await _getLabelIds(id);
    return Project.fromMap(maps.first, labelIds: labelIds);
  }

  @override
  Future<void> insert(Project project) async {
    await _db.transaction((txn) async {
      await txn.insert('projects', project.toMap());
      for (final labelId in project.labelIds) {
        final labelExists = (await txn.rawQuery('SELECT 1 FROM labels WHERE id = ?', [labelId])).isNotEmpty;
        if (labelExists) {
          await txn.insert('project_labels', {'projectId': project.id, 'labelId': labelId});
        }
      }
    });
  }

  @override
  Future<void> update(Project project) async {
    await _db.transaction((txn) async {
      final map = project.toMap();
      map.remove('id');
      await txn.update('projects', map, where: 'id = ?', whereArgs: [project.id]);

      // Update labels: simplest is to delete all and re-insert
      await txn.delete('project_labels', where: 'projectId = ?', whereArgs: [project.id]);
      for (final labelId in project.labelIds) {
        final labelExists = (await txn.rawQuery('SELECT 1 FROM labels WHERE id = ?', [labelId])).isNotEmpty;
        if (labelExists) {
          await txn.insert('project_labels', {'projectId': project.id, 'labelId': labelId});
        }
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    // project_labels will be deleted via CASCADE
    await _db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> _getLabelIds(String projectId) async {
    final maps = await _db.query(
      'project_labels',
      where: 'projectId = ?',
      columns: ['labelId'],
      whereArgs: [projectId],
    );
    return maps.map((m) => m['labelId'] as String).toList();
  }
}
