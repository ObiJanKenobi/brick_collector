#!/usr/bin/env bash
set -euo pipefail

# Upload the current release (and optionally debug) APK to Firebase App Distribution.
#
# Env overrides:
#   FIREBASE_ACCOUNT  google account used for the upload
#   GROUP             App Distribution tester group
#   UPLOAD_DEBUG      1 to also distribute the debug APK

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Get Version from Pubspec (e.g. "1.0.0+1")
version=$(sed -n 's/^version:[[:space:]]*//p' "$root/pubspec.yaml" | head -1)
versionName="${version%%+*}"
# Get the update comment from Pubspec, fall back to the latest commit subject
comment=$(sed -n 's/^changes:[[:space:]]*//p' "$root/pubspec.yaml" | head -1)
comment="${comment:-$(git -C "$root" log -1 --pretty=%s)}"
buildModifier=$(sed -n 's/^buildModifier:[[:space:]]*//p' "$root/pubspec.yaml" | head -1)

mod="${buildModifier:-0}"

# Get revision to create build version
branch=$(git -C "$root" rev-parse --abbrev-ref HEAD)
gitversion=$(git -C "$root" rev-list "$branch" --first-parent --count)
build=$((gitversion + mod))

# Get firebase ID from services.json
firebaseId=$(sed -n 's/.*"mobilesdk_app_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  "$root/android/app/google-services.json" | head -1)

# Get the package from build gradle
package=$(sed -n 's/.*applicationId[[:space:]]*"\([^"]*\)".*/\1/p' \
  "$root/android/app/build.gradle" | head -1)

group="${GROUP:-qs}"
account="${FIREBASE_ACCOUNT:-obijankenobi83@gmail.com}"

# Flutter emits app-release.apk / app-debug.apk; flutter-apk/ is the canonical
# copy, apk/<type>/ is the raw gradle output.
releaseApk="$root/build/app/outputs/flutter-apk/app-release.apk"
[[ -f "$releaseApk" ]] || releaseApk="$root/build/app/outputs/apk/release/app-release.apk"
debugApk="$root/build/app/outputs/flutter-apk/app-debug.apk"
[[ -f "$debugApk" ]] || debugApk="$root/build/app/outputs/apk/debug/app-debug.apk"

echo "Package:     $package"
echo "Branch:      $branch"
echo "Version:     $versionName"
echo "Build:       $build"
echo "Firebase Id: $firebaseId"
echo "Account:     $account"
echo "Group:       $group"
echo "Kommentar:   $comment"
echo "Release APK: $releaseApk"

if [[ ! -f "$releaseApk" ]]; then
  echo "ERROR: release APK not found - run prod_release_apk.sh first." >&2
  exit 1
fi

firebase appdistribution:distribute "$releaseApk" \
  --app "$firebaseId" \
  --account "$account" \
  --release-notes "$versionName+$build - $comment" \
  --groups "$group"

if [[ "${UPLOAD_DEBUG:-0}" == "1" ]]; then
  if [[ -f "$debugApk" ]]; then
    echo "Debug APK:   $debugApk"
    firebase appdistribution:distribute "$debugApk" \
      --app "$firebaseId" \
      --account "$account" \
      --release-notes "DEBUG $versionName+$build - $comment" \
      --groups "$group"
  else
    echo "WARN: UPLOAD_DEBUG=1 but no debug APK at $debugApk - skipping." >&2
  fi
fi
