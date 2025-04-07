echo -e "Tagging $1..."

unzip -q -o -d "$3/build/$1/unzipped-ipa" "$3/build/$1/$2.ipa"
VERSION="$(defaults read "$3/build/$1/unzipped-ipa/Payload/$1.app/Info.plist" CFBundleShortVersionString)"
BUILD="$(defaults read "$3/build/$1/unzipped-ipa/Payload/$1.app/Info.plist" CFBundleVersion)"

TAG="v${VERSION}-${BUILD}_iOS"
git tag $TAG
git push origin $TAG

echo -e "Tagging $1 completed with '$TAG'"
