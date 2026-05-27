# Carpe Diem Refactoring Plan

A comprehensive, step-by-step technical plan to address structural debt, migrate to Riverpod, enforce clean architecture, and implement high-coverage testing.

---

## Critical Critique of Starting with Unit Tests First
Starting with unit tests immediately is a **bad idea** for the current codebase:
1. **Coupled Database Layer:** Repositories have hardcoded dependencies on SQLite FFI and global static state (`DatabaseHelper.database`). VM unit tests will fail or require ugly FFI mock workarounds.
2. **Impending Architecture Shift:** Migrating to a feature-first architecture and Riverpod means almost every file will move and its interface will change. Any test written for the legacy code will be thrown away immediately.

**Recommendation:** Build the testable foundation first, then write tests as each decoupled feature is implemented.

---

## Architectural Phase Plan

### Phase 1: Database & Repository Decoupling (Generalize DB Layer)
Decouple repositories from static SQLite instances to enable dependency injection and mockability.
- [ ] **Step 1.1: Define Repository Interfaces**
  Create abstract contracts (`ITaskRepository`, `IProjectRepository`, `ILabelRepository`, `ISettingsRepository`) to support swapping implementations (SQLite vs. Mock).
- [ ] **Step 1.2: Generalize Database Helper**
  Refactor `DatabaseHelper` from a static singleton to a class that can be initialized and injected.
- [ ] **Step 1.3: Update Repository Concrete Implementations**
  Make repositories accept a database instance via constructor injection.

### Phase 2: Feature-First Directory Restructuring
Restructure the app to enforce cohesive feature separation and strict boundaries.
- [ ] **Step 2.1: Establish `lib/features/` Directory Structure**
  Create feature sub-directories:
  - `lib/features/tasks/`
  - `lib/features/projects/`
  - `lib/features/labels/`
  - `lib/features/settings/`
  - `lib/features/history/`
- [ ] **Step 2.2: Migrate & Split Files**
  Move existing layered files (`lib/data/`, `lib/providers/`, `lib/ui/`) to their respective feature directories:
  - `/data` -> `lib/features/[feature]/data/`
  - `/domain` -> `lib/features/[feature]/domain/` (create this layer for clean use-cases/entities)
  - `/presentation` -> `lib/features/[feature]/presentation/`

### Phase 3: Riverpod Migration & Decoupling Providers (Under 300 Lines)
Replace Provider/ChangeNotifier with highly decoupled, specialized Riverpod providers.
- [ ] **Step 3.1: Package dependency swap**
  Remove `provider` from `pubspec.yaml` and add `flutter_riverpod`.
- [ ] **Step 3.2: Settings Provider Migration**
  Refactor settings into a Riverpod `Notifier`.
- [ ] **Step 3.3: Project & Label Provider Migration**
  Convert to AsyncNotifiers and decouple labels logic.
- [ ] **Step 3.4: Decouple Task Provider (< 300 lines)**
  Split `TaskProvider` (currently 470+ lines) into granular units:
  - `TaskNotifier` (for task CRUD and state)
  - `TaskTimerNotifier` (timer-based completion logic)
  - `TaskSchedulingService` (rescheduling, auto-scheduling)
  - `TaskMarkdownImportService` (markdown parsing/import)

### Phase 4: Presentation Decoupling & Component Extraction
Aggressively decouple UI logic from screens and enforce the 300-line limit per file.
- [ ] **Step 4.1: Split `backlog_screen.dart` (< 300 lines)**
  Extract UI components into independent widget files:
  - `backlog_search_bar.dart`
  - `backlog_list_view.dart`
  - `backlog_bulk_bar.dart`
- [ ] **Step 4.2: Split `project_detail_screen.dart` (< 300 lines)**
  Extract project header and task list elements.
- [ ] **Step 4.3: Standardize Component Architecture**
  Replace inline helper functions returning widgets with lightweight `StatelessWidget` or `ConsumerWidget` classes to optimize Flutter widget reconciliation.

### Phase 5: Comprehensive Unit & Widget Testing
Write high-fidelity tests against the decoupled, testable architecture.
- [ ] **Step 5.1: Write Repository Unit Tests**
  Use mock repositories/database drivers to verify business data transactions.
- [ ] **Step 5.2: Write Provider State/Logic Unit Tests**
  Verify state mutations in `TaskNotifier`, `SettingsNotifier`, and service classes using `ProviderContainer`.
- [ ] **Step 5.3: Write Widget Tests**
  Implement integration widget tests for core screens (e.g. Backlog, Home, Settings) overriding dependencies in `ProviderScope`.
