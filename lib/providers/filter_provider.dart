import 'package:carpe_diem/data/models/task_filter.dart';
import 'package:flutter/foundation.dart';

class FilterProvider extends ChangeNotifier {
  TaskFilter _filter = const TaskFilter();
  bool _isBypassed = false;

  TaskFilter get filter => _filter;
  bool get isBypassed => _isBypassed;

  /// Returns the filter that should be applied to data.
  /// If bypassed, it returns an empty filter.
  TaskFilter get activeFilter => _isBypassed ? const TaskFilter() : _filter;

  void setFilter(TaskFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  void toggleBypass() {
    _isBypassed = !_isBypassed;
    notifyListeners();
  }

  void clearFilter() {
    if (_filter.isEmpty) return;
    _filter = const TaskFilter();
    _isBypassed = false;
    notifyListeners();
  }
}
