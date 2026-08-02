#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/build_version.sh"
cd "$ROOT"

echo "Building release APK $VERSION_NAME+$BUILD_NUMBER"
flutter build apk --dart-define=FORCE_UI=material ./lib/main.dart
