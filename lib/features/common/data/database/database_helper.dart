import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carpe_diem/core/constants/app_constants.dart';

class DatabaseHelper {
  final String dbPath;

  DatabaseHelper({this.dbPath = ''});

  Database? _database;
  Future<Database>? _dbOpenFuture;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _dbOpenFuture ??= _initDB();
    _database = await _dbOpenFuture;
    return _database!;
  }

  static Future<void> initialize() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> _initDB() async {
    final String path;
    if (dbPath.isNotEmpty) {
      path = dbPath;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      path = join(dir.path, AppConstants.dbName);
    }

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        color INTEGER NOT NULL,
        priority INTEGER NOT NULL DEFAULT 0,
        deadline TEXT,
        createdAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE labels (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE project_labels (
        projectId TEXT NOT NULL,
        labelId TEXT NOT NULL,
        PRIMARY KEY (projectId, labelId),
        FOREIGN KEY (projectId) REFERENCES projects(id) ON DELETE CASCADE,
        FOREIGN KEY (labelId) REFERENCES labels(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        scheduledDate TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        status INTEGER NOT NULL DEFAULT 0,
        projectId TEXT,
        priority INTEGER NOT NULL DEFAULT 0,
        deadline TEXT,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        blockedById TEXT,
        sortOrder TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (projectId) REFERENCES projects(id) ON DELETE SET NULL,
        FOREIGN KEY (blockedById) REFERENCES tasks(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE task_labels (
        taskId TEXT NOT NULL,
        labelId TEXT NOT NULL,
        PRIMARY KEY (taskId, labelId),
        FOREIGN KEY (taskId) REFERENCES tasks(id) ON DELETE CASCADE,
        FOREIGN KEY (labelId) REFERENCES labels(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
        CREATE TABLE tags (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL
        )
      ''');
    await db.execute('''
        CREATE TABLE task_tags (
          taskId TEXT NOT NULL,
          tagId TEXT NOT NULL,
          PRIMARY KEY (taskId, tagId),
          FOREIGN KEY (taskId) REFERENCES tasks(id) ON DELETE CASCADE,
          FOREIGN KEY (tagId) REFERENCES tags(id) ON DELETE CASCADE
        )
      ''');
    await db.execute('''
        CREATE TABLE tag_icons (
          tag_name TEXT PRIMARY KEY,
          icon_code_point INTEGER NOT NULL
        )
      ''');
    await _seedTagIcons(db);
  }

  static Future<void> _seedTagIcons(Database db) async {
    final Map<String, int> initialTagIcons = {
      'bug': Icons.bug_report.codePoint,
      'issue': Icons.bug_report.codePoint,
      'feature': Icons.add_circle.codePoint,
      'feat': Icons.add_circle.codePoint,
      'new': Icons.add_circle.codePoint,
      'wip': Icons.pending.codePoint,
      'progress': Icons.pending.codePoint,
      'doing': Icons.pending.codePoint,
      'todo': Icons.playlist_add.codePoint,
      'backlog': Icons.playlist_add.codePoint,
      'done': Icons.check_circle.codePoint,
      'complete': Icons.check_circle.codePoint,
      'resolved': Icons.check_circle.codePoint,
      'urgent': Icons.whatshot.codePoint,
      'priority': Icons.whatshot.codePoint,
      'hotfix': Icons.whatshot.codePoint,
      'personal': Icons.person.codePoint,
      'self': Icons.person.codePoint,
      'private': Icons.person.codePoint,
      'work': Icons.business_center.codePoint,
      'office': Icons.business_center.codePoint,
      'job': Icons.business_center.codePoint,
      'idea': Icons.lightbulb.codePoint,
      'thought': Icons.lightbulb.codePoint,
      'brainstorm': Icons.lightbulb.codePoint,
      'refactor': Icons.build.codePoint,
      'clean': Icons.build.codePoint,
      'chore': Icons.build.codePoint,
      'enhancement': Icons.auto_awesome_motion.codePoint,
      'improve': Icons.auto_awesome_motion.codePoint,
      'optimize': Icons.speed.codePoint,
      'security': Icons.security.codePoint,
      'doc': Icons.description.codePoint,
      'docs': Icons.description.codePoint,
      'documentation': Icons.description.codePoint,
      'test': Icons.flaky.codePoint,
      'tests': Icons.flaky.codePoint,
      'testing': Icons.flaky.codePoint,
    };

    final batch = db.batch();
    for (final entry in initialTagIcons.entries) {
      batch.insert('tag_icons', {
        'tag_name': entry.key,
        'icon_code_point': entry.value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 11) {
      await db.execute('ALTER TABLE projects ADD COLUMN isActive INTEGER NOT NULL DEFAULT 1');
    }
    if (oldVersion < 12) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tags (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS task_tags (
          taskId TEXT NOT NULL,
          tagId TEXT NOT NULL,
          PRIMARY KEY (taskId, tagId),
          FOREIGN KEY (taskId) REFERENCES tasks(id) ON DELETE CASCADE,
          FOREIGN KEY (tagId) REFERENCES tags(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 13) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tag_icons (
          tag_name TEXT PRIMARY KEY,
          icon_code_point INTEGER NOT NULL
        )
      ''');
      await _seedTagIcons(db);
    }
    if (oldVersion < 15) {
      await db.execute("ALTER TABLE tasks ADD COLUMN sortOrder TEXT NOT NULL DEFAULT ''");
      await db.execute("UPDATE tasks SET sortOrder = createdAt WHERE sortOrder = ''");
    }
  }
}
