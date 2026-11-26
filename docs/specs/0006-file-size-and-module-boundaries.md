# 0006: File size and module boundaries

Status: approved

## Why

- 8 files in `lib` broke the 300-line limit in `CLAUDE.md`. `shortcut_intents.dart` (414) and `app_shortcuts.dart` (324) are left to [0007](0007-shortcut-definitions.md), which replaces how shortcuts are defined:

  | File | Lines |
  | --- | --- |
  | `project_detail_screen.dart` | 486 |
  | `task_repository.dart` | 426 |
  | `shortcut_intents.dart` | 414 |
  | `backlog_screen.dart` | 386 |
  | `task_form_panel.dart` | 374 |
  | `app_shortcuts.dart` | 324 |
  | `settings_components.dart` | 321 |
  | `range_date_picker.dart` | 319 |

- Another 12 files sit between 270 and 300 lines, and `task_provider.dart` and `task_reorder_engine.dart` sit at exactly 300. Several of them are large because they carry a second responsibility or duplicate logic that lives elsewhere, not because their one job is big.
- `lib/core/utils` holds feature logic: `task_hierarchy_utils`, `task_selection_utils`, `task_sort_utils`, `project_reorder_utils` and `history_stats_utils`. 13 files import them. `core` should hold only what more than one feature uses.

## Scope / Non-goals

In scope:

- Bring every file in `lib` to 300 lines or fewer, with room to spare where the split is natural.
- Split the files in the 270–300 band that have more than one responsibility or duplicate logic, listed in Design.
- Move the feature-specific utils out of `core/utils` into their features.

Non-goals:

- Rewriting logic. Splits move code verbatim.
- Generated files and `test/**`, which `CLAUDE.md` already exempts.
- A lint or CI check for line counts. That could be added later through dotactions.
- `flutter_ext/range_date_picker.dart` if [0003](0003-dotmaterial-package.md) lands first: the split then happens inside the package, under the same rule.

## Design

**Split along responsibility, not at line 300.** Each new file has one job its name can state. A split that only exists to get under the limit is rejected in review.

| File | Split |
| --- | --- |
| `project_detail_screen.dart` | The `build` body goes into a header widget and a body widget under `widgets/project_detail/`. Focus and search wiring stay in the state class. |
| `backlog_screen.dart` | `build` (lines 131–368) and `_buildHeaderActions` go into `widgets/backlog/` widgets. Same pattern as the project detail screen. |
| `task_form_panel.dart` | `_CoordinatedMenuController` goes to its own file. The form body sections go into `form/sections/`, which already exists. |
| `task_repository.dart` | `_getOrderBy` becomes a pure top-level `taskOrderBy` in `task_order_sql.dart`, relation loading goes into `task_relations_loader.dart`, and the reference checks and label/tag writes that `insert` and `_update` duplicated become one `task_relations_writer.dart`. |
| `shortcut_intents.dart`, `app_shortcuts.dart` | Out of scope. 0007 replaces how shortcuts are defined, so splitting them first would be rewritten. |
| `settings_components.dart` | One file per tile type group: section and base tiles in one, input tiles (switch, dropdown, slider) in another. |
| `range_date_picker.dart` | `_CalendarDay` and the header move to private files under a `range_date_picker/` folder. |

- Rejected: `part`/`part of` files. They hide the size, not the coupling.

**New widgets follow one naming standard.** Splitting screens adds widgets, and names had already drifted: "header" and "toolbar" meant different things on different screens, two features each had a `PlanningSection`, and history kept widgets under `screens/`. `GUIDELINES.md` §2.2.1 now defines each widget suffix (Screen, Tab, Header, Toolbar, Bar, Row, Section, Panel, Pane, Card, Tile, Item, Dialog), the file-name rule and the folder rule. Step 2 renames what breaks it:

| Before | After |
| --- | --- |
| `ProjectDetailToolbar` contained the header | `ProjectDetailHeader` owns its own actions, and `ProjectDetailToolbar` holds only search and filter |
| `TaskChipsBar` (`task_chips_bar.dart`) | `TaskChipsRow` (`task_chips_row.dart`) |
| form `PlanningSection` (`planning_section.dart`) | `SchedulingSection` (`scheduling_section.dart`) |
| form `CategorizationSection` in `labels_and_tags_section.dart` | `categorization_section.dart` |
| settings `LabelsSection` | `LabelsAndTagsSection` |
| `ProjectColorPicker` in `color_picker.dart` | `project_color_picker.dart` |
| `ItemSizeTransitionBuilder` in `kanban_transition_builder.dart` | `item_size_transition_builder.dart` |
| `history/presentation/screens/widgets/` | `history/presentation/widgets/` |
| `TabHistoryDashboard`, `TabHistoryList`, `TabHistoryInsights` in `screens/` | `HistoryDashboardTab`, `HistoryListTab`, `HistoryInsightsTab` in `widgets/tabs/` |
| `filter_dialog.dart`, `mode_selection_dialog.dart`, `save_mode_dialog.dart` in `filter/presentation/widgets/` | the same files in `filter/presentation/widgets/dialogs/` |
| five private `_showFilterDialog` copies (home, backlog, projects, project detail, history) | one `showFilterDialog(context, ref, {showProjectFilter, showTagFilter})` next to `FilterDialog` |

- `ProjectDetailHeader` keeps its own layout rather than `ScreenHeader`, on purpose. The guideline names it as the exception.
- Rejected: a shared `ScreenLayout` widget with header, toolbar, body and bulk-bar slots. Revisit it when the Today view gets the bulk bar, which makes three screens with the same layout.

