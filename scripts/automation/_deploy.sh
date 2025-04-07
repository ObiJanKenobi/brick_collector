echo -e "Deploy $1..."


xcodebuild -exportArchive -archivePath "$3/build/$1/$1.xcarchive" -exportOptionsPlist "$3/scripts/automation/_exportOptions.plist" -exportPath "$3/build/$1" -allowProvisioningUpdates

# The password is not the Apple Account Password, but the One-Time (Application) password from appleid.apple.com/account/manage.
# Should be no problem to have them exposed as plaintext here

#xcrun altool --validate-app --type ios --file "$3/build/$1/$2.ipa" --username "vonaffenfels@googlemail.com" --password "ixcb-twrz-tljs-pttb"
xcrun altool --upload-app --type ios --file "$3/build/$1/$2.ipa" --username "vonaffenfels@googlemail.com" --password "ixcb-twrz-tljs-pttb"


echo -e "Deploy $1 completed!"
