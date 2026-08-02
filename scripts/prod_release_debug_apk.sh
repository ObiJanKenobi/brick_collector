#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/build_version.sh"
cd "$ROOT"

echo "Building debug APK $VERSION_NAME+$BUILD_NUMBER"
flutter build apk --dart-define=FORCE_UI=material --debug ./lib/main.dart
