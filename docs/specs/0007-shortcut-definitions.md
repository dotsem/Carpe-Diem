# 0007: One standard way to define shortcuts

Status: draft

## Why

- **One shortcut touches four places that agree by hand.**
  - The key constant is in `shortcut_keys.dart`.
  - The intent class is in `shortcut_intents.dart`.
  - The binding and handler sit in a per-screen wrapper.
  - The help row is a `ShortcutEntry` in `global_shortcut_entries.dart` or `view_shortcut_entries.dart`.

  Nothing ties the help row to the binding. `'Ctrl + P'` is a string literal in the dialog entries and a `LogicalKeyboardKey` check elsewhere, so the overlay can show keys that no longer work.
- **Six ways to wire a shortcut.**
  - The global `Shortcuts` + `Actions` map in `app_shortcuts.dart`.
  - `BaseScreenShortcuts`, with 8 optional `onX` hooks.
  - Four per-screen wrappers (`HomeShortcuts`, `BacklogShortcuts`, `ProjectsShortcuts`, `ProjectDetailShortcuts`) that each rebuild near-identical maps.
  - `TaskListKeyboardShortcuts` in `task_list_components.dart`.
  - The raw `HardwareShortcuts` key handlers in `task_form_shortcuts.dart` and `project_form_shortcuts.dart`.
  - One `CallbackShortcuts` for Escape in `right_sidebar_container.dart`.
- **Duplicate intents.** `backlog_shortcuts.dart` redeclares `FocusSearchIntent`, `UnfocusSearchIntent` and `NewTaskIntent`, which already exist in `shortcut_intents.dart`, and the local ones shadow the shared ones.
- **`common` owns feature knowledge.** `shortcut_intents.dart` holds `PlanTaskIntent` and `ToggleLayoutIntent`. `view_shortcut_entries.dart` holds the home, backlog and project help text. `common` should hold the mechanism and the global shortcuts only.
- **Inconsistent modifier.** The plan-task shortcuts bind `control: true` only. The global map binds both Ctrl+K and Cmd+K on every platform. The forms use `isControlOrMetaPressed()`. Nothing says which platform gets which.

## Scope / Non-goals

In scope:

- One `AppShortcut` type and one `ShortcutScope` widget that builds `Shortcuts`, `Actions` and the help rows from the same list.
- Ownership by layer: `common` holds the mechanism, the global shortcuts and the intents used by two or more features. Each feature declares its own shortcuts, handlers and help labels.
- A `primary` modifier that resolves per platform.
- Moving the form dialogs and the right-sidebar Escape onto the same type.
- A test that fails on duplicate activators.

Non-goals:

- Changing any key. After this spec every shortcut has the same key as before. The exception is the modifier on macOS (Design, "Modifier").
- User-configurable bindings or a shortcut settings screen.
- Splitting `shortcut_intents.dart` and `app_shortcuts.dart` for size. That was dropped from [0006](0006-file-size-and-module-boundaries.md) because this spec rewrites both.
- Merging feature intents (`PrevDayIntent` into `MoveLeftIntent`). With features owning their intents, the names can stay meaningful.

## Design

**Where things live**

| Layer | Holds |
| --- | --- |
| `common/presentation/shortcuts/` | `AppShortcut`, `Bind`, `ShortcutScope`, the key constants, the global shortcuts (navigation, help, undo/redo, command palette, mode switch), and the shared list-navigation intents (`MoveNext`, `MovePrev`, `MoveLeft`, `MoveRight`, `Filter`, `FocusSearch`, `UnfocusSearch`, `NewItem`). |
| `features/<f>/presentation/shortcuts/` | That feature's `AppShortcut` constants, its intents, and the `ShortcutScope` usage with handlers and labels. `PlanTaskIntent`, `ToggleLayoutIntent`, the task-form and project-form shortcuts move here. |

**The type**

```dart
// a shortcut is a set of activators that all produce one intent type
class AppShortcut<T extends Intent> {
  const AppShortcut(this.activators, {required this.display});
  final Map<ShortcutActivator, T> activators; // 'Ctrl+1..4' is four entries
  final String display;                       // the key text shown in help
}

class Bind<T extends Intent> {
  const Bind(this.shortcut, this.onInvoke, {required this.label, this.category,
      this.allowWhileTyping = false});
  final AppShortcut<T> shortcut;
  final void Function(T intent) onInvoke;
  final String label;
  final String? category;
  final bool allowWhileTyping;
}
```

`ShortcutScope(binds: [...], child: ...)` does three things from the one list:

1. Builds `Shortcuts` from the activators.
2. Builds `Actions`. A bind is wrapped in `NonTypingAction` unless `allowWhileTyping` is true.
3. Registers the help rows through the existing `AppShortcutRegistrar`, from `shortcut.display` + `label` + `category`.

