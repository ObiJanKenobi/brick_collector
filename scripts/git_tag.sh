# Get Version from Pubspec
version=$(LC_ALL=en_US.utf8 grep -P "version: (.+)" ../pubspec.yaml -o | awk -F ':' '{print $2}' | xargs)
buildModifier=$(LC_ALL=en_US.utf8 grep -P "buildModifier: (.+)" ../pubspec.yaml -o | awk -F ':' '{print $2}' | xargs)
mod="${buildModifier:-0}"

# Get the description from Pubspec
description=$(LC_ALL=en_US.utf8 grep -P "description: (.+)" ../pubspec.yaml -o | awk -F ':' '{print $2}' | xargs)

# Get revision to create build version
branch=$(git rev-parse --abbrev-ref HEAD)
gitversion=$(git rev-list $branch --first-parent --count)
build=$(($gitversion + $mod))

echo "Version: $version"
echo "Build: $build"
echo "Description: $description"

git tag -a $version+$build -m "$description Release von $version+$build"

git push origin --tags
