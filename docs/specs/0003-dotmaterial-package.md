# 0003: Extract flutter_ext into the dotmaterial package

Status: draft

## Why

- `lib/flutter_ext/README.md` says everything in the folder must be usable in other apps as-is, and may import only `dart:*`, Flutter, `package:fuzzy` and its own files through relative imports. Nothing enforces that. Five files already import `package:carpe_diem/flutter_ext/...`.
- Inside the app, `flutter_ext` coverage gets mixed with app coverage, and app tests can cover it by accident.
- A package boundary makes the import rule a compile error and gives the code its own tests and coverage.

## Scope / Non-goals

- In scope: everything in `lib/flutter_ext/` and its tests in `test/flutter_ext/`.
- Non-goals:
  - Publishing to pub.dev, versioning or a changelog.
  - A separate repo.
  - Moving app-specific shared widgets (`features/common/presentation/widgets`) into the package.
  - API changes. It's a move, not a redesign.

## Design

**Location and name:** `packages/dotmaterial/`, with package name `dotmaterial`. The app imports `package:dotmaterial/...`.

**Pub workspace.** The root `pubspec.yaml` gets `workspace: [packages/dotmaterial]`, and the package's pubspec gets `resolution: workspace`. That gives one lockfile and one version of Flutter and `fuzzy`, and the app's SDK constraint (`^3.10.4`) already supports workspaces.

- Rejected: a plain `path:` dependency. It means a second resolution and lockfile to keep in sync.
- Rejected: a separate repo. Every change would need two PRs.

**Public API:** a barrel file, `lib/dotmaterial.dart`, exports the widgets the app uses. Helpers the app doesn't import go under `lib/src/`. Internal imports are relative.

**CI: a new `test-paths` input in `dotactions/flutter` `ci.yml`.** It takes a list of paths and defaults to `["."]`.

- The test job runs `flutter test --coverage` in each path.
- It prefixes each path's `SF:` entries so they're repo-relative, the same as the existing `working-directory` handling.
- It concatenates the results into the single `lcov.info` artifact.
- `analyze` and `verify-generated` already cover `packages/` from the root.
- Rejected: a separate job in this repo. Its coverage would stay out of the report.

**Order:** best done after step 7 of [0002](0002-test-coverage/plan.md), so the tests move together with the code. Doing it first also works; it just means rewriting the imports in 3 test files instead of about 10.

## Risks

- **About 44 app files import `package:carpe_diem/flutter_ext/...`.** A missed one fails the build. That's loud, not silent.
- **`flutter analyze` at the root might not analyse a workspace member.** If so, lints and the import rule go unchecked in CI.
- **The `test-paths` change breaks consumers of `dotactions/flutter` that rely on the current single-directory behaviour.**
- **Coverage paths double up or don't match PR diffs**, so patch coverage reads 0% for package files.

## Plan

1. **dotactions PR** in `dotactions/flutter/.github/workflows/ci.yml`: add the `test-paths` input, loop the test step and the "Prepare coverage report" step over it, and concatenate the lcov files. Release it, then bump the pinned SHA in `.github/workflows/ci.yml`.
2. **App PR:**
   - Create `packages/dotmaterial/` with `pubspec.yaml` (`resolution: workspace`; deps `flutter`, `fuzzy`; dev dep `flutter_test`), `lib/dotmaterial.dart`, `lib/src/**` and `README.md` (moved from `lib/flutter_ext/README.md`).
   - Move `test/flutter_ext/**` to `packages/dotmaterial/test/`.
   - In the root `pubspec.yaml`, add `workspace:` and `dotmaterial:` (with `fuzzy` going only if the app no longer uses it directly).
   - Rewrite the imports in the app files.
   - Delete `lib/flutter_ext/`.
   - In `.github/workflows/ci.yml`, set `test-paths: '[".", "packages/dotmaterial"]'`.
   - Update `CLAUDE.md`/`GUIDELINES.md` wherever they mention `flutter_ext`.

## Verification

- **Missed imports:** run `flutter analyze` and `flutter test` at the root, and `grep -r "flutter_ext" lib test`, which should return nothing.
- **Analyzer reach:** temporarily add an unused import to a package file and check that `flutter analyze` at the root reports it. If not, run analyze per package in the dotactions loop too.
- **Breaking dotactions consumers:** `test-paths` defaults to `["."]`, so the existing behaviour doesn't change. Check by running one other consumer repo on the new SHA.
- **Coverage paths:** on the app PR, the coverage comment should list package files as `packages/dotmaterial/lib/...`, and patch coverage should be non-zero for the moved files.

## Assumptions

- The package version stays at `0.0.0` with `publish_to: none`.
- `analysis_options.yaml` is shared by including the root one from the package.
