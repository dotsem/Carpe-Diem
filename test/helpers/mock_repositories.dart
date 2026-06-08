import 'package:mocktail/mocktail.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';

class MockTaskRepository extends Mock implements ITaskRepository {}
class MockProjectRepository extends Mock implements IProjectRepository {}
class MockLabelRepository extends Mock implements ILabelRepository {}
class MockHistoryRepository extends Mock implements IHistoryRepository {}
class MockSettingsRepository extends Mock implements ISettingsRepository {}
