# Screenshot flow

Captures the key onboarding screens for handing to testers:

| File | Screen |
|------|--------|
| `01-first-screen.png` | Group create/join (the real first-run screen) |
| `02-rebrickable-login.png` | Rebrickable login dialog |
| `03-rebrickable-sync.png` | Collection sync progress modal |

## Run it

```bash
scripts/screenshots.sh                 # default: iPhone + iPad
scripts/screenshots.sh iphone          # iPhone 16 Pro only
scripts/screenshots.sh ipad            # iPad Pro 13-inch (M4) only
scripts/screenshots.sh "iPhone 17 Pro" "iPad Air 13-inch (M3)"  # by name
scripts/screenshots.sh ipad --keep     # keep existing app data
```

Aliases: `iphone` → iPhone 16 Pro, `ipad` → iPad Pro 13-inch (M4). Any other
argument is treated as a literal simulator name (`xcrun simctl list devices`).

Output lands in `shots/<timestamp>/<device>/` — one folder per device (and
`shots/latest` → newest run). The run folder opens in Finder when it finishes.

### Prefill the login dialog

Export your Rebrickable creds to populate the email/password fields in the
`02-rebrickable-login` shot:

```bash
USER_ID=you@example.com USER_PASSWORD=secret scripts/screenshots.sh
```

## How it works

- `integration_test/screenshots_test.dart` — the driver test. Boots the real
  app for the first screen, then presents the **real** login dialog and sync
  modal over a branded host surface, driven with controlled input so the run is
  deterministic and needs no network or account.
- `test_driver/integration_test.dart` — host side; writes each screenshot PNG
  to `$SCREENSHOT_DIR`.
- `scripts/screenshots.sh` — boots the simulator, does a clean install (so the
  first-run screen shows), runs `flutter drive`, and collects the PNGs.

## Notes

- Clean install is what guarantees the group-setup "first screen". Pass
  `--keep` to skip the uninstall (you'll then land on Home if a group exists).
- Run via `scripts/screenshots.sh` (i.e. `flutter drive`), **not**
  `flutter test` — on-device screenshots only work under `flutter drive`.
- To capture a **real** sync with your actual collection instead of the
  representative frame, log in + sync in the running app and grab it manually,
  or extend the test to drive `collectionSyncService.syncAll()` with live creds.
