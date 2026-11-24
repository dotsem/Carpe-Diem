import 'package:carpe_diem/features/common/data/database/database_helper.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tags/data/repositories/tag_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late TagRepository repository;

  setUp(() async {
    db = await DatabaseHelper(dbPath: inMemoryDatabasePath).database;
    repository = TagRepository(db);
  });

  tearDown(() => db.close());

  test('exposes its repository name', () {
    expect(repository.repositoryName, 'tag');
  });

  test('inserts, reads, updates and deletes tags', () async {
    const first = Tag(id: 'one', name: 'First');
    const second = Tag(id: 'two', name: 'Second');

    expect(await repository.getById('missing'), isNull);
    await repository.insert(first);
    await repository.insert(second);
    expect(await repository.getAll(), containsAll([first, second]));
    expect(await repository.getById('one'), first);

    const updated = Tag(id: 'one', name: 'Updated');
    await repository.update(updated);
    expect(await repository.getById('one'), updated);

    await repository.delete('one');
    expect(await repository.getById('one'), isNull);
    expect(await repository.getAll(), [second]);
  });

  test('Tag empty state and map conversion are consistent', () {
    const empty = Tag(id: '', name: '');
    const tag = Tag(id: 'id', name: 'Name');

    expect(empty.isEmpty, isTrue);
    expect(tag.isEmpty, isFalse);
    expect(Tag.fromMap(tag.toMap()), tag);
  });
}
