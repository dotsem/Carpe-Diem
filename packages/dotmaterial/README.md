# dotmaterial

General widgets and helpers that fill gaps in the standard Flutter widgets.

Not meant for app-specific reusable widgets: everything here must be usable in other apps as-is.

## Usage

```dart
import 'package:dotmaterial/dotmaterial.dart';
```

Only `lib/dotmaterial.dart` is public API; files under `lib/src/` are internal.

## Import rule

Files in this package may only import `dart:*`, `package:flutter/*`, `package:fuzzy` and each other (via `package:dotmaterial/...` imports).
Never import the app, Riverpod or app theme/constants; take colors as parameters or read `Theme.of(context)`.
`flutter analyze` flags any package not listed in `pubspec.yaml` (`depend_on_referenced_packages`).
