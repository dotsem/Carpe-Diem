# 0002 plan

There's one PR per step. Each step ends with `dart format .`, `flutter analyze`, `flutter test --coverage` and the scope check from the spec's Verification section. Missed-line counts come from run `b4aec49`.

## 1. Groundwork

- Delete `lib/core/utils/task_reorder_utils.dart`, `lib/core/theme/responsive_provider.dart` and `lib/features/common/data/database/migration_runner.dart`.
- Exclusion probe: add `// coverage:ignore-file` to `lib/core/theme/app_theme.dart`, plus one `ignore-line` and one `ignore-start`/`ignore-end` block in `lib/core/utils/focus_utils.dart` (on the `Platform.*` branches). Check that the excluded lines are gone from `lcov.info`.

## 2. Routes (32)

- `lib/routes/app_router.dart`: extract `parseSettingsSection(Uri, Object?)`.
- `test/routes/app_router_test.dart`: unit tests for `parseSettingsSection`, plus the `findMatch` route-table test.

## 3. Domain + data (29 + 225)

- `features/history/data/repositories/history_repository.dart` (41): `_applyFilterToWhereClause`, with every filter field and the include/exclude combinations; `getCompletedInRange`; `getHistoryOverview`.
- `features/history/data/repositories/history_insights_repository.dart` (57, 0%).
- `features/tasks/data/repositories/task_repository.dart` (53): `update`; the null-out branches in `insert` for a missing project or blocker; `getByProject`, `getByProjectUnscheduled` and `getByLabel`.
- `features/tags/data/repositories/tag_repository.dart` (16, 0%).
- `features/tasks/domain/reorder/task_reorder_utils.dart` (13): `moveToTop`, `moveToBottom` and `_moveToEdge`.
- Remaining small gaps in `domain/` and `data/`. Add `features/common/data/database/constants/db_constants.dart` to `lcov.info`, or exclude it if it holds only constants.

## 4. Providers (353)

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

## 5. Core (184)

- `reorder/lexorank.dart` (21): the multi-character keys from `_encodeInteger` (`b`/`c`/`Y`/`X`) and the edges of `generateBetween`. Add a property-style check that thousands of consecutive keys stay strictly ordered.
- `toast/cheesy_toast.dart` (22), `toast/toast_utils.dart` (17, 0%)
- `utils/focus_utils.dart` (27, 0%), after the step 1 exclusions
- `utils/task_selection_utils.dart` (13)
- `undo_redo/undo_redo_provider.dart` (10)
- `theme/app_breakpoints.dart` (9)
- remaining small gaps in `utils/`

## 6. Shared widgets (307)

All under `lib/features/common/presentation/widgets/`:

- `bulk_planning_bar.dart` (73), `swinging_drag_proxy.dart` (43), `bulk_action_menu.dart` (35)
- `chip/chip.dart` (40), plus `label_chip`, `manageable_chip` and `tag_chip` (63 together, all at 0%)
- `dialogs/custom_date_picker_dialog.dart` (17), `dialogs/warning_dialog.dart` (11)
- `context_menu_item_tile.dart` (11), `date_picker_button.dart` (8), `screen_header.dart` (4), `color_picker.dart` and `urgency_selector.dart` (1 each)

## 7. flutter_ext (351)

Tests import only `flutter_ext` and Flutter, never app code, so they can move unchanged in 0003.

- `range_date_picker.dart` (143, 0%), `dialogs/pick_date_range_dialog.dart` (60, 0%)
- `searchable_dropdown/multi_select_searchable_dropdown.dart` (54), `searchable_dropdown/searchable_dropdown.dart` (50)
- `horizontal_tab.dart` (24), `platform_draggable.dart` (11)
- remaining files with 1–3 lines missed each
