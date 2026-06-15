import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/tasks/data/models/priority.dart';

void main() {
  group('filter', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty filter with no bypass', () {
      final state = container.read(filterProvider);
      expect(state.filter.isEmpty, true);
      expect(state.isBypassed, false);
      expect(state.activeFilter.isEmpty, true);
    });

    test('setFilter updates the state filter', () {
      const newFilter = TaskFilter(prioritiesIncluded: {Priority.high});

      container.read(filterProvider.notifier).setFilter(newFilter);

      final state = container.read(filterProvider);
      expect(state.filter.prioritiesIncluded, {Priority.high});
      expect(state.activeFilter.prioritiesIncluded, {Priority.high});
    });

    test('toggleBypass hides the active filter but preserves the original filter config', () {
      const filter = TaskFilter(prioritiesIncluded: {Priority.urgent});
      final notifier = container.read(filterProvider.notifier);

      notifier.setFilter(filter);
      notifier.toggleBypass();

      final state = container.read(filterProvider);
      expect(state.isBypassed, true);
      expect(state.filter.prioritiesIncluded, {Priority.urgent});
      expect(state.activeFilter.isEmpty, true); // Active filter is empty due to bypass

      notifier.toggleBypass();
      final stateAfterSecondToggle = container.read(filterProvider);
      expect(stateAfterSecondToggle.isBypassed, false);
      expect(stateAfterSecondToggle.activeFilter.prioritiesIncluded, {Priority.urgent});
    });

    test('clearFilter resets the filter and bypass settings', () {
      const filter = TaskFilter(prioritiesIncluded: {Priority.low});
      final notifier = container.read(filterProvider.notifier);

      notifier.setFilter(filter);
      notifier.toggleBypass();
      notifier.clearFilter();

      final state = container.read(filterProvider);
      expect(state.filter.isEmpty, true);
      expect(state.isBypassed, false);
      expect(state.activeFilter.isEmpty, true);
    });
  });
}
