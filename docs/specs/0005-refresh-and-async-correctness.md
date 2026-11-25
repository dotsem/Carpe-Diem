# 0005: Refresh and async correctness

Status: done (#152)

## Why

- **Stale first load.** `TaskNotifier.build()` starts `TaskSchedulingService.autoScheduleDeadlines` as fire-and-forget. The first `loadTasksForDate` can run before it finishes, and nothing reloads afterwards, so tasks with a due deadline only show up on today after the next mutation.
- **The deadline job bypasses undo and the event log.** `autoScheduleDeadlines` calls `repo.update` once per task, with no transaction. A crash part-way through leaves only some tasks scheduled.
- **Responses that arrive out of order.** `loadTasksForDate` awaits two queries one after the other, then writes state. If the user switches day A → B, a slow response for A can land after B's and show A's tasks under date B.
- **Serial refresh.** `refreshAll` runs the date, overdue and unscheduled queries one after another after every command.
- **Errors are swallowed.** Mutations started with `unawaited(...)` in `home_planner_pane.dart`, `task_form_submit_handler.dart`, `context_menu_helpers.dart`, `task_hierarchy_item.dart` and `backlog_dialog_handlers.dart` have no error handling. There is no `FlutterError.onError` or `PlatformDispatcher.onError` either, so a failed write disappears without a trace.

## Scope / Non-goals

In scope:

- The order and concurrency of `TaskNotifier` loading.
- How `autoScheduleDeadlines` runs.
- Making errors from unawaited mutations visible.

Non-goals:

- Patching state per command. Keep the full reload: it's local SQLite, and a second source of truth next to undo/redo costs more than it saves.
- `unawaited(showDialog(...))`. Dialogs that are opened without awaiting them are fine.
- Re-running auto-schedule at midnight. Today it runs only on startup; that's a separate feature if anyone wants it.

## Design

**Auto-schedule runs before the first load, inside one transaction.**

- `build()` returns the initial state with `isLoading: true` and starts a single `_init()`. `_init()` awaits `autoScheduleDeadlines`, then `refreshAll()`.
- `main.dart` no longer loads tasks itself. Its eager `loadTasksForDate` and `loadUnscheduledTasks` calls would race `_init()` and bring back the stale load. The screen shows `isLoading` until `_init()` finishes.
- `autoScheduleDeadlines` gathers its updates and writes them through one repository batch call.
  - Rejected: going through undo. A user shouldn't be able to undo a system action they never took.
  - Rejected: making `build()` an `AsyncNotifier`. It would change the type of every `taskProvider` consumer for one startup step.

**Parallel loads with a last-write-wins guard.**

- `loadTasksForDate` runs `getByDate` and `getOverdue` with `Future.wait`.
- When the queries return, it drops the result if `state.currentDate` no longer equals the date it requested.
- `refreshAll` runs the date load and the unscheduled load with `Future.wait`. They write different state fields, so they can't clobber each other.
- Rejected: a generation counter. The date check is enough, because the date is the only argument that changes.
- Silent loads (`silent: true`, used by `refreshAll`) leave `isLoading` as they found it. Only a non-silent load or the end of `_init()` clears it, so a refresh that runs during startup can't end the loading state before auto-schedule has finished.
- `_init()` and both loads check `ref.mounted` after each `await`, so a notifier that was disposed mid-load (for example when a test tears down its container) never writes state.

**One global error sink instead of a `try/catch` at each call site.**

- `main.dart` sets `FlutterError.onError` and `PlatformDispatcher.instance.onError`. Each one logs the error and shows a new `ToastUtils.showError`, built the same way as the existing `showWarning`.
- Unawaited futures end up there with no change at the call sites.
- `showError` keeps the `ToastificationItem` it last showed and dismisses it before showing a new one. `toastification.showCustom` takes no id, so a fixed toast id isn't an option.
- Rejected: wrapping each `unawaited` in a `try/catch`. That's 7 call sites today, and every future one would need the same.

## Risks

- **A toast storm.** A repeating failure, such as a locked database, raises a toast for every action.
- **The guard drops a valid result.** It could discard a result the screen needed, for example a same-date refresh racing a mutation. A dropped result also leaves `isLoading` as it was; the newer load that caused the drop clears it.
- **The batch write fails part-way.** The transaction must roll back the whole batch.
- **Startup flicker.** Tests or screens that assume `isLoading` starts `false` break, or the screen flickers on startup.

## Verification

- Stale first load: a provider test with a backlog task whose deadline is today asserts that `taskProvider.tasks` contains it once `_init` completes, without any further mutation.
- Out-of-order responses: a provider test with a mock repository that delays `getByDate(A)` past `getByDate(B)` asserts that the state shows B's tasks.
- Partial batch: a repository test makes the second update in `updateAll` throw and asserts that the first one rolled back.
- Swallowed errors: a widget test makes `updateTask` throw from an unawaited call and asserts that a toast appears. The call starts in `Zone.root`, because the zone of `testWidgets` would otherwise catch the error before it reaches `PlatformDispatcher.onError`. That makes the error take the same route as a real engine event, with no forwarding in the test. An `integration_test` wouldn't help: it runs in the same test zone.
- Toast storm: `showError` dismisses the previous error toast before showing the next, so repeated errors replace each other instead of stacking. A widget test shows two errors in a row and asserts that only one toast remains.
- Startup flicker: covered by the existing `task_provider_test`, after updating its expectation for the initial `isLoading`.
