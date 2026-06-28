# Gemini AI Instructions for Carpe Diem

This file provides high-level guidelines and instructions for Gemini models interacting with this codebase. For full technical details and coding standards, refer to the main [GUIDELINES.md](GUIDELINES.md) file.

---

## CRITICAL CONSTRAINTS (Must Follow Without Exception)

1. **Strict File Line Limit (300 Lines)**
   - Every file has a strict maximum ceiling of **300 lines**.
   - If your generated or refactored code exceeds this, you must aggressively decouple and split it into sub-modules or logical widgets/classes.
   - Do **NOT** do major refactoring or file splitting autonomously; ask the developer for permission first.

2. **No Code Generation for State or Models**
   - **State Management**: Use manual Riverpod classes (`Notifier`, `AsyncNotifier`, `NotifierProvider`, etc.). **Do not use `@riverpod` annotations or the riverpod generator**.
   - **Data Models**: Write models manually with standard `toMap()`, `fromMap()`, and `copyWith()` methods. **Do not use `freezed` or `json_serializable`**.

3. **Comment Standards**
   - **No Inline Comments**: Do not explain standard Dart/Flutter syntax, control flow, or simple operations.
   - **No Redundant Comments**: Comments like `counter++ // increment counter` are strictly banned.
   - **Allowed**: Standard Dartdoc on public APIs, high-level `// Why:` comments, and `// TODO:` comments for future improvements. Keep short comments lowercase.

4. **Workflow Restrictions**
   - **No Git Access**: Never run git commits or push changes. Commits are reserved exclusively for the human developer.
   - **Plan Approval**: Never start implementing complex changes without writing an implementation plan and getting explicit approval from the developer.

---

## Verification Command Reference

Always format and check your code before finishing tasks:

| Command | Purpose |
|---|---|
| `dart format .` | Formats all Dart files |
| `flutter analyze` | Runs static analysis and lints |
| `flutter test` | Executes the unit/widget test suite |

For specific instructions on clean architecture, repository decoupling, and testing patterns, consult [GUIDELINES.md](GUIDELINES.md).
