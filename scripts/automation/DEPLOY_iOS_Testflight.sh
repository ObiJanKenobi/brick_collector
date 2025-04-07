PROJ_DIR=~/Projects/flutter-apps/pitch-db-flutter

$PROJ_DIR/scripts/automation/_build.sh "Runner" "pitch_db_flutter" "$PROJ_DIR" "-preview"
$PROJ_DIR/scripts/automation/_deploy.sh "Runner" "pitch_db_flutter" "$PROJ_DIR" "-preview"
$PROJ_DIR/scripts/automation/_tag.sh "Runner" "pitch_db_flutter" "$PROJ_DIR" "-preview"
$PROJ_DIR/scripts/automation/_cleanup.sh "Runner" "pitch_db_flutter" "$PROJ_DIR" "-preview"

echo "done"
echo -e ""


read -p "Press any key to continue... " -n1 -s
