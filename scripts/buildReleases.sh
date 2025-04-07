echo "Clear Flutter Builds"
flutter clean
echo "PROD Build"
./prod_release_apk.sh
echo "PROD Debug Build"
./prod_release_debug_apk.sh
echo "PROD Bundle Build"
./prod_release_appbundle.sh

cd ../build/app/outputs/bundle/release
start .
