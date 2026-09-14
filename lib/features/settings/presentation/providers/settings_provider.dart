import 'dart:convert';

import 'package:carpe_diem/core/utils/key_value_map_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:carpe_diem/features/settings/presentation/constants/settings_constants.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart'
    show FilterInteractionMethod;
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';

class SettingsState {
  final Map<String, String> _map;

  const SettingsState(this._map);

  int get maxPlanningDays => _map.getInt(
    SettingsConstants.keyMaxPlanningDays,
    SettingsConstants.maxPlanningDaysAhead,
  );
  int get firstDayOfWeek => _map.getInt(
    SettingsConstants.keyFirstDayOfWeek,
    SettingsConstants.firstDayOfWeek,
  );
  int get taskCompletionDelay => _map.getInt(
    SettingsConstants.keyTaskDelay,
    SettingsConstants.taskCompletionDelaySeconds,
  );
  bool get inheritParentDeadline => _map.getBool(
    SettingsConstants.keyInheritParentDeadline,
    SettingsConstants.inheritParentDeadline,
  );
  bool get prioritizeDeadlines => _map.getBool(
    SettingsConstants.keyPrioritizeDeadlines,
    SettingsConstants.prioritizeDeadlines,
  );
  bool get prioritizeOverdue => _map.getBool(
    SettingsConstants.keyPrioritizeOverdue,
    SettingsConstants.prioritizeOverdue,
  );
  bool get inheritProjectDeadline => _map.getBool(
    SettingsConstants.keyInheritProjectDeadline,
    SettingsConstants.inheritProjectDeadline,
  );
  ThemeMode get themeMode => _map.getEnum(
    SettingsConstants.keyThemeMode,
    ThemeMode.values,
    ThemeMode.system,
  );
  double get taskGradientWidth => _map.getDouble(
    SettingsConstants.keyTaskGradientWidth,
    SettingsConstants.defaultTaskGradientWidth,
  );
  bool get compactMode => _map.getBool(
    SettingsConstants.keyCompactMode,
    SettingsConstants.defaultCompactMode,
  );
  bool get showDescriptionOnCard => _map.getBool(
    SettingsConstants.keyShowDescriptionOnCard,
    SettingsConstants.defaultShowDescriptionOnCard,
  );
  String? get defaultProjectId => _map[SettingsConstants.keyDefaultProjectId];

  int get historyRetention => _map.getInt(
    SettingsConstants.keyHistoryRetention,
    SettingsConstants.defaultHistoryRetention,
  );
  String get defaultStatsPeriod => _map.getString(
    SettingsConstants.keyDefaultStatsPeriod,
    SettingsConstants.defaultStatsPeriod,
  );
  bool get showActiveProjectsOnly => _map.getBool(
    SettingsConstants.keyShowActiveProjectsOnly,
    SettingsConstants.defaultShowActiveProjectsOnly,
  );
  bool get enableRandomTask => _map.getBool(
    SettingsConstants.keyEnableRandomTask,
    SettingsConstants.defaultEnableRandomTask,
  );
  FilterInteractionMethod get filterInteractionMethod => _map.getEnum(
    SettingsConstants.keyFilterInteractionMethod,
    FilterInteractionMethod.values,
    FilterInteractionMethod.cycle,
  );
  bool get persistentFilter => _map.getBool(
    SettingsConstants.keyPersistentFilter,
    SettingsConstants.defaultPersistentFilter,
  );
  Absorption get tagAbsorption => _map.getEnum(
    SettingsConstants.keyTagAbsorption,
    Absorption.values,
    SettingsConstants.defaultTagAbsorption,
  );
  bool get keepTagsInTitle => _map.getBool(
    SettingsConstants.keyKeepTagsInTitle,
    SettingsConstants.defaultKeepTagsInTitle,
  );
  bool get showHashtagInTitle => _map.getBool(
    SettingsConstants.keyShowHashtagInTitle,
    SettingsConstants.defaultShowHashtagInTitle,
  );
}

