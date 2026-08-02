#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Get Version from Pubspec
version=$(sed -n 's/^version:[[:space:]]*//p' "$root/pubspec.yaml" | head -1)
version="${version%%+*}"
buildModifier=$(sed -n 's/^buildModifier:[[:space:]]*//p' "$root/pubspec.yaml" | head -1)
mod="${buildModifier:-0}"

# Get the description from Pubspec
description=$(sed -n 's/^description:[[:space:]]*//p' "$root/pubspec.yaml" | head -1)

# Get revision to create build version
branch=$(git -C "$root" rev-parse --abbrev-ref HEAD)
gitversion=$(git -C "$root" rev-list "$branch" --first-parent --count)
build=$((gitversion + mod))

echo "Version: $version"
echo "Build: $build"
echo "Description: $description"

git -C "$root" tag -a "$version+$build" -m "$description Release von $version+$build"

git -C "$root" push origin --tags
