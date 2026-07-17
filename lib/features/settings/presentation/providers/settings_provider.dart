import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/features/settings/presentation/constants/settings_constants.dart';
import 'package:carpe_diem/features/tasks/data/models/task_layout.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';

class SettingsState {
  final Map<String, String> _map;

  const SettingsState(this._map);

  String _get(String key, String defaultValue) => _map[key] ?? defaultValue;

  // Task Layout
  TaskLayout getTaskLayout() {
    final layoutStr = _get('task_layout', TaskLayout.list.name);
    try {
      return TaskLayout.fromString(layoutStr);
    } catch (_) {
      return TaskLayout.list;
    }
  }

  // Max Planning Days
  int get maxPlanningDays =>
      int.tryParse(_get(SettingsConstants.keyMaxPlanningDays, SettingsConstants.maxPlanningDaysAhead.toString())) ??
      SettingsConstants.maxPlanningDaysAhead;

  // First Day of Week
  int get firstDayOfWeek =>
      int.tryParse(_get(SettingsConstants.keyFirstDayOfWeek, SettingsConstants.firstDayOfWeek.toString())) ??
      SettingsConstants.firstDayOfWeek;

  // Task Completion Delay
  int get taskCompletionDelay =>
      int.tryParse(_get(SettingsConstants.keyTaskDelay, SettingsConstants.taskCompletionDelaySeconds.toString())) ??
      SettingsConstants.taskCompletionDelaySeconds;

  // Inherit Parent Deadline
  bool get inheritParentDeadline =>
      _get(SettingsConstants.keyInheritParentDeadline, SettingsConstants.inheritParentDeadline.toString()) == 'true';

  // Prioritize Deadlines
  bool get prioritizeDeadlines =>
      _get(SettingsConstants.keyPrioritizeDeadlines, SettingsConstants.prioritizeDeadlines.toString()) == 'true';

  // Prioritize Overdue
  bool get prioritizeOverdue =>
      _get(SettingsConstants.keyPrioritizeOverdue, SettingsConstants.prioritizeOverdue.toString()) == 'true';

  // Inherit Project Deadline
  bool get inheritProjectDeadline =>
      _get(SettingsConstants.keyInheritProjectDeadline, SettingsConstants.inheritProjectDeadline.toString()) == 'true';

  // Theme Mode
  ThemeMode get themeMode {
    final modeStr = _get(SettingsConstants.keyThemeMode, ThemeMode.system.name);
    return ThemeMode.values.firstWhere((e) => e.name == modeStr, orElse: () => ThemeMode.system);
  }

  // Task Gradient Width
  double get taskGradientWidth =>
      double.tryParse(
        _get(SettingsConstants.keyTaskGradientWidth, SettingsConstants.defaultTaskGradientWidth.toString()),
      ) ??
      SettingsConstants.defaultTaskGradientWidth;

  // Compact Mode
  bool get compactMode =>
      _get(SettingsConstants.keyCompactMode, SettingsConstants.defaultCompactMode.toString()) == 'true';

  // Show Description on Card
  bool get showDescriptionOnCard =>
      _get(SettingsConstants.keyShowDescriptionOnCard, SettingsConstants.defaultShowDescriptionOnCard.toString()) ==
      'true';

  // Default Priority
  String get defaultPriority => _get(SettingsConstants.keyDefaultPriority, SettingsConstants.defaultTaskPriority);

  // Default Project
  String? get defaultProjectId {
    final id = _get(SettingsConstants.keyDefaultProjectId, 'null');
    return id == 'null' ? null : id;
  }

  // History Retention
  int get historyRetention =>
      int.tryParse(_get(SettingsConstants.keyHistoryRetention, SettingsConstants.defaultHistoryRetention.toString())) ??
      SettingsConstants.defaultHistoryRetention;

  // Default Stats Period
  String get defaultStatsPeriod => _get(SettingsConstants.keyDefaultStatsPeriod, SettingsConstants.defaultStatsPeriod);

  // Show Active Projects Only
  bool get showActiveProjectsOnly =>
      _get(SettingsConstants.keyShowActiveProjectsOnly, SettingsConstants.defaultShowActiveProjectsOnly.toString()) ==
      'true';

  // Enable Random Task Picker
  bool get enableRandomTask =>
      _get(SettingsConstants.keyEnableRandomTask, SettingsConstants.defaultEnableRandomTask.toString()) == 'true';

  // Filter Interaction Method
  FilterInteractionMethod get filterInteractionMethod {
    final methodStr = _get(
      SettingsConstants.keyFilterInteractionMethod,
      SettingsConstants.defaultFilterInteractionMethod,
    );
    return FilterInteractionMethod.fromString(methodStr);
  }

