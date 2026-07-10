<#
Builds a portable Windows release ZIP of Brick Collector.

PREREQUISITES (one-time, on the Windows build machine):
  1. Visual Studio 2022 with the "Desktop development with C++" workload
     (https://visualstudio.microsoft.com/downloads/)
  2. Flutter SDK on PATH  (so `flutter --version` works)
  3. Run once:   flutter config --enable-windows-desktop

USAGE (from the repo root, in PowerShell):
  powershell -ExecutionPolicy Bypass -File scripts\build_windows.ps1

OUTPUT:
  dist\brick_collector-windows-v<version>-portable.zip
  → hand this to a tester: they unzip it anywhere and run brick_collector.exe
    (no installer, no admin rights needed).
#>

$ErrorActionPreference = 'Stop'

# --- repo root = parent of this script's folder ---
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

# --- read version from pubspec.yaml ("1.0.0+1" -> "1.0.0") ---
$verMatch = Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(\S+)' | Select-Object -First 1
if (-not $verMatch) { throw "Could not read 'version:' from pubspec.yaml" }
$fullVer = $verMatch.Matches[0].Groups[1].Value
$version = ($fullVer -split '\+')[0]
Write-Host "==> Building Brick Collector $version (Windows, release)" -ForegroundColor Cyan

# --- build ---
flutter --version
flutter config --enable-windows-desktop | Out-Null
flutter pub get
flutter build windows --release

# --- locate the release output (Flutter 3.x = x64 subdir; older builds don't) ---
$ReleaseDir = @(
  'build\windows\x64\runner\Release',
  'build\windows\runner\Release'
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $ReleaseDir) { throw "No Release output under build\windows — did the build succeed?" }
Write-Host "==> Release output: $ReleaseDir" -ForegroundColor Green

# --- bundle the Visual C++ runtime so it runs on a clean machine ---
$crtDlls = @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')
$copied = @()
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (Test-Path $vswhere) {
  $vsPath = & $vswhere -latest -products * `
    -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    -property installationPath
  if ($vsPath) {
    $redistRoot = Join-Path $vsPath 'VC\Redist\MSVC'
    $crtVerDir = Get-ChildItem -Path $redistRoot -Directory -ErrorAction SilentlyContinue |
      Sort-Object Name -Descending | Select-Object -First 1
    if ($crtVerDir) {
      $crtSrc = Get-ChildItem -Path (Join-Path $crtVerDir.FullName 'x64') `
        -Filter 'Microsoft.VC*.CRT' -Directory -ErrorAction SilentlyContinue |
        Select-Object -First 1
      if ($crtSrc) {
        foreach ($dll in $crtDlls) {
          $src = Join-Path $crtSrc.FullName $dll
          if ((Test-Path $src) -and -not (Test-Path (Join-Path $ReleaseDir $dll))) {
            Copy-Item $src -Destination $ReleaseDir
            $copied += $dll
          }
        }
      }
    }
  }
}
if ($copied.Count -gt 0) {
  Write-Host "==> Bundled VC++ runtime: $($copied -join ', ')" -ForegroundColor Green
} else {
  Write-Warning ("Could not auto-bundle the VC++ runtime ($($crtDlls -join ', ')). " +
    "If the app won't start on a clean machine, install 'Microsoft Visual C++ 2015-2022 " +
    "Redistributable (x64)' there, or copy those DLLs into the app folder.")
}

# --- zip the folder contents (so brick_collector.exe sits at the zip root) ---
$distDir = Join-Path $RepoRoot 'dist'
New-Item -ItemType Directory -Force -Path $distDir | Out-Null
$zipPath = Join-Path $distDir "brick_collector-windows-v$version-portable.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path (Join-Path $ReleaseDir '*') -DestinationPath $zipPath -CompressionLevel Optimal
$sizeMB = [math]::Round((Get-Item $zipPath).Length / 1MB, 1)

Write-Host ""
Write-Host "==> Done: $zipPath  ($sizeMB MB)" -ForegroundColor Cyan
Write-Host "    Tester: unzip anywhere, run brick_collector.exe" -ForegroundColor Cyan
