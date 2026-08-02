#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/build_version.sh"

echo "Version: $VERSION_NAME"
echo "Build: $BUILD_NUMBER"
echo "Description: $DESCRIPTION"

git -C "$ROOT" tag -a "$VERSION_NAME+$BUILD_NUMBER" \
  -m "$DESCRIPTION Release von $VERSION_NAME+$BUILD_NUMBER"

git -C "$ROOT" push origin --tags