class SettingsNotifier extends Notifier<SettingsState> {
  late final IKeyValueRepository _repo;
  final Map<String, Future<void>> _writeQueues = {};

  @override
  SettingsState build() {
    _repo = ref.watch(keyValueRepositoryProvider);
    return const SettingsState({});
  }

  Future<void> loadSettings() async {
    try {
      final map = await _repo.getAll();
      state = SettingsState(map);
    } catch (e) {
      debugPrint('Failed to load settings: $e');
      state = const SettingsState({});
    }
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

    final queue = _writeQueues[key] ?? Future.value();
    final writeTask = queue
        .catchError((_) {})
        .then((_) => _repo.set(key, stringValue));
    _writeQueues[key] = writeTask;
    await writeTask;
  }

  Future<void> _delete(String key) async {
    final updatedMap = Map<String, String>.from(state._map);
    updatedMap.remove(key);
    state = SettingsState(updatedMap);

    final queue = _writeQueues[key] ?? Future.value();
    final writeTask = queue.catchError((_) {}).then((_) => _repo.delete(key));
    _writeQueues[key] = writeTask;
    await writeTask;
  }

  Future<void> setMaxPlanningDays(int days) =>
      _set(SettingsConstants.keyMaxPlanningDays, days);
  Future<void> setFirstDayOfWeek(int day) =>
      _set(SettingsConstants.keyFirstDayOfWeek, day);
  Future<void> setTaskCompletionDelay(int seconds) =>
      _set(SettingsConstants.keyTaskDelay, seconds);
  Future<void> setInheritParentDeadline(bool value) =>
      _set(SettingsConstants.keyInheritParentDeadline, value);
  Future<void> setPrioritizeDeadlines(bool value) =>
      _set(SettingsConstants.keyPrioritizeDeadlines, value);
  Future<void> setPrioritizeOverdue(bool value) =>
      _set(SettingsConstants.keyPrioritizeOverdue, value);
  Future<void> setInheritProjectDeadline(bool value) =>
      _set(SettingsConstants.keyInheritProjectDeadline, value);
  Future<void> setThemeMode(ThemeMode mode) =>
      _set(SettingsConstants.keyThemeMode, mode);
  Future<void> setTaskGradientWidth(double value) =>
      _set(SettingsConstants.keyTaskGradientWidth, value);
  Future<void> setCompactMode(bool value) =>
      _set(SettingsConstants.keyCompactMode, value);
  Future<void> setShowDescriptionOnCard(bool value) =>
      _set(SettingsConstants.keyShowDescriptionOnCard, value);
  Future<void> setDefaultProjectId(String? projectId) => projectId == null
      ? _delete(SettingsConstants.keyDefaultProjectId)
      : _set(SettingsConstants.keyDefaultProjectId, projectId);
  Future<void> setHistoryRetention(int days) =>
      _set(SettingsConstants.keyHistoryRetention, days);
  Future<void> setDefaultStatsPeriod(String period) =>
      _set(SettingsConstants.keyDefaultStatsPeriod, period);
  Future<void> setShowActiveProjectsOnly(bool value) =>
      _set(SettingsConstants.keyShowActiveProjectsOnly, value);
  Future<void> setEnableRandomTask(bool value) =>
      _set(SettingsConstants.keyEnableRandomTask, value);
  Future<void> setFilterInteractionMethod(FilterInteractionMethod method) =>
      _set(SettingsConstants.keyFilterInteractionMethod, method);
  Future<void> setPersistentFilter(bool value) =>
      _set(SettingsConstants.keyPersistentFilter, value);
  Future<void> setTagAbsorption(Absorption absorption) =>
      _set(SettingsConstants.keyTagAbsorption, absorption);
  Future<void> setKeepTagsInTitle(bool value) =>
      _set(SettingsConstants.keyKeepTagsInTitle, value);
  Future<void> setShowHashtagInTitle(bool value) =>
      _set(SettingsConstants.keyShowHashtagInTitle, value);
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
