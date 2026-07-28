import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterAccordionNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    return {};
  }

  bool isExpanded(String key, bool defaultState) {
    return state[key] ?? defaultState;
  }

  void toggle(String key, bool defaultState) {
    final current = state[key] ?? defaultState;
    state = {...state, key: !current};
  }
}

final filterAccordionProvider =
    NotifierProvider<FilterAccordionNotifier, Map<String, bool>>(() {
      return FilterAccordionNotifier();
    });
