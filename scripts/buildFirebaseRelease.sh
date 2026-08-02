#!/usr/bin/env bash
set -euo pipefail

# Build the prod release APK, distribute it via Firebase App Distribution and
# tag the build.
#
# Env overrides:
#   UPLOAD_DEBUG  1 to also build+distribute the debug APK
#   SKIP_TAG      1 to skip the git tag + push step

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$here"

echo "Running unit tests"
(cd "$here/.." && flutter test) || { echo "Tests failed - aborting build."; exit 1; }

echo "PROD Build"
bash ./prod_release_apk.sh

if [[ "${UPLOAD_DEBUG:-0}" == "1" ]]; then
  echo "PROD Debug Build"
  bash ./prod_release_debug_apk.sh
fi

echo "Uploading to Firebase"
bash ./upload_firebase.sh

if [[ "${SKIP_TAG:-0}" == "1" ]]; then
  echo "Skipping tag (SKIP_TAG=1)"
else
  echo "Tagging Build"
  bash ./git_tag.sh
fi
