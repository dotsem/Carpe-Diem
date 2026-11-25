# 0002: Full, useful coverage for the non-screen layers

Status: done (#153)

## Why

- CI reports 53.17% project coverage (run on `b4aec49`), and the one number hides where the gaps are. Domain is at 94.8%; screens are at 9.4%.
- Some data-shaping logic has no tests at all: `HistoryRepository._applyFilterToWhereClause` (builds SQL with a duplicated argument list for label filters), `HistoryInsightsRepository` (0%), the null-out branches in `TaskRepository.insert`, and the multi-character keys in `LexoRank._encodeInteger`. A bug in any of these silently corrupts history, filters or task order.
- `flutter_ext` is meant to be reused in other apps (see [0003](0003-dotmaterial-package.md)), so it needs to stand on its own tests.

## Scope / Non-goals

In scope: 100% line coverage, after exclusions, for:

| Scope | Path match | Now | Missed |
|---|---|---|---|
| domain | `lib/features/*/domain/**` | 94.8% | 29 |
| data | `lib/features/*/data/**` | 75.1% | 225 |
| providers | `lib/features/*/presentation/providers/**` | 71.1% | 353 |
| core | `lib/core/**` | 78.1% | 184 |
| shared widgets | `lib/features/common/presentation/widgets/**` | 45.8% | 307 |
| flutter_ext | `lib/flutter_ext/**` | 53.4% | 351 |
| routes | `lib/routes/**` | 3.0% | 32 |

Non-goals:

- Screens, shell, shortcuts and feature-specific `widgets/` folders.
- CI enforcement: no thresholds and no per-scope statuses yet. coverage-action stays informational.
- `coverage.yml` or source-file `ignore` support in coverage-action. The developer will open a PR upstream; once it lands, the inline exclusions may move there.
- An `errorBuilder` on the router. There are no deep links, and a deleted project already renders "Project not found", so the only way to reach an unknown path is a typo in our own code, and the route test catches that.
- Extracting `flutter_ext` into a package (0003).

## Design

**Only useful tests.** A test must fail when real behaviour breaks. A "pumps without throwing" smoke test does not count, and neither does a test that re-checks Riverpod, freezed or Flutter itself. If the only possible test for a line is ceremonial, exclude the line instead of writing the test.

**Exclusions use `// coverage:ignore-*` comments**, which `flutter test --coverage` already applies while it writes `lcov.info` (the `*.freezed.dart` files prove it for `ignore-file`):

- Whole file (option C): `// coverage:ignore-file` as the file's first comment. It's used for files that are pure configuration, for example `core/theme/app_theme.dart`.
- Lines or blocks (option A): `// coverage:ignore-line` or `// coverage:ignore-start` … `// coverage:ignore-end`, each with a short `// why:` reason. They're for defensive branches that can't happen, and platform-only code (for example the `Platform.isIOS || Platform.isAndroid` branch in `flutter_ext/platform_draggable.dart`). All three forms (`ignore-file`, `ignore-line`, `ignore-start`/`ignore-end`) are confirmed to be applied by `flutter test --coverage`.
- Each exclusion is reviewed in its PR. As a rule of thumb, if a file is more than ~20% excluded, either it needs refactoring or the whole file should be excluded.
- A whole file is excluded only when it is declarative (theme, constants, navigator keys). Logic that is merely awkward to test, such as pointer velocity or ticker timing, gets a test, not an exclusion: drive the ticker with `tester.pump(duration)` and, where the code reads `DateTime.now()`, use `tester.runAsync` with a short real delay. `SwingingDragProxy` was excluded whole at first and is now tested.
- `// coverage:ignore-line` must sit on the line it excludes. For a multi-line expression use `ignore-start`/`ignore-end` around it.
- Rejected: path lists in dotactions' awk step (that couples the app's exclusions to a shared workflow) and `coverage.yml` (coverage-action doesn't support it yet).

**Exclusions in place** (keep this list in sync; every entry also carries a `// why:` comment in the code):

| Form | File | Reason |
|---|---|---|
| file | `core/theme/app_theme.dart` | declarative theme, no logic |
| file | `features/common/data/database/constants/db_constants.dart` | schema version constants only |
| file | `routes/keys.dart` | global navigator keys only |
| block | `routes/app_router.dart` (`appRouter`) | `findMatch` never runs the `pageBuilder` closures; accepted exception to the ~20% rule (about 64% of the file) because the only logic is extracted into `parseSettingsSection` |
| block | `flutter_ext/platform_draggable.dart` | mobile-only `LongPressDraggable` branch cannot run on desktop CI |
| block | `core/toast/toast_utils.dart` (`builder`) | toastification does not mount custom builders in widget tests; `CheesyToast` is tested directly |
| block | `features/common/data/database/database_helper.dart` | `getApplicationDocumentsDirectory` needs a platform host; tests pass an explicit path |
| block | `features/tasks/domain/reorder/task_reorder_engine.dart` | loop over nested descendants of the last subtask; hierarchies are two levels deep (`reparentTasks` rejects nested parents) |
| line | `core/utils/task_hierarchy_utils.dart` | `emit` only receives ids taken from `taskMap` or `childrenOf` |
**Dead code is deleted, not tested.** Nothing imports these files:

- `lib/core/utils/task_reorder_utils.dart`, a stale 175-line copy of `features/tasks/domain/reorder/task_reorder_utils.dart`
- `lib/core/theme/responsive_provider.dart`, whose `screenBreakpointProvider` is unused
- `lib/features/common/data/database/migration_runner.dart`, which holds only a `// TODO` stub
- the default `repositoryName` body in `IFilterModeRepository` (`features/common/data/repositories/interfaces.dart`): `FilterModeRepository` overrides it and its mock only `implements` the interface, so the body never ran

**Routes get two kinds of test:**

1. Extract the `?section=` and `extra` parsing out of the `/settings` `pageBuilder` into a pure function and unit-test it, including the `filtering`/`modes` aliases, unknown names, and `extra` precedence:

   ```dart
   Section? parseSettingsSection(Uri uri, Object? extra);
   ```

2. A route-table test that uses `appRouter.configuration.findMatch(uri)` and covers every path the app navigates to (`/`, `/projects`, `/projects/<id>`, `/tasks`, `/history`, `/settings`, `/settings?section=filteringAndModes`). It asserts that each path is not `isError` and that it matches the expected route pattern. No screens get built, so no repository mocks are needed. An unknown path should come back as `isError`.
   - Rejected: pumping `MaterialApp.router(routerConfig: appRouter)`. Every screen would need every repository overridden, which makes the tests slow and brittle for little extra value.
   - `findMatch` never runs the `pageBuilder` closures, so the `appRouter` declaration is wrapped in `ignore-start`/`ignore-end` and counts as excluded, not covered. The route-table test guards the paths; `parseSettingsSection` carries the only logic.

**Test layout** mirrors `lib/` under `test/`, following the existing patterns: mocktail mocks from `test/helpers/mock_repositories.dart`, and `sqflite_common_ffi` in-memory databases for repositories. Test files are exempt from the 300-line limit. One test file per subject (`<lib file>_test.dart`); never name a file after the goal (`*_coverage_test.dart`), and name each test after the behaviour it checks, not the branch it reaches. Shared test notifiers live in `test/helpers/widget_test_notifiers.dart`.

## Risks

- **The route-table test misses a path added later**, because the list of paths is maintained by hand.
- **`appRouter` is a global singleton.** That doesn't matter for `findMatch`, which is read-only, but it would leak state if someone later adds navigation tests.
- **Chasing 100% invites ceremonial tests.** The usefulness rule above is the guard.
- **Tests that are timing- or platform-dependent** (drag, hardware keys, `Platform.*`) could be flaky on the CI runners.

## Plan

There's one PR per step. Each step ends with `dart format .`, `flutter analyze`, `flutter test --coverage` and the scope check from the spec's Verification section. Missed-line counts come from run `b4aec49`.

### 1. Groundwork

- Delete `lib/core/utils/task_reorder_utils.dart`, `lib/core/theme/responsive_provider.dart` and `lib/features/common/data/database/migration_runner.dart`.
- Exclusion probe: add `// coverage:ignore-file` to `lib/core/theme/app_theme.dart`, one `ignore-line` in `lib/core/utils/task_hierarchy_utils.dart` and one `ignore-start`/`ignore-end` block in `lib/features/common/data/database/database_helper.dart` (the `getApplicationDocumentsDirectory` branch). Check that the excluded lines are gone from `lcov.info`.

### 2. Routes (32)

- `lib/routes/app_router.dart`: extract `parseSettingsSection(Uri, Object?)`.
- `test/routes/app_router_test.dart`: unit tests for `parseSettingsSection`, plus the `findMatch` route-table test.

### 3. Domain + data (29 + 225)

- `features/history/data/repositories/history_repository.dart` (41): `_applyFilterToWhereClause`, with every filter field and the include/exclude combinations; `getCompletedInRange`; `getHistoryOverview`.
- `features/history/data/repositories/history_insights_repository.dart` (57, 0%).
- `features/tasks/data/repositories/task_repository.dart` (53): `update`; the null-out branches in `insert` for a missing project or blocker; `getByProject`, `getByProjectUnscheduled` and `getByLabel`.
- `features/tags/data/repositories/tag_repository.dart` (16, 0%).
- `features/tasks/domain/reorder/task_reorder_utils.dart` (13): `moveToTop`, `moveToBottom` and `_moveToEdge`.
- Remaining small gaps in `domain/` and `data/`. Add `features/common/data/database/constants/db_constants.dart` to `lcov.info`, or exclude it if it holds only constants.

### 4. Providers (353)

Largest gaps first:

- `settings/presentation/providers/settings_provider.dart` (54)
- `filter/presentation/providers/filter_provider.dart` (41)
- `common/presentation/providers/window_title_provider.dart` (40)
- `projects/presentation/providers/project_provider.dart` (35)
- `labels/presentation/providers/label_provider.dart` (29)
- `history/presentation/providers/history_insights_provider.dart` (27, 0%)
- `tasks/presentation/providers/task_history_provider.dart` (21, 0%)
- `history/presentation/providers/activity_provider.dart` (20, 0%)
- `common/presentation/providers/repository_providers.dart` (17)
- `filter/presentation/providers/filter_accordion_provider.dart` (10, 0%)
- the remaining providers with fewer than 10 lines missed each

If this PR grows past roughly 1500 lines of tests, split it by feature.

### 5. Core (184)

- `reorder/lexorank.dart` (21): the multi-character keys from `_encodeInteger` (`b`/`c`/`Y`/`X`) and the edges of `generateBetween`. Add a property-style check that thousands of consecutive keys stay strictly ordered.
- `toast/cheesy_toast.dart` (22), `toast/toast_utils.dart` (17, 0%)
- `utils/focus_utils.dart` (27, 0%)
- `utils/task_selection_utils.dart` (13)
- `undo_redo/undo_redo_provider.dart` (10)
- `theme/app_breakpoints.dart` (9)
- remaining small gaps in `utils/`

### 6. Shared widgets (307)

All under `lib/features/common/presentation/widgets/`:

- `bulk_planning_bar.dart` (73), `swinging_drag_proxy.dart` (43), `bulk_action_menu.dart` (35)
- `chip/chip.dart` (40), plus `label_chip`, `manageable_chip` and `tag_chip` (63 together, all at 0%)
- `dialogs/custom_date_picker_dialog.dart` (17), `dialogs/warning_dialog.dart` (11)
- `context_menu_item_tile.dart` (11), `date_picker_button.dart` (8), `screen_header.dart` (4), `color_picker.dart` and `urgency_selector.dart` (1 each)

### 7. flutter_ext (351)

Tests import only `flutter_ext` and Flutter, never app code, so they can move unchanged in 0003.

- `range_date_picker.dart` (143, 0%), `dialogs/pick_date_range_dialog.dart` (60, 0%)
- `searchable_dropdown/multi_select_searchable_dropdown.dart` (54), `searchable_dropdown/searchable_dropdown.dart` (50)
- `horizontal_tab.dart` (24), `platform_draggable.dart` (11)
- remaining files with 1–3 lines missed each

## Verification

- **Exclusion comments:** the first PR adds a single `ignore-line` and a single `ignore-start`/`ignore-end` block. Then check that the excluded lines are missing from `coverage/lcov.info`. If they aren't excluded, stop and revisit option C only, before writing any more exclusions.
- **Route list drift:** the plan includes a one-off grep of `context.go(` and `context.push(` to build the list of paths. When adding a route, add a test for it (noted in the test file's header doc).
- **Scope coverage:** after each PR, measure every scope from a fresh `flutter test --coverage`:

  ```sh
  awk -F: '/^SF:/{f=$2} /^LF:/{lf=$2} /^LH:/{if(f~ENVIRON["S"] && lf>$2) print lf-$2, f}' coverage/lcov.info
  ```

  Run it with `S='/domain/|/data/|/providers/|^lib/(core|flutter_ext|routes)/|common/presentation/widgets/'`. Empty output means the scopes are at 100%. Also confirm that every in-scope file appears in `lcov.info` (a file with no tests that import it doesn't show up at all).
- **Ceremonial tests:** review each PR against the usefulness rule.
- **Flaky tests:** before merging, run `flutter test` three times on CI. Platform branches are excluded instead of being faked.

## Assumptions

- The CI artifact's `.g`/`.freezed` awk filter stays as it is. It's redundant with `ignore-file`, but it's harmless.
- Uncovered lines that turn out to be real bugs get fixed in the same PR as their test, and the PR description says so.
