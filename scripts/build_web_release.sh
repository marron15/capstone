#!/usr/bin/env bash
# Build Flutter web for static hosting (e.g. Hostinger) and strip
# //# sourceMappingURL=... from root *.js (avoids 404s for flutter.js.map and
# jsQR's /sm/*.map in the browser console).
set -euo pipefail
cd "$(dirname "$0")/.."
flutter build web --release "$@"
dart run tool/strip_flutter_web_sourcemaps.dart
