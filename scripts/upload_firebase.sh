#!/usr/bin/env bash
set -euo pipefail

# Upload the current release (and optionally debug) APK to Firebase App
# Distribution.
#
# Env overrides:
#   FIREBASE_ACCOUNT  google account used for the upload
#   GROUP             App Distribution tester group
#   UPLOAD_DEBUG      1 to also distribute the debug APK

source "$(dirname "${BASH_SOURCE[0]}")/build_version.sh"

# Get firebase ID from services.json
firebaseId=$(sed -n 's/.*"mobilesdk_app_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  "$ROOT/android/app/google-services.json" | head -1)

# Get the package from build gradle
package=$(sed -n 's/.*applicationId[[:space:]]*"\([^"]*\)".*/\1/p' \
  "$ROOT/android/app/build.gradle" | head -1)

group="${GROUP:-qs}"
account="${FIREBASE_ACCOUNT:-obijankenobi83@gmail.com}"

# build.gradle sets archivesBaseName, so gradle emits
# <package>-<version>+<build>-<type>.apk; flutter additionally copies the
# artifact to flutter-apk/app-<type>.apk. Accept either.
find_apk() {
  local type="$1" candidate
  for candidate in \
    "$ROOT/build/app/outputs/apk/$type/$package-$VERSION_NAME+$BUILD_NUMBER-$type.apk" \
    "$ROOT/build/app/outputs/flutter-apk/app-$type.apk" \
    "$ROOT/build/app/outputs/apk/$type/app-$type.apk"; do
    if [[ -f "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

releaseApk="$(find_apk release || true)"

echo "Package:     $package"
echo "Branch:      $BRANCH"
echo "Version:     $VERSION_NAME"
echo "Build:       $BUILD_NUMBER"
echo "Firebase Id: $firebaseId"
echo "Account:     $account"
echo "Group:       $group"
echo "Kommentar:   $RELEASE_NOTES"
echo "Release APK: ${releaseApk:-<none>}"

if [[ -z "$releaseApk" ]]; then
  echo "ERROR: release APK not found - run prod_release_apk.sh first." >&2
  exit 1
fi

firebase appdistribution:distribute "$releaseApk" \
  --app "$firebaseId" \
  --account "$account" \
  --release-notes "$VERSION_NAME+$BUILD_NUMBER - $RELEASE_NOTES" \
  --groups "$group"

if [[ "${UPLOAD_DEBUG:-0}" == "1" ]]; then
  debugApk="$(find_apk debug || true)"
  if [[ -n "$debugApk" ]]; then
    echo "Debug APK:   $debugApk"
    firebase appdistribution:distribute "$debugApk" \
      --app "$firebaseId" \
      --account "$account" \
      --release-notes "DEBUG $VERSION_NAME+$BUILD_NUMBER - $RELEASE_NOTES" \
      --groups "$group"
  else
    echo "WARN: UPLOAD_DEBUG=1 but no debug APK found - skipping." >&2
  fi
fi
