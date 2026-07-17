import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tags/presentation/utils/update_tag_command.dart';
import 'package:carpe_diem/features/tags/presentation/utils/delete_tag_command.dart';
import '../../../../helpers/mock_repositories.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const Tag(id: '', name: ''));
    registerFallbackValue(Task(id: '', title: '', createdAt: DateTime.now()));
  });

  group('UpdateTagCommand', () {
    late MockTagRepository mockTagRepo;
    late MockTagIconRepository mockIconRepo;
    late MockTaskRepository mockTaskRepo;

    setUp(() {
      mockTagRepo = MockTagRepository();
      mockIconRepo = MockTagIconRepository();
      mockTaskRepo = MockTaskRepository();
    });

    test('should rename tag, move icon, and update task titles on execute and undo', () async {
      final prevTag = const Tag(id: 't1', name: 'work');
      final nextTag = const Tag(id: 't1', name: 'job');

      when(() => mockTagRepo.update(any())).thenAnswer((_) async {});
      when(() => mockIconRepo.getAllIconDatas()).thenAnswer((_) async => {'work': Icons.work});
      when(() => mockIconRepo.deleteIconDataForTag('work')).thenAnswer((_) async {});
      when(() => mockIconRepo.setIconDataForTag('job', Icons.work)).thenAnswer((_) async {});
      when(() => mockIconRepo.setIconDataForTag('work', Icons.work)).thenAnswer((_) async {});
      when(() => mockIconRepo.deleteIconDataForTag('job')).thenAnswer((_) async {});

      final task1 = Task(id: 'task1', title: 'Finish #work stuff', createdAt: DateTime.now(), tagIds: const ['t1']);
      final task2 = Task(id: 'task2', title: 'Other task #workplace', createdAt: DateTime.now(), tagIds: const ['t1', 't2']);
      when(() => mockTaskRepo.getAll(prioritizeDeadlines: false)).thenAnswer((_) async => [task1, task2]);
      when(() => mockTaskRepo.getById('task1')).thenAnswer((_) async => task1.copyWith(title: 'Finish #job stuff'));
      when(() => mockTaskRepo.update(any())).thenAnswer((_) async {});

      final command = UpdateTagCommand(
        tagRepo: mockTagRepo,
        iconRepo: mockIconRepo,
        taskRepo: mockTaskRepo,
        previousTag: prevTag,
        nextTag: nextTag,
      );

      await command.execute();

      verify(() => mockTagRepo.update(nextTag)).called(1);
      verify(() => mockIconRepo.deleteIconDataForTag('work')).called(1);
      verify(() => mockIconRepo.setIconDataForTag('job', Icons.work)).called(1);

      final capturedTasks = verify(() => mockTaskRepo.update(captureAny())).captured.cast<Task>();
      expect(capturedTasks.length, equals(1));
      expect(capturedTasks[0].title, equals('Finish #job stuff'));

      await command.undo();

      verify(() => mockTagRepo.update(prevTag)).called(1);
      verify(() => mockIconRepo.deleteIconDataForTag('job')).called(1);
      verify(() => mockIconRepo.setIconDataForTag('work', Icons.work)).called(1);
      verify(() => mockTaskRepo.getById('task1')).called(1);
    });
  });

  group('DeleteTagCommand', () {
    late MockTagRepository mockTagRepo;
    late MockTagIconRepository mockIconRepo;
    late MockTaskRepository mockTaskRepo;

    setUp(() {
      mockTagRepo = MockTagRepository();
      mockIconRepo = MockTagIconRepository();
      mockTaskRepo = MockTaskRepository();
    });

    test('should delete tag, delete icon, strip hashtag and update tagIds on execute and undo (including picker-only tags)', () async {
      final tag = const Tag(id: 't1', name: 'work');

      when(() => mockTagRepo.delete(tag.id)).thenAnswer((_) async {});
      when(() => mockTagRepo.insert(tag)).thenAnswer((_) async {});
      when(() => mockIconRepo.getAllIconDatas()).thenAnswer((_) async => {'work': Icons.work});
      when(() => mockIconRepo.deleteIconDataForTag('work')).thenAnswer((_) async {});
      when(() => mockIconRepo.setIconDataForTag('work', Icons.work)).thenAnswer((_) async {});

      // task1 has inline hashtag
      final task1 = Task(id: 'task1', title: 'Finish #work stuff', createdAt: DateTime.now(), tagIds: const ['t1']);
      // task2 has it only in tagIds (picker-only)
      final task2 = Task(id: 'task2', title: 'Other task', createdAt: DateTime.now(), tagIds: const ['t1', 't2']);
      // task3 is unrelated
      final task3 = Task(id: 'task3', title: 'Unrelated task', createdAt: DateTime.now(), tagIds: const ['t3']);

      when(() => mockTaskRepo.getAll(prioritizeDeadlines: false)).thenAnswer((_) async => [task1, task2, task3]);
      when(() => mockTaskRepo.update(any())).thenAnswer((_) async {});

      // Mock task queries on undo (representing their states post-execute)
      when(() => mockTaskRepo.getById('task1')).thenAnswer((_) async => task1.copyWith(title: 'Finish stuff', tagIds: []));
      when(() => mockTaskRepo.getById('task2')).thenAnswer((_) async => task2.copyWith(tagIds: ['t2']));

      final command = DeleteTagCommand(
        tagRepo: mockTagRepo,
        iconRepo: mockIconRepo,
        taskRepo: mockTaskRepo,
        tag: tag,
      );

      await command.execute();

      verify(() => mockTagRepo.delete(tag.id)).called(1);
      verify(() => mockIconRepo.deleteIconDataForTag('work')).called(1);

      // Verify task updates during execute
      final capturedTasks = verify(() => mockTaskRepo.update(captureAny())).captured.cast<Task>();
      expect(capturedTasks.length, equals(2));

      // Task 1 title should be stripped, t1 removed from tagIds
      final updatedTask1 = capturedTasks.firstWhere((t) => t.id == 'task1');
      expect(updatedTask1.title, equals('Finish stuff'));
      expect(updatedTask1.tagIds, isNot(contains('t1')));

      // Task 2 title should remain unchanged, t1 removed from tagIds
      final updatedTask2 = capturedTasks.firstWhere((t) => t.id == 'task2');
      expect(updatedTask2.title, equals('Other task'));
      expect(updatedTask2.tagIds, equals(['t2']));

      // Undo
      await command.undo();

      verify(() => mockTagRepo.insert(tag)).called(1);
      verify(() => mockIconRepo.setIconDataForTag('work', Icons.work)).called(1);
      verify(() => mockTaskRepo.getById('task1')).called(1);
      verify(() => mockTaskRepo.getById('task2')).called(1);
    });
  });
}
