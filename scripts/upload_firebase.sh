# Get Version from Pubspec
version=$(LC_ALL=en_US.utf8 grep -P "version: (.+)" ../pubspec.yaml -o | awk -F ':' '{print $2}' | xargs)
# Get the update comment from Pubspec
comment=$(LC_ALL=en_US.utf8 grep -P "changes: (.+)" ../pubspec.yaml -o | awk -F ':' '{print $2}' | xargs)
buildModifier=$(LC_ALL=en_US.utf8 grep -P "buildModifier: (.+)" ../pubspec.yaml -o | awk -F ':' '{print $2}' | xargs)

mod="${buildModifier:-0}"

# Get revision to create build version
branch=$(git rev-parse --abbrev-ref HEAD)
gitversion=$(git rev-list $branch --first-parent --count)
build=$(($gitversion + $mod))

# Get firebase ID from services.json
firebaseId=$(LC_ALL=en_US.utf8 grep -P 'mobilesdk_app_id": "(.+)"' ../android/app/google-services.json -o | awk '{print $2}' | tr -d '"')

# Get the package from build gradle
package=$(LC_ALL=en_US.utf8 grep -P 'applicationId.*' ../android/app/build.gradle -o | awk '{print $2}' | tr -d '"')


group="qs-mps"

echo "Package: $package"
echo "Branch: $branch"
echo "Version: $version"
echo "Build: $build"
echo "Firebase Id: $firebaseId"
echo "Group: $group"
echo "Kommentar: $comment"

#adb install ../build/app/outputs/apk/$stage/release/$package-$version+$build-release.apk
firebase appdistribution:distribute ../build/app/outputs/apk/release/$package-$version+$build-release.apk --app $firebaseId --release-notes "$comment" --groups $group
firebase appdistribution:distribute ../build/app/outputs/apk/debug/$package-$version+$build-debug.apk --app $firebaseId --release-notes "DEBUG, $comment" --groups $group
