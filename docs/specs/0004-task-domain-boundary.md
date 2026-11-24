# 0004: Task domain boundary

Status: draft

## Why

- `domain`, `data` and `core` import from `presentation` in 7 files. Domain code depends on `SettingsState`, `TaskState`, `TaskNotifier` and the settings keys, so changing a screen's state or a settings key can break reorder and CRUD logic.
- `TaskReorderService.optimisticallyReorder` builds a fake `SettingsState` from settings-key strings just to pass two booleans down.
- Services that need the repository are classes made only of static methods. Each call passes `repo` and `settings` through by hand, so the parameter lists grow: `TaskNotifier.addTask` has 11 named parameters and copies all of them into `TaskCrudService.buildNewTask`, which has 13.
- `TaskReorderUtils.inSameGroup`, `getEffectiveRank`, `getUrgentSectionEndIndex` and the whole of `TaskHierarchyReorderUtils` just forward to `TaskReorderEngine`.
- `TaskFormDetailsLoader`, a widget helper, reads `taskRepositoryProvider` directly when the parent task isn't in state.

## Scope / Non-goals

In scope:

- Remove every `presentation/` import from `lib/features/*/domain`, `lib/features/*/data` and `lib/core`.
- Turn the task services that depend on the repository into injected instances.
- Collapse the 11- and 13-parameter task-creation path into one value.
- Delete the reorder wrappers that only forward to `TaskReorderEngine`.
- Fix the direct repository read in `TaskFormDetailsLoader`.

Non-goals:

- Pure static helpers with no dependencies stay static: `TaskReorderEngine`, `TaskSortUtils`, `TaskCompletionService` and `TaskMarkdownParser`. Injecting them buys nothing.
- No behaviour changes: ordering, undo/redo and propagation stay exactly as they are.
- Projects, tags and the other features. Only `tasks` has service classes.
- File sizes and moving `core/utils` files belong to [0006](0006-file-size-and-module-boundaries.md).

## Design

**`TaskPrefs`, a domain value that replaces `SettingsState` in domain code.**

```dart
// features/tasks/domain/task_prefs.dart
typedef TaskPrefs = ({
  bool prioritizeDeadlines,
  bool prioritizeOverdue,
  bool inheritParentDeadline,
});
```

- `SettingsState` gains `TaskPrefs get taskPrefs`. Presentation code converts once, and domain code never sees `SettingsState`.
- Records get value equality without boilerplate.
- Rejected: a freezed class, which means codegen for three bools.
- Rejected: two separate types, one for ordering and one for inheritance. Pure functions ignore the field they don't use.

**Task services become instances with injected dependencies.** This covers `TaskCrudService`, `TaskReorderService`, `SubtaskService`, `TaskSchedulingService` and `DeadlinePropagationService`.

```dart
class TaskCrudService {
  TaskCrudService(this._repo, this._prefs);
  final ITaskRepository _repo;
  final TaskPrefs Function() _prefs;
}

final taskCrudServiceProvider = Provider<TaskCrudService>(
  (ref) => TaskCrudService(
    ref.watch(taskRepositoryProvider),
    () => ref.read(settingsProvider).taskPrefs,
  ),
);
```

- Prefs are passed as a getter, not a value. If the provider watched settings instead, every settings change would rebuild the service and then `TaskNotifier`, which would wipe the loaded task state.
- Methods that already take no repository or prefs, such as `TaskSchedulingService.pickRandomTask`, become instance methods anyway, so each class has one way to be called.
- Rejected: top-level functions. They keep the `repo:`/`settings:` threading this spec is meant to remove.

**`TaskDraft` for task creation.** It's a hand-written `const` class with the 11 fields `addTask` takes today, and the same defaults. 0001 already says small value types stay hand-written.

- `TaskNotifier.addTask(TaskDraft draft)` and `TaskCrudService.buildNewTask(TaskDraft draft)`. `placement` goes inside the draft.
- Rejected: passing a `Task` with a blank `id`. The code already builds a `dummyTask` this way, and it's a trap.

**Code that touches presentation state moves to presentation:**

- `TaskReorderService.applyOptimisticTask`, `applyBulkOptimisticReorder` and `applyBulkOptimisticReorderList` return or take `TaskState`. They become an extension on `TaskState` in `tasks/presentation/providers/`.
- `TaskReorderUtils.dispatchReorder`, `moveToTop` and `moveToBottom` call `TaskNotifier`. They move next to the task actions in `presentation/providers/actions/`. The pure `handleReorder` and `handleMultiReorder` stay in domain.
- `tag_icon_constants.dart` imports only Material. It moves to `lib/core/constants/`, and both `FilterMode` (data) and `TagIconRepository` (data) import it from there.

**`TaskFormDetailsLoader`** calls a new `TaskNotifier.findById(String id)`, which checks state first and then the repository. The widget stops touching repositories.

## Risks

- **A service rebuild wipes task state.** If a service provider ever uses `ref.watch` on settings, `TaskNotifier` rebuilds and loses its loaded state.
- **The swap from static to instance services breaks tests.** Existing service tests call static methods with a mocked `repo:`.
- **Ordering behaves differently after the `TaskPrefs` swap,** for example if a call site maps `prioritizeOverdue` and `prioritizeDeadlines` the wrong way round.
- **Something lingers in the moved code.** The optimistic-state and dispatch code could keep a hidden import of `presentation`.

## Plan

PR 1, layering:

- Add `features/tasks/domain/task_prefs.dart` and `SettingsState.taskPrefs`.
- Swap `SettingsState` for `TaskPrefs` in `task_reorder_engine.dart`, `task_reorder_utils.dart`, `task_sort_utils.dart`, `task_crud_service.dart` and `task_reorder_service.dart`.
- Move the optimistic `TaskState` helpers and the `dispatchReorder`/`moveTo*` code into presentation, and update their 7 call sites.
- Delete the forwarding wrappers and `task_hierarchy_reorder_utils.dart`, and point their 11 callers at `TaskReorderEngine`.
- Move `tag_icon_constants.dart` to `lib/core/constants/`.

PR 2, services:

- Turn the five services into instances and add their providers next to `repository_providers.dart`.
- `TaskNotifier` and the actions mixins read services from those providers.
- Add `TaskDraft`, change `addTask` and `buildNewTask`, and update the single caller, `task_form_submit_handler.dart`.
- Add `TaskNotifier.findById` and use it in `task_form_details_loader.dart`.
- Update the tests under `test/features/tasks/domain/services/` and `test/features/tasks/presentation/providers/`.

## Verification

- Layering: `grep -rn "presentation/" lib/features/*/domain lib/features/*/data lib/core` returns nothing. Run this in PR review and once per PR.
- Ordering: the existing suites `task_reorder_contract_test`, `task_reorder_urgent_boundary_test`, `task_reorder_utils_test` and `task_sort_utils` pass unchanged apart from the type swap.
- State wipe: a provider test changes `prioritizeDeadlines` and then asserts that `taskProvider` still holds its loaded tasks.
- Service tests: build each service with a mocktail `ITaskRepository` and a fixed `TaskPrefs`.
- `flutter analyze` and `flutter test` are clean.

## Assumptions

- `inheritProjectDeadline` and the other settings that aren't used in domain stay on `SettingsState` only.
- `TaskNotifier`'s public `repo` field stays for now. Making it private is part of this cleanup only if nothing outside the notifier uses it after PR 2.
