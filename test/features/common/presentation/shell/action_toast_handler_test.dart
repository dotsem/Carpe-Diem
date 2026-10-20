import 'package:carpe_diem/core/theme/app_theme.dart';
import 'package:carpe_diem/core/undo_redo/command.dart';
import 'package:carpe_diem/features/common/data/repositories/interfaces.dart';
import 'package:carpe_diem/features/common/presentation/shell/action_toast_handler.dart';
import 'package:carpe_diem/features/filter/data/models/task_filter.dart';
import 'package:carpe_diem/features/filter/presentation/providers/filter_provider.dart';
import 'package:carpe_diem/features/labels/data/models/label.dart';
import 'package:carpe_diem/features/projects/data/models/project.dart';
import 'package:carpe_diem/features/tags/data/models/tag.dart';
import 'package:carpe_diem/features/tasks/data/models/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskRepository extends Mock implements ITaskRepository {}

class MockProjectRepository extends Mock implements IProjectRepository {}

class MockTagRepository extends Mock implements ITagRepository {}

class MockLabelRepository extends Mock implements ILabelRepository {}

void main() {
  final testDate = DateTime(2026, 1, 1);
  Task makeTask(String id, {bool isUrgent = false, String? projectId}) => Task(
    id: id,
    title: 'Task $id',
    createdAt: testDate,
    isUrgent: isUrgent,
    projectId: projectId,
  );

  Project makeProject(String id, {List<String> labelIds = const []}) => Project(
    id: id,
    name: 'Project $id',
    color: const Color(0xFF00FF00),
    createdAt: testDate,
    labelIds: labelIds,
  );

  group('ActionToastHandler', () {
    late MockTaskRepository taskRepo;
    late MockProjectRepository projectRepo;
    late MockTagRepository tagRepo;
    late MockLabelRepository labelRepo;

    setUp(() {
      taskRepo = MockTaskRepository();
      projectRepo = MockProjectRepository();
      tagRepo = MockTagRepository();
      labelRepo = MockLabelRepository();
      when(() => taskRepo.repositoryName).thenReturn('Task');
      when(() => projectRepo.repositoryName).thenReturn('Project');
      when(() => tagRepo.repositoryName).thenReturn('Tag');
      when(() => labelRepo.repositoryName).thenReturn('Label');
    });

    group('isTaskHidden', () {
      test('evaluates filter emptiness and bypass correctly', () {
        final task = makeTask('1');
        expect(
          ActionToastHandler.isTaskHidden(
            task: task,
            filterState: const FilterState(filter: TaskFilter()),
            projects: [],
          ),
          isFalse,
        );
        expect(
          ActionToastHandler.isTaskHidden(
            task: task,
            filterState: const FilterState(
              filter: TaskFilter(isUrgent: true),
              isBypassed: true,
            ),
            projects: [],
          ),
          isFalse,
        );
      });

      test(
        'detects hidden by urgency, project inclusion, or label exclusion',
        () {
          expect(
            ActionToastHandler.isTaskHidden(
              task: makeTask('1', isUrgent: false),
              filterState: const FilterState(
                filter: TaskFilter(isUrgent: true),
              ),
              projects: [],
            ),
            isTrue,
          );
          expect(
            ActionToastHandler.isTaskHidden(
              task: makeTask('1', projectId: 'p1'),
              filterState: const FilterState(
                filter: TaskFilter(projectIdsIncluded: {'p2'}),
              ),
              projects: [makeProject('p1')],
            ),
            isTrue,
          );
          expect(
            ActionToastHandler.isTaskHidden(
              task: makeTask('1', projectId: 'p1'),
              filterState: const FilterState(
                filter: TaskFilter(labelIdsExcluded: {'lbl-secret'}),
              ),
              projects: [
                makeProject('p1', labelIds: ['lbl-secret']),
              ],
            ),
            isTrue,
          );
        },
      );
    });

    group('resolveExecuteToastData', () {
      test('resolves default for null and visible task creation', () {
        final nullData = ActionToastHandler.resolveExecuteToastData(
          cmd: null,
          filterState: const FilterState(),
          projects: [],
        );
        expect(nullData.icon, Icons.check_circle_outline);
        expect(nullData.subtitle, isNull);

        final visibleTask = makeTask('1');
        final createCmd = CreateCommand<Task>(
          repo: taskRepo,
          item: visibleTask,
          id: visibleTask.id,
          displayName: visibleTask.title,
        );
        final visibleData = ActionToastHandler.resolveExecuteToastData(
          cmd: createCmd,
          filterState: const FilterState(),
          projects: [],
        );
        expect(visibleData.icon, Icons.add_task);
        expect(visibleData.primaryColor, AppColors.success);
        expect(visibleData.subtitle, isNull);
      });

      test(
        'resolves hidden warning on task creation when hidden by filter',
        () {
          final hiddenTask = makeTask('1', isUrgent: false);
          final createCmd = CreateCommand<Task>(
            repo: taskRepo,
            item: hiddenTask,
            id: hiddenTask.id,
            displayName: hiddenTask.title,
          );
          final compound = CompoundCommand([createCmd], 'Create Task');
          final data = ActionToastHandler.resolveExecuteToastData(
            cmd: compound,
            filterState: const FilterState(filter: TaskFilter(isUrgent: true)),
            projects: [],
          );
          expect(data.icon, Icons.add_task);
          expect(data.primaryColor, AppColors.success);
          expect(data.subtitle, 'Hidden by active filter');
        },
      );

      test('resolves CRUD action icons and colors across models', () {
        final task = makeTask('1');
        final project = makeProject('p1');
        final tag = Tag(id: 't1', name: 'Tag');
        final label = const Label(
          id: 'l1',
          name: 'Label',
          color: Color(0xFFFFFFFF),
        );

        final updateTaskData = ActionToastHandler.resolveExecuteToastData(
          cmd: UpdateCommand<Task>(
            repo: taskRepo,
            previous: task,
            next: task,
            displayName: task.title,
          ),
          filterState: const FilterState(),
          projects: [],
        );
        expect(updateTaskData.icon, Icons.edit_outlined);
        expect(updateTaskData.primaryColor, AppColors.info);

        final deleteTaskData = ActionToastHandler.resolveExecuteToastData(
          cmd: DeleteCommand<Task>(
            repo: taskRepo,
            item: task,
            id: task.id,
            displayName: task.title,
          ),
          filterState: const FilterState(),
          projects: [],
        );
        expect(deleteTaskData.icon, Icons.delete_outline);
        expect(deleteTaskData.primaryColor, AppColors.error);

        final createProjectData = ActionToastHandler.resolveExecuteToastData(
          cmd: CreateCommand<Project>(
            repo: projectRepo,
            item: project,
            id: project.id,
            displayName: project.name,
          ),
          filterState: const FilterState(),
          projects: [],
        );
        expect(createProjectData.icon, Icons.create_new_folder_outlined);
        expect(createProjectData.primaryColor, AppColors.success);

        final createTagData = ActionToastHandler.resolveExecuteToastData(
          cmd: CreateCommand<Tag>(
            repo: tagRepo,
            item: tag,
            id: tag.id,
            displayName: tag.name,
          ),
          filterState: const FilterState(),
          projects: [],
        );
        expect(createTagData.icon, Icons.tag);
        expect(createTagData.primaryColor, AppColors.success);

        final createLabelData = ActionToastHandler.resolveExecuteToastData(
          cmd: CreateCommand<Label>(
            repo: labelRepo,
            item: label,
            id: label.id,
            displayName: label.name,
          ),
          filterState: const FilterState(),
          projects: [],
        );
        expect(createLabelData.icon, Icons.label_outline);
        expect(createLabelData.primaryColor, AppColors.success);
      });

      test(
        'resolves compound bulk commands to corresponding icons and colors',
        () {
          final bulkDelete = ActionToastHandler.resolveExecuteToastData(
            cmd: CompoundCommand([], 'Delete 3 tasks'),
            filterState: const FilterState(),
            projects: [],
          );
          expect(bulkDelete.icon, Icons.delete_sweep_outlined);
          expect(bulkDelete.primaryColor, AppColors.error);

          final bulkUpdate = ActionToastHandler.resolveExecuteToastData(
            cmd: CompoundCommand([], 'Update 4 tasks'),
            filterState: const FilterState(),
            projects: [],
          );
          expect(bulkUpdate.icon, Icons.checklist);
          expect(bulkUpdate.primaryColor, AppColors.info);

          final bulkImport = ActionToastHandler.resolveExecuteToastData(
            cmd: CompoundCommand([], 'Import 5 tasks'),
            filterState: const FilterState(),
            projects: [],
          );
          expect(bulkImport.icon, Icons.file_upload_outlined);
          expect(bulkImport.primaryColor, AppColors.info);
        },
      );
    });
  });
}