A screen then writes one place per shortcut:

```dart
ShortcutScope(
  binds: [
    Bind(taskShortcuts.planToday, (_) => onPlanToday(), label: 'Plan for today'),
    Bind(listNav.moveNext, (_) => onMoveNext(), label: 'Focus next'),
  ],
  child: child,
)
```

**Precedence.** Scopes are plain nested `Shortcuts` widgets, so the nearest scope wins: form dialog, then screen, then global. The task form's Ctrl+P (project menu) beats the global Ctrl+P (command palette) because the form scope is the nearer ancestor. Today it works because a raw key handler runs before the focus tree.

**Modifier.** `AppShortcut.primary(LogicalKeyboardKey key, {bool shift = false})` builds `control: true` on Linux and Windows and `meta: true` on macOS. It reads `defaultTargetPlatform`, so tests can set `debugDefaultTargetPlatformOverride`. The `display` text follows the platform ("Ctrl" or "Cmd"). One modifier per platform replaces the global map's habit of binding both Ctrl+K and Cmd+K everywhere. Behaviour change: Linux and Windows lose the Meta/Super variant. macOS gains Cmd on the plan-task shortcuts.

**Typing in text fields.** `allowWhileTyping: true` is for shortcuts that must fire while a text field has focus: Ctrl+Enter, Ctrl+1..4 and the form menu toggles. Single-letter shortcuts stay disabled while typing, as `NonTypingAction` does today.

**Duplicate check.** A test imports the global list and each feature's list, builds the activator set per scope, and fails when:

- A key appears twice in one scope.
- A screen scope reuses a global key without being listed as an intentional override.

**Deleted by this spec:** `BaseScreenShortcuts`, `HomeShortcuts`, `BacklogShortcuts`, `ProjectsShortcuts`, `ProjectDetailShortcuts`, `TaskListKeyboardShortcuts`, `ShortcutEntry` and the two entry-list files, and the duplicate intents in `backlog_shortcuts.dart`.

## Risks

- **Open menus.** The form wrappers use a raw `HardwareShortcuts` handler, probably so Ctrl+P can close a project menu while focus is inside the menu overlay. That overlay is not a descendant of the form's `Shortcuts` widget. If `ShortcutScope` cannot reach it, the forms keep `HardwareShortcuts` and only their help rows move. Unverified: spike it first (Plan, step 5).
- **Behaviour drift.** Every screen is rewired. A missed binding is silent, so every migration step needs key-press tests first (Verification).
- **Typing guard.** Wrapping the wrong binds in `allowWhileTyping` makes letters fire inside text fields, or makes Ctrl+Enter stop working there.
- **Platform change.** Linux and Windows lose the Meta variants. Check that nobody relies on Cmd+K there (single user, so low risk).

## Plan

Run after [0006](0006-file-size-and-module-boundaries.md) steps 2–5 so the screen splits don't collide with the rewiring. One PR per step.

1. **Characterization tests, then the mechanism.** First, key-press tests for the current behaviour of home, backlog, projects and project detail (key → callback). Then `AppShortcut`, `Bind`, `ShortcutScope` and the duplicate-key test harness, with no screens migrated.
2. **Global shortcuts** move onto the new type. `GlobalShortcuts` loses its inline maps. The shared list-navigation intents are defined once.
3. **Tasks:** home, backlog and the plan shortcuts in the task list. `BaseScreenShortcuts` and the task wrappers are removed.
4. **Projects:** projects and project detail.
5. **Spike, then forms and the right-sidebar Escape.** Show whether `ShortcutScope` receives keys while a form menu is open. If it does, migrate the forms and drop `HardwareShortcuts` there. If not, keep `HardwareShortcuts` and register only the help rows.
6. **Cleanup:** delete `ShortcutEntry`, the entry-list files and dead intents.

## Verification

- **Characterization:** each screen has widget tests with `sendKeyEvent` for its keys (including the typing guard), written before its migration and passing unchanged after it. Existing `undo_redo_shortcuts_test`, `task_form_shortcuts_test`, `command_palette_test` and `search_unfocus_highlight_test` pass unchanged apart from imports.
- **`ShortcutScope`:** tests for a bound key firing its handler, a letter key not firing while an `EditableText` has focus, an `allowWhileTyping` key firing there, and the help rows registering from `display` + `label`.
- **Modifier:** with `debugDefaultTargetPlatformOverride` set to macOS and to linux, `primary` resolves to meta and control, and `display` matches.
- **Duplicates:** the test passes on the final registry. A test fixture with two binds on one activator makes it fail.
- **Cleanup:** `grep -rn "BaseScreenShortcuts\|ShortcutEntry" lib test` returns nothing, and `flutter analyze` is clean.
- **Manual:** on desktop, each screen's keys, the Alt-hold hints and the `?` overlay, and Ctrl+P in an open task form menu.
