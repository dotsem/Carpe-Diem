import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_provider.dart';
import 'package:carpe_diem/features/common/presentation/shell/right_sidebar/right_sidebar_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RightSidebarNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is closed with null activePanel and empty history', () {
      final state = container.read(rightSidebarProvider);
      expect(state.isOpen, isFalse);
      expect(state.activePanel, isNull);
      expect(state.history, isEmpty);
    });

    test('open sets activePanel when previously closed', () {
      final notifier = container.read(rightSidebarProvider.notifier);
      const panel = AddTaskPanel();

      notifier.open(panel);

      final state = container.read(rightSidebarProvider);
      expect(state.isOpen, isTrue);
      expect(state.activePanel, equals(panel));
      expect(state.history, isEmpty);
    });

    test('open pushes previous activePanel into history when opening a new panel', () {
      final notifier = container.read(rightSidebarProvider.notifier);
      const panel1 = AddTaskPanel();
      const panel2 = AddProjectPanel();

      notifier.open(panel1);
      notifier.open(panel2);

      final state = container.read(rightSidebarProvider);
      expect(state.isOpen, isTrue);
      expect(state.activePanel, equals(panel2));
      expect(state.history, equals([panel1]));
    });

    test('open ignores duplicate consecutive panel pushes', () {
      final notifier = container.read(rightSidebarProvider.notifier);
      const panel = EditTaskPanel('task_123');

      notifier.open(panel);
      notifier.open(panel);

      final state = container.read(rightSidebarProvider);
      expect(state.activePanel, equals(panel));
      expect(state.history, isEmpty);
    });

    test('close resets state to closed with empty history', () {
      final notifier = container.read(rightSidebarProvider.notifier);
      notifier.open(const AddTaskPanel());
      notifier.open(const AddProjectPanel());

      notifier.close();

      final state = container.read(rightSidebarProvider);
      expect(state.isOpen, isFalse);
      expect(state.activePanel, isNull);
      expect(state.history, isEmpty);
    });

    test('pop closes sidebar when history is empty', () {
      final notifier = container.read(rightSidebarProvider.notifier);
      notifier.open(const AddTaskPanel());

      notifier.pop();

      final state = container.read(rightSidebarProvider);
      expect(state.isOpen, isFalse);
      expect(state.activePanel, isNull);
      expect(state.history, isEmpty);
    });

    test('pop restores last panel from history', () {
      final notifier = container.read(rightSidebarProvider.notifier);
      const panel1 = AddTaskPanel();
      const panel2 = EditTaskPanel('task_456');

      notifier.open(panel1);
      notifier.open(panel2);

      notifier.pop();

      final state = container.read(rightSidebarProvider);
      expect(state.isOpen, isTrue);
      expect(state.activePanel, equals(panel1));
      expect(state.history, isEmpty);
    });

    test('RightSidebarPanel subclasses equality and hashCode work correctly', () {
      const panelA1 = AddTaskPanel(initialParentId: 'p1');
      const panelA2 = AddTaskPanel(initialParentId: 'p1');
      const panelB = AddTaskPanel(initialParentId: 'p2');

      expect(panelA1, equals(panelA2));
      expect(panelA1.hashCode, equals(panelA2.hashCode));
      expect(panelA1, isNot(equals(panelB)));

      const edit1 = EditTaskPanel('t1');
      const edit2 = EditTaskPanel('t1');
      expect(edit1, equals(edit2));
      expect(edit1.hashCode, equals(edit2.hashCode));
    });
  });
}
