// Why: these mocks keep the concrete members inherited from the interface.
// ignore_for_file: prefer_mixin
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskRepository extends ITaskRepository with Mock {}

class MockProjectRepository extends IProjectRepository with Mock {}

class MockLabelRepository extends ILabelRepository with Mock {}

class MockHistoryRepository extends Mock implements IHistoryRepository {}

class MockHistoryInsightsRepository extends Mock
    implements IHistoryInsightsRepository {}

class MockKeyValueRepository extends Mock implements IKeyValueRepository {}

class MockTagRepository extends Mock implements ITagRepository {}

class MockTagIconRepository extends Mock implements ITagIconRepository {}

class MockFilterModeRepository extends Mock implements IFilterModeRepository {}
