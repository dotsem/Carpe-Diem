# Changelog

All notable changes to Carpe Diem will be documented in this file.

## v0.6.0 - Modes & Animations

- **Drag-and-Drop Polish:** Added swing animations, placeholder indicators, extended list drag boundaries, and right-click cancellation for tasks and projects.
- **Sub-task Linking:** Support linking existing standalone tasks into parent tasks as sub-tasks.
- **Form Shortcuts:** Added keyboard shortcuts for faster task and project creation and editing.
- **Task Modes:** Added filter modes for tasks.
- **Animation Controls:** Added an option in settings to disable animations across the application.


## v0.5.0 - Desktop & UI Overhaul

- **Desktop Overhaul:** Optimize desktop UI layout and interaction models.
- **Split Backlog By Labels:** Split backlog into separate lists based on labels.
- **Dialog Overhaul:** Streamline modals and integrate more controls into sidebars.

## v0.4.0 - Core Features & Provider Architecture

- **Undo & Redo:** Undo and redo system for task actions.
- **Sub-tasks:** Hierarchical sub-task support and cascade completion.
- **Tags:** Support adding tags to tasks with inline autocomplete.
- **Sorting Overhaul:** LexoRank continuous drag-and-drop sorting.
- **Grouped Settings:** Category-based settings navigation in a dedicated sidebar.
- **Architecture Refactor:** Modularized task provider into domain services.

## v0.3.0 - Riverpod Migration & Refactor

- **Migrate to Riverpod:** Replaced Provider/ChangeNotifier with Riverpod providers.
- **Core Logic Decoupling:** Moved repository and logic out of providers.
- **Improved Performance:** Implemented granular rebuilds for complex lists.
- **Unit Testing:** Increased coverage for core logic.
- **Widget Testing:** Initial test suite for major UI components.

## v0.2.0 - History, Statistics & Personalization

- **History:** View completed tasks and history overview across time ranges.
- **Statistics:** Analytics and statistics about task completion.
- **Dynamic Theming:** Manual toggle and system-based dark mode.
- **Personalization:** Enhanced app customizability.

## v0.1.0 - Initial Release

- **Core Task Management:** Add, complete, and delete tasks.
- **Categories:** Organise tasks by projects.
- **Local Storage:** SQLite implementation for persistent data.
- **Basic UI:** Material Design implementation.
