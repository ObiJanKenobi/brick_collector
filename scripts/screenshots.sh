#!/usr/bin/env bash
#
# Capture tester-facing screenshots (first screen + Rebrickable login & sync)
# from the app running on one or more iOS simulators.
#
# Usage:
#   scripts/screenshots.sh                       # default: iPhone + iPad
#   scripts/screenshots.sh iphone                # iPhone 16 Pro only
#   scripts/screenshots.sh ipad                  # iPad Pro 13-inch (M4) only
#   scripts/screenshots.sh iphone ipad           # both (same as default)
#   scripts/screenshots.sh "iPhone 17 Pro" "iPad Air 13-inch (M3)"  # by name
#   scripts/screenshots.sh ipad --keep           # keep existing app data
#
# Aliases:  iphone → iPhone 16 Pro   ipad → iPad Pro 13-inch (M4)
#
# Output: shots/<timestamp>/<device>/*.png   (shots/latest → newest run)
#
# Optional: prefill the login dialog by exporting creds before running:
#   USER_ID=you@example.com USER_PASSWORD=secret scripts/screenshots.sh
#
set -euo pipefail

cd "$(dirname "$0")/.."

BUNDLE_ID="com.example.brickCollector"
IPHONE_DEFAULT="iPhone 16 Pro"
IPAD_DEFAULT="iPad Pro 13-inch (M4)"

# ---- Parse args: flags + device names (with aliases) ------------------------
KEEP_DATA=false
DEVICES=()
for arg in "$@"; do
  case "$arg" in
    --keep)         KEEP_DATA=true ;;
    iphone|iPhone)  DEVICES+=("${IPHONE_DEFAULT}") ;;
    ipad|iPad)      DEVICES+=("${IPAD_DEFAULT}") ;;
    both)           DEVICES+=("${IPHONE_DEFAULT}" "${IPAD_DEFAULT}") ;;
    *)              DEVICES+=("$arg") ;;
  esac
done
# No devices named → capture both form factors.
[[ ${#DEVICES[@]} -eq 0 ]] && DEVICES=("${IPHONE_DEFAULT}" "${IPAD_DEFAULT}")

STAMP="$(date +%Y-%m-%d-%H%M%S)"
RUN_DIR="shots/${STAMP}"

# Pass login creds through to the app if present (prefills the login dialog).
DEFINES=()
[[ -n "${USER_ID:-}" ]]       && DEFINES+=(--dart-define=USER_ID="${USER_ID}")
[[ -n "${USER_PASSWORD:-}" ]] && DEFINES+=(--dart-define=USER_PASSWORD="${USER_PASSWORD}")

# ---- Capture a single device ------------------------------------------------
capture() {
  local name="$1"
  echo ""
  echo "▸ Target: ${name}"

  # Newest available simulator matching the name.
  local udid
  udid="$(xcrun simctl list devices available \
    | grep -F "${name} (" \
    | head -1 \
    | grep -oE '[0-9A-F-]{36}' || true)"
  if [[ -z "${udid}" ]]; then
    echo "  ✗ No available simulator named '${name}'." >&2
    echo "    List them with: xcrun simctl list devices available" >&2
    return 1
  fi
  echo "  UDID: ${udid}"

  xcrun simctl boot "${udid}" 2>/dev/null || true
  open -a Simulator
  xcrun simctl bootstatus "${udid}" -b >/dev/null 2>&1 || true

  # A clean install guarantees the first-run group-setup screen.
  if [[ "${KEEP_DATA}" == false ]]; then
    echo "  Uninstalling ${BUNDLE_ID} (clean first-screen; pass --keep to skip)"
    xcrun simctl uninstall "${udid}" "${BUNDLE_ID}" 2>/dev/null || true
  fi

  # Slugify the device name for the output folder.
  local slug outdir
  slug="$(printf '%s' "${name}" | tr ' /()' '-' | tr -s '-' | sed 's/-$//')"
  outdir="${RUN_DIR}/${slug}"
  mkdir -p "${outdir}"
  echo "  Capturing to ${outdir}/"

  SCREENSHOT_DIR="${outdir}" flutter drive \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/screenshots_test.dart \
    -d "${udid}" \
    ${DEFINES[@]+"${DEFINES[@]}"}
}

# ---- Run every requested device (keep going if one fails) -------------------
FAILED=()
for device in "${DEVICES[@]}"; do
  capture "${device}" || FAILED+=("${device}")
done

ln -sfn "${STAMP}" shots/latest

echo ""
echo "✓ Screenshots in ${RUN_DIR}/:"
find "${RUN_DIR}" -name '*.png' | sort | sed 's/^/  /'
if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo "✗ Failed device(s): ${FAILED[*]}" >&2
fi
open "${RUN_DIR}" 2>/dev/null || true
