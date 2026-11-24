import 'package:carpe_diem/features/settings/presentation/widgets/section.dart';
import 'package:carpe_diem/routes/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSettingsSection', () {
    for (final section in Section.values) {
      test('parses ${section.name}', () {
        final uri = Uri.parse('/settings?section=${section.name}');

        expect(parseSettingsSection(uri, null), section);
      });
    }

    test('maps legacy filtering and modes aliases', () {
      expect(
        parseSettingsSection(Uri.parse('/settings?section=filtering'), null),
        Section.filteringAndModes,
      );
      expect(
        parseSettingsSection(Uri.parse('/settings?section=modes'), null),
        Section.filteringAndModes,
      );
    });

    test('returns null for an unknown section', () {
      expect(
        parseSettingsSection(Uri.parse('/settings?section=unknown'), null),
        isNull,
      );
    });

    test('uses a Section extra when the query is absent', () {
      expect(
        parseSettingsSection(Uri.parse('/settings'), Section.planning),
        Section.planning,
      );
      expect(parseSettingsSection(Uri.parse('/settings'), Object()), isNull);
    });

    test('query parameter takes precedence over extra', () {
      expect(
        parseSettingsSection(
          Uri.parse('/settings?section=tasks'),
          Section.planning,
        ),
        Section.tasks,
      );
      expect(
        parseSettingsSection(
          Uri.parse('/settings?section=unknown'),
          Section.planning,
        ),
        isNull,
      );
    });
  });

  group('route table', () {
    final cases = <String, String>{
      '/': '/',
      '/projects': '/projects',
      '/projects/project-1': '/projects/:projectId',
      '/tasks': '/tasks',
      '/history': '/history',
      '/settings': '/settings',
      '/settings?section=filteringAndModes': '/settings',
    };

    for (final entry in cases.entries) {
      test('matches ${entry.key}', () {
        final result = appRouter.configuration.findMatch(Uri.parse(entry.key));

        expect(result.isError, isFalse);
        expect(result.fullPath, entry.value);
      });
    }

    test('rejects an unknown path', () {
      final result = appRouter.configuration.findMatch(Uri.parse('/missing'));

      expect(result.isError, isTrue);
    });
  });
}
