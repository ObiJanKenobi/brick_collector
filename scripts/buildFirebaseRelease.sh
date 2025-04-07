echo "PROD Build"
./prod_release_apk.sh
echo "PROD Debug Build"
./prod_release_debug_apk.sh
echo "Uploading to Firebase"
./upload_firebase.sh
echo "Tagging Build"
./git_tag.sh
