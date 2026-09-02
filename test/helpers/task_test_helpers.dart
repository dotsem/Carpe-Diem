import 'package:carpe_diem/features/common/presentation/providers/repository_providers.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:carpe_diem/features/tasks/data/models/task_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_repositories.dart';

Task createTestTask({
  String id = 't1',
  String title = 'Test Task',
  String? description,
  String? parentId,
  TaskStatus status = TaskStatus.todo,
  DateTime? scheduledDate,
  String? projectId,
  bool isUrgent = false,
  DateTime? deadline,
  DateTime? createdAt,
  DateTime? completedAt,
  String? blockedById,
  String sortOrder = '',
  List<String> labelIds = const [],
  List<String> tagIds = const [],
}) {
  return Task(
    id: id,
    title: title,
    description: description,
    parentId: parentId,
    status: status,
    scheduledDate: scheduledDate,
    projectId: projectId,
    isUrgent: isUrgent,
    deadline: deadline,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    completedAt: completedAt,
    blockedById: blockedById,
    sortOrder: sortOrder,
    labelIds: labelIds,
    tagIds: tagIds,
  );
}

class TestTaskRepositories {
  final MockTaskRepository mockTaskRepo;
  final MockProjectRepository mockProjectRepo;
  final MockHistoryRepository mockHistoryRepo;
  final MockSettingsRepository mockSettingsRepo;
  final MockLabelRepository mockLabelRepo;
  final MockTagRepository mockTagRepo;
  final MockTagIconRepository mockTagIconRepo;

  TestTaskRepositories({
    MockTaskRepository? taskRepo,
    MockProjectRepository? projectRepo,
    MockHistoryRepository? historyRepo,
    MockSettingsRepository? settingsRepo,
    MockLabelRepository? labelRepo,
    MockTagRepository? tagRepo,
    MockTagIconRepository? tagIconRepo,
  }) : mockTaskRepo = taskRepo ?? MockTaskRepository(),
       mockProjectRepo = projectRepo ?? MockProjectRepository(),
       mockHistoryRepo = historyRepo ?? MockHistoryRepository(),
       mockSettingsRepo = settingsRepo ?? MockSettingsRepository(),
       mockLabelRepo = labelRepo ?? MockLabelRepository(),
       mockTagRepo = tagRepo ?? MockTagRepository(),
       mockTagIconRepo = tagIconRepo ?? MockTagIconRepository();

  void setupDefaultStubs() {
    when(() => mockSettingsRepo.getAll()).thenAnswer((_) async => {});
    when(() => mockSettingsRepo.set(any(), any())).thenAnswer((_) async => {});
    when(() => mockSettingsRepo.delete(any())).thenAnswer((_) async => {});
    when(
      () => mockTaskRepo.getByDate(
        any(),
        prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
      ),
    ).thenAnswer((_) async => []);
    when(() => mockTaskRepo.getOverdue(any())).thenAnswer((_) async => []);
    when(
      () => mockTaskRepo.getUnscheduled(
        prioritizeDeadlines: any(named: 'prioritizeDeadlines'),
      ),
    ).thenAnswer((_) async => []);
    when(() => mockTaskRepo.getByParent(any())).thenAnswer((_) async => []);
    when(() => mockTaskRepo.getByProject(any())).thenAnswer((_) async => []);
    when(() => mockTaskRepo.getById(any())).thenAnswer((_) async => null);
    when(() => mockTaskRepo.cleanupHistory(any())).thenAnswer((_) async => 0);
    when(() => mockLabelRepo.getAll()).thenAnswer((_) async => []);
    when(() => mockTagRepo.getAll()).thenAnswer((_) async => []);
    when(() => mockProjectRepo.getAll()).thenAnswer((_) async => []);
    when(() => mockTagIconRepo.getAllIconDatas()).thenAnswer((_) async => {});
  }

  List<Override> get providerOverrides => [
    taskRepositoryProvider.overrideWithValue(mockTaskRepo),
    projectRepositoryProvider.overrideWithValue(mockProjectRepo),
    historyRepositoryProvider.overrideWithValue(mockHistoryRepo),
    settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
    labelRepositoryProvider.overrideWithValue(mockLabelRepo),
    tagRepositoryProvider.overrideWithValue(mockTagRepo),
    tagIconRepositoryProvider.overrideWithValue(mockTagIconRepo),
  ];

  ProviderContainer createContainer() {
    return ProviderContainer(overrides: providerOverrides);
  }
}
