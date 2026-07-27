import 'dart:io';

const sqliteDir = 'lib/features/common/data/database';
const migrationsDir = '$sqliteDir/migrations';
const dbVersionPath = '$sqliteDir/constants/db_constants.dart';
const templatePath = 'sqlite_migrator/template.txt';
const registrarPath = '$sqliteDir/migration_registrar.dart';

class Slug {
  final String snakeCaseSlug;
  final String pascalCaseSlug;
  Slug({required this.snakeCaseSlug, required this.pascalCaseSlug});
}

void main(List<String> args) {
  final versionFile = File(dbVersionPath);
  if (!versionFile.existsSync()) {
    stderr.writeln(
      'Error: Could not find $dbVersionPath. Run from root directory.',
    );
    exit(1);
  }

  final slug = _getSlug(args);

  final isoTimestamp = _formatDateTimeToIso8601Utc(DateTime.now());

  final filename = '${isoTimestamp}_${slug.snakeCaseSlug}.dart';
  final className = 'Migration_${isoTimestamp}_${slug.pascalCaseSlug}';

  final nextVersion = _bumpDbVersion(versionFile);

  final migrationsDirObj = Directory(migrationsDir);
  if (!migrationsDirObj.existsSync()) {
    migrationsDirObj.createSync(recursive: true);
  }

  // 5. Generate migration file from template
  _createMigrationFile(nextVersion, className, filename);

  // 6. Re-generate migration_registrar.dart
  _registerMigration(filename, migrationsDirObj);

  stdout.write('Migration $filename created with version $nextVersion\n');
}

Slug _getSlug(List<String> args) {
  final rawInput = args.join(' ').trim();
  final description = rawInput.isEmpty ? 'create migration' : rawInput;

  final words = description
      .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();

  final snakeCaseSlug = words.map((w) => w.toLowerCase()).join('_');
  final pascalCaseSlug = words
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join('');

  return Slug(snakeCaseSlug: snakeCaseSlug, pascalCaseSlug: pascalCaseSlug);
}

String _formatDateTimeToIso8601Utc(DateTime dateTime) {
  final now = DateTime.now().toUtc();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  final hh = now.hour.toString().padLeft(2, '0');
  final mm = now.minute.toString().padLeft(2, '0');
  final ss = now.second.toString().padLeft(2, '0');
  return '${y}_${m}_${d}_$hh$mm$ss';
}

int _bumpDbVersion(File versionFile) {
  final versionContent = versionFile.readAsStringSync();
  final versionMatch = RegExp(
    r'static const int dbVersion = (\d+);',
  ).firstMatch(versionContent);
  if (versionMatch == null) {
    stderr.writeln('Error: Could not parse dbVersion from $dbVersionPath');
    exit(1);
  }

  final currentVersion = int.parse(versionMatch.group(1)!);
  final nextVersion = currentVersion + 1;

  final updatedVersionContent = versionContent.replaceFirst(
    'static const int dbVersion = $currentVersion;',
    'static const int dbVersion = $nextVersion;',
  );
  versionFile.writeAsStringSync(updatedVersionContent);
  stdout.writeln(
    'Bumped dbVersion in $dbVersionPath: $currentVersion -> $nextVersion',
  );
  return nextVersion;
}

void _createMigrationFile(int nextVersion, String className, String filename) {
  final templateFile = File(templatePath);
  if (!templateFile.existsSync()) {
    stderr.writeln('Error: Could not find template at $templatePath');
    exit(1);
  }

  final template = templateFile.readAsStringSync();
  final newContent = template
      .replaceAll('{{version}}', nextVersion.toString())
      .replaceAll('{{name}}', className);

  File('$migrationsDir/$filename').writeAsStringSync(newContent);
  stdout.writeln(
    'Created migration file: $migrationsDir/$filename (version $nextVersion)',
  );
}

void _registerMigration(String filename, Directory migrationsDirObj) {
  final migrationFiles =
      migrationsDirObj
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final imports = <String>[];
  final instances = <String>[];

  for (final file in migrationFiles) {
    final baseName = file.uri.pathSegments.last;
    final content = file.readAsStringSync();

    final match = RegExp(
      r'class\s+([A-Za-z0-9_]+)\s+implements\s+Migration',
    ).firstMatch(content);
    if (match != null) {
      final cls = match.group(1)!;
      imports.add("import 'migrations/$baseName';");
      instances.add('  $cls(),');
    }
  }

  final registrarContent =
      '''
import 'package:carpe_diem/features/common/data/database/migration.dart';
${imports.join('\n')}

final List<Migration> allMigrations = [
${instances.join('\n')}
];
''';

  File(registrarPath).writeAsStringSync(registrarContent);
}
