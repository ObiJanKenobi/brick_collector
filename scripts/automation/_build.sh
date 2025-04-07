echo -e "Build $1..."

# Get Version from Pubspec
version=$(LC_ALL=en_US.utf8 grep -p "version: " "$3/pubspec.yaml" | awk -F ':' '{print $2}' | xargs)
buildModifier=$(LC_ALL=en_US.utf8 grep -p "iosBuildModifier: " "$3/pubspec.yaml" | awk -F ':' '{print $2}' | xargs)
mod="${buildModifier:-0}"

branch=$(git rev-parse --abbrev-ref HEAD)
gitversion=$(git rev-list $branch --first-parent --count)
build=$(($gitversion + $mod))


# set BuildNumber of ios info.plist to the buildNumber found in our pubspec.yaml
defaults write "$3/ios/$1/Info.plist" CFBundleVersion "$build"

# set version of ios info.plist to the version found in our pubspec.yaml
defaults write "$3/ios/$1/Info.plist" CFBundleShortVersionString "$version"



xcodebuild -allowProvisioningUpdates -workspace $3/ios/Runner.xcworkspace -scheme $1 -sdk "iphoneos" -configuration Release archive -archivePath $3/build/$1/$1.xcarchive

echo -e "Build $1 completed! Version: ${version} - ${build}"
