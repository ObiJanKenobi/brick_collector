# Windows release (portable ZIP)

Produces a self-contained folder testers can run with no installer and no admin
rights: unzip, double-click `brick_collector.exe`.

## One-time setup on the Windows build machine

1. **Visual Studio 2022** with the **"Desktop development with C++"** workload
   — <https://visualstudio.microsoft.com/downloads/>. (Community edition is fine.)
2. **Flutter SDK** on `PATH` — verify with `flutter doctor` (the "Visual Studio"
   check must be green).
3. Enable desktop once:
   ```powershell
   flutter config --enable-windows-desktop
   ```
4. **Clone `brick-lib` next to this repo** — the app depends on it via a
   relative path (`../brick-lib`), and the Windows Cloudflare fix lives there:
   ```
   <parent>\brick_collector   (this repo)
   <parent>\brick-lib         git clone https://github.com/ObiJanKenobi/brick-lib
   ```
   Make sure both are pushed/pulled to the latest commit before building.

## Build

From the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_windows.ps1
```

The script runs `flutter build windows --release`, bundles the Visual C++
runtime DLLs (so it runs on a clean machine), and zips the result to:

```
dist\brick_collector-windows-v<version>-portable.zip
```

Bump `version:` in `pubspec.yaml` before building to change the filename/version.

## Give it to a tester

Send the ZIP. They:

1. Unzip it anywhere (e.g. Desktop).
2. Run **`brick_collector.exe`**.

Windows SmartScreen may warn "Windows protected your PC" for an unsigned exe →
**More info → Run anyway** (once). That's expected for an unsigned portable
build; signing removes it (see below).

### If it won't start on a clean machine
The VC++ runtime should already be bundled by the script. If not, install
**Microsoft Visual C++ 2015–2022 Redistributable (x64)** on the target machine
(a small, free Microsoft download).

## Notes
- **`dist/` holds build artifacts** — consider adding it to `.gitignore` rather
  than committing multi-MB zips.
- **No auto-update / no Start-menu entry** — that's the portable-ZIP tradeoff.
  If you later want a real installer (Start menu, uninstall), switch to the
  `msix` path (already a dependency) — it needs a signing certificate that each
  machine trusts, or a paid code-signing cert to avoid the SmartScreen warning.
- The Rebrickable Cloudflare workaround on Windows uses the OS-bundled
  `curl.exe` (see `brick-lib/lib/request/curl_http_adapter.dart`); no extra
  setup needed on the tester's machine (Windows 10 v1803+ / 11 ship curl).
