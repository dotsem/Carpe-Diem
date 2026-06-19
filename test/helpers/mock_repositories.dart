import 'package:mocktail/mocktail.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';

class MockTaskRepository extends ITaskRepository with Mock {}

class MockProjectRepository extends IProjectRepository with Mock {}

class MockLabelRepository extends ILabelRepository with Mock {}

class MockHistoryRepository extends Mock implements IHistoryRepository {}

class MockSettingsRepository extends Mock implements ISettingsRepository {}
