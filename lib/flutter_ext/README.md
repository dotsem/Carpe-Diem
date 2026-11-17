# flutter_ext

General widgets and helpers that fill gaps in the standard Flutter widgets.

Not meant for app-specific reusable widgets: everything here must be usable in other apps as-is.

## Import rule

Files in this folder may only import `dart:*`, `package:flutter/*`, `package:fuzzy` and each other (via relative imports).
Never import `package:carpe_diem/...`, Riverpod or app theme/constants; take colors as parameters or read `Theme.of(context)`.
