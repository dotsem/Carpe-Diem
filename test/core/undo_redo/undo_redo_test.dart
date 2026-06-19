import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:carpe_diem/core/undo_redo/undo_redo_provider.dart';
import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';

class MockCommand extends Mock implements Command {}

class MockCrudRepository extends Mock implements ICrudRepository<String> {}

void main() {
  group('UndoRedoNotifier', () {
    late ProviderContainer container;
    late UndoRedoNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(undoRedoProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('should have initial empty state', () {
      final state = notifier.state;
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isFalse);
      expect(state.undoStack, isEmpty);
      expect(state.redoStack, isEmpty);
      expect(state.isProcessing, isFalse);
      expect(state.lastOperationType, equals(UndoRedoOperationType.none));
    });

    test('should execute command and update stack state', () async {
      final cmd = MockCommand();
      when(() => cmd.execute()).thenAnswer((_) async => {});
      when(() => cmd.description).thenReturn('Mock Action');

      await notifier.execute(cmd);

      verify(() => cmd.execute()).called(1);
      final state = notifier.state;
      expect(state.canUndo, isTrue);
      expect(state.canRedo, isFalse);
      expect(state.undoStack, equals([cmd]));
      expect(state.redoStack, isEmpty);
      expect(state.undoDescription, equals('Mock Action'));
      expect(state.redoDescription, isNull);
    });

    test('should handle undo and redo operations correctly', () async {
      final cmd = MockCommand();
      when(() => cmd.execute()).thenAnswer((_) async => {});
      when(() => cmd.undo()).thenAnswer((_) async => {});
      when(() => cmd.description).thenReturn('Mock Action');

      await notifier.execute(cmd);
      await notifier.undo();

      verify(() => cmd.undo()).called(1);
      expect(notifier.state.canUndo, isFalse);
      expect(notifier.state.canRedo, isTrue);
      expect(notifier.state.undoStack, isEmpty);
      expect(notifier.state.redoStack, equals([cmd]));

      await notifier.redo();

      verify(() => cmd.execute()).called(2);
      expect(notifier.state.canUndo, isTrue);
      expect(notifier.state.canRedo, isFalse);
      expect(notifier.state.undoStack, equals([cmd]));
      expect(notifier.state.redoStack, isEmpty);
    });

    test('should ignore commands when isProcessing is true', () async {
      final completer = Completer<void>();
      final firstCmd = MockCommand();
      final secondCmd = MockCommand();

      when(() => firstCmd.execute()).thenAnswer((_) => completer.future);
      when(() => firstCmd.description).thenReturn('First');
      when(() => secondCmd.execute()).thenAnswer((_) async => {});
      when(() => secondCmd.description).thenReturn('Second');

      // start executing first command (async, doesn't complete yet)
      final future = notifier.execute(firstCmd);

      expect(notifier.state.isProcessing, isTrue);

      // try executing second command while first is still running
      await notifier.execute(secondCmd);

      // resolve first command execution
      completer.complete();
      await future;

      // second command should have been ignored
      verifyNever(() => secondCmd.execute());
      expect(notifier.state.undoStack, equals([firstCmd]));
    });

    test('should evict oldest command when exceeding stack limit', () async {
      // populate 50 commands
      final commands = List.generate(50, (i) {
        final cmd = MockCommand();
        when(() => cmd.execute()).thenAnswer((_) async => {});
        when(() => cmd.description).thenReturn('Command $i');
        return cmd;
      });

      for (final cmd in commands) {
        await notifier.execute(cmd);
      }

      expect(notifier.state.undoStack.length, equals(50));
      expect(notifier.state.undoStack.first, equals(commands.first));

      // push 51st command
      final extraCmd = MockCommand();
      when(() => extraCmd.execute()).thenAnswer((_) async => {});
      when(() => extraCmd.description).thenReturn('Extra Command');

      await notifier.execute(extraCmd);

      expect(notifier.state.undoStack.length, equals(50));
      expect(notifier.state.undoStack.first, equals(commands[1]));
      expect(notifier.state.undoStack.last, equals(extraCmd));
    });

    test('should return unmodifiable lists for stacks', () async {
      final cmd = MockCommand();
      when(() => cmd.execute()).thenAnswer((_) async => {});
      when(() => cmd.description).thenReturn('Mock Action');

      await notifier.execute(cmd);

      expect(() => notifier.state.undoStack.add(cmd), throwsUnsupportedError);
      expect(() => notifier.state.redoStack.add(cmd), throwsUnsupportedError);
    });

    test('should support jumping back and forth via jumpTo', () async {
      final c1 = MockCommand();
      final c2 = MockCommand();
      final c3 = MockCommand();

      for (final c in [c1, c2, c3]) {
        when(() => c.execute()).thenAnswer((_) async => {});
        when(() => c.undo()).thenAnswer((_) async => {});
        when(() => c.description).thenReturn('Cmd');
        await notifier.execute(c);
      }

      // stack: [c1, c2, c3]. jumpTo c1 should undo c3 and c2.
      await notifier.jumpTo(c1);

      verify(() => c3.undo()).called(1);
      verify(() => c2.undo()).called(1);
      verifyNever(() => c1.undo());

      expect(notifier.state.undoStack, equals([c1]));
      expect(notifier.state.redoStack, equals([c3, c2]));

      // jumpTo c3 should redo c2 and c3.
      await notifier.jumpTo(c3);

      verify(() => c2.execute()).called(2); // once initially, once on jumpTo
      verify(() => c3.execute()).called(2);

      expect(notifier.state.undoStack, equals([c1, c2, c3]));
      expect(notifier.state.redoStack, isEmpty);
    });
  });

  group('Commands Class Tests', () {
    late MockCrudRepository mockRepo;

    setUp(() {
      mockRepo = MockCrudRepository();
      when(() => mockRepo.repositoryName).thenReturn('TestItem');
    });

    test('CreateCommand triggers insert and delete', () async {
      when(() => mockRepo.insert(any())).thenAnswer((_) async => {});
      when(() => mockRepo.delete(any())).thenAnswer((_) async => {});

      final cmd = CreateCommand<String>(repo: mockRepo, item: 'item1', id: '1', displayName: 'Item One');

      expect(cmd.description, equals('Create TestItem: "Item One"'));

      await cmd.execute();
      verify(() => mockRepo.insert('item1')).called(1);

      await cmd.undo();
      verify(() => mockRepo.delete('1')).called(1);
    });

    test('UpdateCommand triggers update with next and previous', () async {
      when(() => mockRepo.update(any())).thenAnswer((_) async => {});

      final cmd = UpdateCommand<String>(
        repo: mockRepo,
        previous: 'item_old',
        next: 'item_new',
        displayName: 'Item Config',
      );

      expect(cmd.description, equals('Update TestItem: "Item Config"'));

      await cmd.execute();
      verify(() => mockRepo.update('item_new')).called(1);

      await cmd.undo();
      verify(() => mockRepo.update('item_old')).called(1);
    });

    test('DeleteCommand triggers delete and insert', () async {
      when(() => mockRepo.delete(any())).thenAnswer((_) async => {});
      when(() => mockRepo.insert(any())).thenAnswer((_) async => {});

      final cmd = DeleteCommand<String>(repo: mockRepo, item: 'item1', id: '1', displayName: 'Item One');

      expect(cmd.description, equals('Delete TestItem: "Item One"'));

      await cmd.execute();
      verify(() => mockRepo.delete('1')).called(1);

      await cmd.undo();
      verify(() => mockRepo.insert('item1')).called(1);
    });
  });
}