  bool get persistentFilter =>
      _get(SettingsConstants.keyPersistentFilter, SettingsConstants.defaultPersistentFilter.toString()) == 'true';

  Map<String, dynamic> get persistentFilterValues =>
      Map.from(jsonDecode(_get(SettingsConstants.keyPersistentFilterValues, '{}')));

  Absorption get tagAbsorption {
    final absorptionStr = _get(SettingsConstants.keyTagAbsorption, SettingsConstants.defaultTagAbsorption.name);
    return Absorption.fromString(absorptionStr);
  }

  bool get keepTagsInTitle =>
      _get(SettingsConstants.keyKeepTagsInTitle, SettingsConstants.defaultKeepTagsInTitle.toString()) == 'true';

  bool get showHashtagInTitle =>
      _get(SettingsConstants.keyShowHashtagInTitle, SettingsConstants.defaultShowHashtagInTitle.toString()) == 'true';
}

class SettingsNotifier extends Notifier<SettingsState> {
  late final ISettingsRepository _repo;

  @override
  SettingsState build() {
    _repo = ref.watch(settingsRepositoryProvider);
    return const SettingsState({});
  }

  Future<void> loadSettings() async {
    final map = await _repo.getAll();
    state = SettingsState(map);
  }

  Future<void> _set(String key, Object value) async {
    String stringValue;

    switch (value) {
      case String():
        stringValue = value;
        break;
      case Enum():
        stringValue = value.name;
        break;
      case Map():
        stringValue = jsonEncode(value);
        break;
      default:
        stringValue = value.toString();
        break;
    }

    final updatedMap = Map<String, String>.from(state._map);
    updatedMap[key] = stringValue;
    state = SettingsState(updatedMap);
    await _repo.set(key, stringValue);
  }

  Future<void> setTaskLayout(TaskLayout layout) => _set('task_layout', layout);
  Future<void> setMaxPlanningDays(int days) => _set(SettingsConstants.keyMaxPlanningDays, days);
  Future<void> setFirstDayOfWeek(int day) => _set(SettingsConstants.keyFirstDayOfWeek, day);
  Future<void> setTaskCompletionDelay(int seconds) => _set(SettingsConstants.keyTaskDelay, seconds);
  Future<void> setInheritParentDeadline(bool value) => _set(SettingsConstants.keyInheritParentDeadline, value);
  Future<void> setPrioritizeDeadlines(bool value) => _set(SettingsConstants.keyPrioritizeDeadlines, value);
  Future<void> setPrioritizeOverdue(bool value) => _set(SettingsConstants.keyPrioritizeOverdue, value);
  Future<void> setInheritProjectDeadline(bool value) => _set(SettingsConstants.keyInheritProjectDeadline, value);
  Future<void> setThemeMode(ThemeMode mode) => _set(SettingsConstants.keyThemeMode, mode);
  Future<void> setTaskGradientWidth(double value) => _set(SettingsConstants.keyTaskGradientWidth, value);
  Future<void> setCompactMode(bool value) => _set(SettingsConstants.keyCompactMode, value);
  Future<void> setShowDescriptionOnCard(bool value) => _set(SettingsConstants.keyShowDescriptionOnCard, value);
  Future<void> setDefaultPriority(String priority) => _set(SettingsConstants.keyDefaultPriority, priority);
  Future<void> setDefaultProjectId(String? projectId) =>
      _set(SettingsConstants.keyDefaultProjectId, projectId ?? 'null');
  Future<void> setHistoryRetention(int days) => _set(SettingsConstants.keyHistoryRetention, days);
  Future<void> setDefaultStatsPeriod(String period) => _set(SettingsConstants.keyDefaultStatsPeriod, period);
  Future<void> setShowActiveProjectsOnly(bool value) => _set(SettingsConstants.keyShowActiveProjectsOnly, value);
  Future<void> setEnableRandomTask(bool value) => _set(SettingsConstants.keyEnableRandomTask, value);
  Future<void> setFilterInteractionMethod(FilterInteractionMethod method) =>
      _set(SettingsConstants.keyFilterInteractionMethod, method);
  Future<void> setPersistentFilter(bool value) => _set(SettingsConstants.keyPersistentFilter, value);
  Future<void> setPersistentFilterValues(Map<String, dynamic> values) =>
      _set(SettingsConstants.keyPersistentFilterValues, values);
  Future<void> setTagAbsorption(Absorption absorption) => _set(SettingsConstants.keyTagAbsorption, absorption);
  Future<void> setKeepTagsInTitle(bool value) => _set(SettingsConstants.keyKeepTagsInTitle, value);
  Future<void> setShowHashtagInTitle(bool value) => _set(SettingsConstants.keyShowHashtagInTitle, value);
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
