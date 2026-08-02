#!/usr/bin/env bash
# Shared version data for the release scripts. Source this file, do not run it:
#
#   source "$(dirname "${BASH_SOURCE[0]}")/build_version.sh"
#
# Exports:
#   ROOT           repo root
#   BRANCH         current branch
#   VERSION_NAME   from pubspec "version", with the "+build" suffix stripped
#   BUILD_NUMBER   first-parent commit count + pubspec "buildModifier"
#   RELEASE_NOTES  pubspec "changes", falling back to the latest commit subject
#   DESCRIPTION    pubspec "description"
#
# BUILD_NUMBER is the single source of truth for the Android versionCode, the
# git tag and the Firebase release notes, so the three can never drift apart.
# The "+N" in pubspec's version is ignored for scripted builds - the release
# scripts pass BUILD_NUMBER to flutter via --build-number, which overrides it.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Read a top-level scalar key from pubspec.yaml.
_pubspec() { sed -n "s/^$1:[[:space:]]*//p" "$ROOT/pubspec.yaml" | head -1; }

VERSION_NAME="$(_pubspec version)"
VERSION_NAME="${VERSION_NAME%%+*}"

_mod="$(_pubspec buildModifier)"
BRANCH="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)"
_count="$(git -C "$ROOT" rev-list "$BRANCH" --first-parent --count)"
BUILD_NUMBER=$(( _count + ${_mod:-0} ))

RELEASE_NOTES="$(_pubspec changes)"
RELEASE_NOTES="${RELEASE_NOTES:-$(git -C "$ROOT" log -1 --pretty=%s)}"

DESCRIPTION="$(_pubspec description)"

export ROOT BRANCH VERSION_NAME BUILD_NUMBER RELEASE_NOTES DESCRIPTION
