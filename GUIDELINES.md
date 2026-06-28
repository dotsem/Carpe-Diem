# Carpe Diem AI Coding Guidelines

This document defines the coding standards, architectural decisions, and practices for the Carpe Diem codebase. Every AI assistant and developer working on this project **must** adhere strictly to these rules.

---

## 1. Universal Principles (Dart & Flutter)

### 1.1 Comments & Documentation
- **No Inline Comments**: Do not write comments within function bodies to explain syntax, control flow, or standard actions. If logic is complex, rewrite it to be self-documenting or extract it into a descriptive helper function.
- **Redundant Comments Ban**: Comments that echo the code syntax (e.g., `counter++ // increment counter`) are strictly forbidden.
- **Allowed Comments**:
  - Package/Library-level docstrings.
  - Standard Dartdoc documentation on public interfaces, classes, functions, and variables.
  - High-level `// Why:` comments explaining non-obvious architecture or business constraints.
  - Actionable `// TODO:` comments explaining future improvements, shortcuts taken, or technical debt to resolve.
- **Style**: Keep short comments lowercase. Use capital letters only for multi-line contextual explanations.

### 1.2 Function & File Design
- **Single Responsibility (SOLID)**: Every class and function must do exactly one thing and do it right. If a function or class performs multiple operations, break it down.
- **DRY (Don't Repeat Yourself)**: Generalized utilities must be extracted. Never duplicate logic.
- **KISS (Keep It Simple, Stupid)**: Favor simple, readable solutions over overly clever or complex abstractions.
- **Function Names**: The name must clearly reflect the function's single action. Avoid generic names or names with "And" (which signals multiple responsibilities).
- **File Length Limit**: A strict ceiling of **300 lines per file**. If a file exceeds this:
  - Aggressively decouple, group, and split into sub-modules or logical extensions.
  - **Important for AI**: Ask the developer for permission before performing a major file split/refactoring. Do not do it autonomously.
- **Clean Code**: No dead, unused, or commented-out code. Use named constants instead of magic numbers.

### 1.3 Development & Workflows
- **Test Coverage**: We target high test coverage for business and core logic. All public functions and notifier states should have unit/widget tests.
- **Linter & Formatter Integrity**: Never bypass formatters or linters. Before presenting or pushing code, formatting and linting checks must pass cleanly.
- **AI Tooling Constraints**:
  - AI assistants must **never** run git commits or push changes under any circumstance. Commits are reserved exclusively for human execution.
  - AI assistants must **never** begin execution of an implementation plan without explicit authorization/approval from the developer. A plan is a plan until the human developer explicitly says "go ahead".
- **Commit Format**: All commit messages must follow standard conventional commits format (e.g., `feat: description`, `fix: description`, `chore: description`).

---

## 2. Flutter / Dart Standards & Architecture

### 2.1 Tooling & Verification
- **Formatting**: Format the Dart codebase using:
  ```bash
  dart format .
  ```
- **Linting & Static Analysis**: Analyze the codebase using:
  ```bash
  flutter analyze
  ```
  All code must strictly pass standard rules configured in `analysis_options.yaml` (utilizing `package:flutter_lints/flutter.yaml`). Fix any lint warnings or information items automatically.

### 2.2 Component & Architecture Standards
- **Feature-First Structure**: Organize the codebase into cohesive feature folders under `lib/features/`:
  ```
  lib/
  ├── features/
  │   └── [feature_name]/
  │       ├── data/         # Data sources, repositories, models
  │       ├── domain/       # Entities, use-cases, repository interfaces
  │       └── presentation/ # Widgets, controllers/providers
  └── core/                 # Shared utilities, themes, network clients
  ```
- **State Management**: Use declarative state management with Riverpod (`flutter_riverpod`).
  - **No Code Generation**: Define `Notifier`, `NotifierProvider`, `AsyncNotifier`, and `AsyncNotifierProvider` manually. Do **NOT** use Riverpod generator or `@riverpod` annotations, as code generation is not configured for state management.
  - Separate business logic cleanly out of the UI tree.
- **Widget Performance**: Extract long nested widget trees into separate `StatelessWidget` or `ConsumerWidget` classes rather than inline helper builder functions to optimize Flutter widget reconciliation.
- **Theming**: Use standard context themes (`Theme.of(context)`) exclusively for layout, typography, and standard UI colors. Do not hardcode spacing or styles. Hardcoded hex colors are allowed only for custom user-configurable colors (e.g., project/label color selection).
- **Localization (i18n)**: Use `flutter_localizations` and `intl`. Never hardcode user-facing strings in presentation files.

### 2.3 Models & Serialization
- **No Freezed / Code Gen Models**: Do not use `freezed` or `json_serializable`. Models must be defined manually as immutable classes with `final` fields, a `const` constructor, standard `toMap()`/`fromMap()` methods, a `copyWith()` utility, and an `empty()` factory where appropriate.

### 2.4 Persistence & Repositories
- **Database Decoupling**: Repositories must depend on abstract interfaces (e.g., `ITaskRepository`) and accept the database instance via constructor injection. This enables swapping sqlite implementations with mocks during testing.
- **SQLite Storage**: Use `sqflite` (for platforms/mobile) and `sqflite_common_ffi` (for desktop/tests) for persistence.

### 2.5 Testing & Navigation
- **Testing**: Use standard `flutter_test` with `mocktail` for mocking dependencies. Group test cases cleanly using `group('feature_name', () { ... })` blocks.
- **Navigation**: Use `go_router` for type-safe routing.

---

## 3. Verification Commands Reference

Run the following commands to ensure absolute compliance before finalizing code:

| Action | Command |
|---|---|
| **Format** | `dart format .` |
| **Lint / Analyze** | `flutter analyze` |
| **Test Run** | `flutter test` |