**Files in the 270–300 band: split only where a file has more than one responsibility or duplicates logic.**

| File | Finding | Action |
| --- | --- | --- |
| `task_provider.dart` (300) | It does loading, CRUD, reorder, status and completion, and the parent-completion prompt. The other action groups already live in `actions/` mixins. | Move `updateTaskStatus` through `completeParentOnly` into a `task_completion_actions.dart` mixin, the same pattern as `task_bulk_actions`. |
| `history_screen.dart` (272) | The widget state owns pagination (`_offset`, `_hasMore`, `_completedTasks`), and `_loadData` and `_loadMoreData` each build the same start/end-of-day range. | Add a manual `historyListProvider` `Notifier` that owns paging and the date range. The screen only renders. |
| `searchable_dropdown.dart` (274), `multi_select_searchable_dropdown.dart` (299), `tag_autocomplete_text_field.dart` (293) | Three copies of the arrow-key selection and scroll-to-index code, with hard-coded item heights of 40, 44 and 36. | Write one `ensureIndexVisible(ScrollController, int index, double itemExtent)` and one keyboard-selection helper in `flutter_ext/searchable_dropdown/`, and use them in all three. The `tag_autocomplete` scroll keeps its "scroll only when out of view" behaviour, which becomes the shared behaviour. |
| `project_grid.dart` (293) | `moveFocus` (about 70 lines) is a geometric nearest-neighbour search living inside widget state, and it has no tests. | Extract a pure `pickNeighbour(Offset from, Map<String, Offset> candidates, int dx, int dy)` into `core/utils/focus_utils.dart`. The widget only collects the item centres. |
| `parent_group_header.dart` (292) | It resolves labels and tags (task labels plus project labels) with the same code as `task_chips_bar.dart`. | Extract that resolution into one shared function used by both, or render `TaskChipsBar` inside the header if the layouts match. |
| `kanban_column.dart` (290) | The widget calls domain reorder helpers directly. | Covered by 0004, which changes those calls. No separate split. |
| `task_reorder_engine.dart` (300) | Pure and cohesive: one job, slot and rank resolution. | Keep. 0004 removes the wrappers that call it, not its own code. |
| `group_tasks_dialog.dart`, `project_form_panel.dart`, `shortcuts_help_overlay.dart` | View code plus form validation, delegating to notifiers. | Keep. |

**Feature utils move out of `core`:**

- The `task_*_utils` files and `deadline_urgency.dart` go to `features/tasks/domain/`.
- `project_reorder_utils` goes to `features/projects/domain/`.
- `history_stats_utils` goes to `features/history/domain/`.
- `core/utils` keeps the generic helpers: date/time, color, focus, key-value map, midnight timer and search navigation.

## Risks

- **Moves lose behaviour.** Code moved between files can drop a `context.mounted` check, change focus or listener ownership, or change rebuild boundaries when a `build` body becomes its own widget.
- **Import churn.** Moving the utils and intents leaves broken or circular imports.
- **Coverage shifts.** Moved code changes which test file covers it, which matters for 0002's coverage scopes.

## Plan

Run this after 0004 and 0005, because both change sizes in `tasks`. Use one PR per row group so diffs stay reviewable:

1. Data and logic: `task_repository.dart` and the `core/utils` moves.
2. Screens: `project_detail_screen.dart`, `backlog_screen.dart` and `task_form_panel.dart`, the naming standard in `GUIDELINES.md` §2.2.1, and the renames listed under Design.
3. Components: `settings_components.dart` and `range_date_picker.dart`, unless 0003 has already moved the picker.
4. Shared helpers in the 270–300 band: the dropdown and autocomplete keyboard/scroll helper, `pickNeighbour`, and the label/tag resolution.
5. Ownership: `task_completion_actions.dart` and `historyListProvider`.

Move the matching tests under `test/` to mirror the new paths.

## Verification

- Line limit: `find lib -name '*.dart' ! -name '*.freezed.dart' -exec wc -l {} + | awk '$1>300 && $2!="total"'` prints nothing.
- Behaviour: existing widget and provider tests pass unchanged apart from import paths. Manual pass on the project detail, backlog and task form screens: keyboard focus, search and drag-reorder.
- Imports: `flutter analyze` is clean, and `grep -rn "core/utils/task_" lib test` returns nothing.
- New tests: `task_order_sql.dart` gets a unit test that pins the `ORDER BY` output for the plan, deadline and overdue combinations.
- `pickNeighbour`: unit tests for each direction, for no candidate in that direction, and for the bias against off-axis neighbours.
- `ensureIndexVisible`: widget tests for an item above the viewport, below it, and already visible, which means no scroll. The existing dropdown and autocomplete tests pass unchanged.
- `historyListProvider`: provider tests for the first page, `loadMore` appending, `hasMore` turning false on a short page, and a date-range change resetting the offset.
- Label/tag resolution: covered by the existing `task_chips_bar` and parent header tests, plus one unit test for merging project and task labels without duplicates.
- Coverage: compare the 0002 coverage scopes before and after each PR.
- Naming: every file under `presentation/widgets` and `presentation/screens` contains a class named after the file, apart from these known exceptions: `chip/chip.dart` and `task_list/task_list_components.dart` (several small classes), `settings/.../section.dart` (its main type is the `Section` enum), `import_from_md_dialog.dart` (`MD` acronym) and `settings_components.dart` (split in step 3). Also, `grep -rhoE "^class [A-Z]\w*" lib/features/*/presentation/widgets | sort | uniq -d` prints nothing.
