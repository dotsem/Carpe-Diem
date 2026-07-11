import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/tags/presentation/providers/tag_icon_provider.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/mock_repositories.dart';

void main() {
  group('tags', () {
    late MockTagIconRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockTagIconRepository();
      container = ProviderContainer(overrides: [tagIconRepositoryProvider.overrideWithValue(mockRepo)]);
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with empty map', () {
      final state = container.read(tagIconProvider);
      expect(state, isEmpty);
    });

    test('should load tag icons from repository', () async {
      final mockIcons = {'bug': Icons.bug_report, 'feat': Icons.add_circle};
      when(() => mockRepo.getAllIconDatas()).thenAnswer((_) async => mockIcons);

      await container.read(tagIconProvider.notifier).loadIcons();

      final state = container.read(tagIconProvider);
      expect(state, equals(mockIcons));
      verify(() => mockRepo.getAllIconDatas()).called(1);
    });

    test('should set tag icon and reload', () async {
      when(() => mockRepo.getAllIconDatas()).thenAnswer((_) async => {'bug': Icons.bug_report});
      when(() => mockRepo.setIconDataForTag('bug', Icons.bug_report)).thenAnswer((_) async => {});

      await container.read(tagIconProvider.notifier).setIcon('bug', Icons.bug_report);

      final state = container.read(tagIconProvider);
      expect(state['bug'], equals(Icons.bug_report));
      verify(() => mockRepo.setIconDataForTag('bug', Icons.bug_report)).called(1);
      verify(() => mockRepo.getAllIconDatas()).called(1);
    });

    test('should delete tag icon and reload', () async {
      when(() => mockRepo.getAllIconDatas()).thenAnswer((_) async => {});
      when(() => mockRepo.deleteIconDataForTag('bug')).thenAnswer((_) async => {});

      await container.read(tagIconProvider.notifier).deleteIcon('bug');

      final state = container.read(tagIconProvider);
      expect(state['bug'], isNull);
      verify(() => mockRepo.deleteIconDataForTag('bug')).called(1);
      verify(() => mockRepo.getAllIconDatas()).called(1);
    });
  });
}
