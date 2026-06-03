import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carpe_diem/features/common/data/database/database_helper.dart';
import 'package:carpe_diem/features/settings/data/repositories/settings_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SettingsRepository', () {
    late DatabaseHelper dbHelper;
    late Database db;
    late SettingsRepository repository;

    setUp(() async {
      dbHelper = DatabaseHelper(dbPath: inMemoryDatabasePath);
      db = await dbHelper.database;
      repository = SettingsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('should insert and fetch a single setting value', () async {
      await repository.set('theme', 'dark');
      final value = await repository.get('theme');
      expect(value, equals('dark'));
    });

    test('should overwrite an existing setting value with conflict replacement', () async {
      await repository.set('theme', 'dark');
      await repository.set('theme', 'light');
      final value = await repository.get('theme');
      expect(value, equals('light'));
    });

    test('should return null for non-existent keys', () async {
      final value = await repository.get('non_existent');
      expect(value, isNull);
    });

    test('should retrieve all stored settings as a map', () async {
      await repository.set('theme', 'dark');
      await repository.set('compact', 'true');

      final all = await repository.getAll();
      expect(all.length, equals(2));
      expect(all['theme'], equals('dark'));
      expect(all['compact'], equals('true'));
    });
  });
}
