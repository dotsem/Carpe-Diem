# 0001: Freezed for data models

Status: done (#145)

## Why

- `Task.copyWith` needs 8 `clearX` flags to set a nullable field to null. `Project.copyWith` can't clear `description` or `deadline` at all.
- `Task`, `Project`, `Label` and `Tag` have no `==`, so they compare by identity. `TaskFilter` and `FilterMode` maintain `==`/`hashCode` by hand.
- **Bug:** `Task.copyWith(status: done)` without an explicit `completedAt` sets `completedAt` to now, even when the task was already done. Unscheduling a done task, and likely reordering inside the done column, quietly rewrites the completion date, which skews history and insights.

## Scope / Non-goals

- In scope: `Task`, `Project`, `Label`, `Tag`, `TaskFilter`, `FilterMode`.
- Non-goals:
  - Notifier state classes (`RightSidebarState`, `TaskDragState`, `TaskReorderSlot`) and small value types (`TaskPlacement`, history models). They stay hand-written.
  - `toMap`/`fromMap` stay hand-written: they map SQLite rows (bools as 0/1, enum indices, join-table ids), not JSON.
  - `json_serializable`, `riverpod_generator`: still banned.

## Design

**Shape (freezed 3):**

```dart
@freezed
abstract class Task with _$Task {
  const Task._();
  const factory Task({required String id, ... }) = _Task;

  bool get isOverdue { ... }              // getters, Project's Comparable, Label.empty() kept as-is
  Map<String, dynamic> toMap() => { ... };
  factory Task.fromMap(Map<String, dynamic> map, { ... }) => Task( ... );
}
```

**`copyWith` semantics change:** leaving a parameter out keeps the value, passing `null` clears it. All `clearX` flags are removed.

- `clearX: true` → `x: null`
- `clearX: cond, x: v` → `x: cond ? null : v`, or just `x: v` where `v` is already null in the clear case (form submit handler).
- Project forms can clear `description` and `deadline` by passing null through `copyWith`.
- Filter modes can clear their icon when `iconCodePoint` is null.

**`completedAt` becomes explicit (hard to reverse, surprising, real trade-off):**

```dart
/// Sets [status]; touches [completedAt] only when the done-ness changes.
Task withStatus(TaskStatus status, {DateTime? at});
```

- Moving into done sets `completedAt = at ?? now`; moving out of done clears it; done → done keeps it.
- Every status change goes through `withStatus`. Freezed's `copyWith(status:)` still exists, but it no longer has side effects.
- Rejected:
  - A hand-written `copyWith` override that keeps the hidden rule: it keeps the bug-prone magic.
  - Leaving the rule to each caller: 7 call sites would each have to remember it.

**Equality:** generated deep `==`/`hashCode`. Set fields in `TaskFilter` stay order-independent, same as the current `setEquals`.

**Collections:** freezed wraps List/Set fields in unmodifiable views. No code mutates model lists in place today (checked).

**Rejected alternatives:**

- `equatable`: only gives `==`, not `copyWith`.
- `dart_mappable`: generates the mapping we explicitly want to keep by hand.
- Status quo: keeps the clear flags and the bug.

## Risks

1. A status call site is missed or converted wrong, so `completedAt` is wrong again.
2. Equality changes when Riverpod notifies: Riverpod 3 skips an update whose new state `==` the old one. Checked: notifier states holding models are lists (compared by identity) or `parentCompletionPromptProvider`, which resets to null after each prompt.
3. A remaining in-place mutation of a model list throws at runtime (unmodifiable view). Done: no `.add`/`.remove` mutations were found on model lists.
4. Generated files go stale when someone edits a model without running `build_runner`.
5. Any `copyWith(x: maybeNull)` where null previously meant keep can now clear data unexpectedly, including bulk edit, scheduling, forms, filters, and UI reorder paths.

## Plan

Single PR.

1. **Rules:**
   - `CLAUDE.md` #2 and `GUIDELINES.md` §2.3: allow `freezed` for models; keep the other bans.
   - Exempt `*.freezed.dart` from the 300-line rule.
   - Add `dart run build_runner build -d` to the verification table.
2. **Config:**
   - `pubspec.yaml`: `freezed_annotation`; dev `freezed`, `build_runner`.
   - `analysis_options.yaml`: exclude `**/*.freezed.dart`.
   - `justfile`: add a `gen` recipe.
3. **Models:** `lib/features/{tasks,projects,labels,tags,filter}/data/models/*.dart`; add `Task.withStatus`.
4. **Status sites:**
   - `task_completion_service.dart`: 5 sites.
   - `task_scheduling_service.dart`: 2 sites. Pass the status unchanged, or `withStatus(todo)` when `resetStatus`.
5. **Clear-flag sites:**
   - `task_scheduling_service.dart`
   - `task_crud_service.dart`
   - `task_hierarchy_actions.dart`
   - `task_bulk_actions.dart`
   - `task_form_submit_handler.dart`
   - `filter_provider.dart`
   - `filter_dialog.dart`
   - Tests that use `clearX`.

   The `clearX` names in the bulk-edit API (`bulk_tasks_actions.dart`, `bulkUpdateTasks`) stay: they describe user intent, not model `copyWith` arguments.
6. Delete the hand-written `==`/`hashCode` in `TaskFilter` and `FilterMode`.
7. Commit the generated `*.freezed.dart` files.

## Verification

- **Risk 1:**
  - Unit tests for `withStatus`: todo→done sets `completedAt`; done→done keeps it; done→todo and done→review clear it; `at` is honoured.
  - Regression test: unscheduling a done task keeps its `completedAt`.
- **Risk 2:** run the full `flutter test`. Manual check: the parent-completion prompt still appears twice in a row for the same parent.
- **Risk 3:** `grep` for `.add(`/`.remove(` on model list fields (`labelIds`, `tagIds`, filter id sets) before merging.
- **Risk 4:** CI (`verify-generated: true`) runs `build_runner build` and fails if `git status --porcelain` is not empty, which also catches uncommitted generated files.
- **Risk 5:** audit every model `copyWith` call that passes a value which can be null. The existing bulk-edit and task-form tests pass, plus tests that bulk edit without clear flags keeps fields and that each clear flag, including `clearDeadline`, clears its field.
- **Manual:** complete a task, unschedule a done task, drag inside the done column, then check that dates on the history screen haven't changed.
- `dart format .`, `flutter analyze`, `flutter test` all pass.

## Assumptions

- Latest freezed 3.x; the public names `toMap`/`fromMap`/`copyWith`/`Label.empty` stay.
- Tasks created as done by the markdown importer still get no `completedAt`; that's existing behaviour and out of scope.
- drift is not allowed by this spec; it gets its own.
