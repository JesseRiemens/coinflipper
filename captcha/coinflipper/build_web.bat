@echo off
setlocal enabledelayedexpansion

set BASE_HREF=/coinflipper/app/

echo == Flutter Web Build (Batch) ==
where flutter >nul 2>nul || (echo flutter command not found in PATH & exit /b 1)

echo Building with base href: %BASE_HREF%
flutter build web --release --base-href %BASE_HREF% --no-web-resources-cdn --no-wasm-dry-run
if errorlevel 1 (
  echo Flutter build failed with exit code %errorlevel%
  exit /b %errorlevel%
)

set TARGET=..\app
if not exist %TARGET% mkdir %TARGET%

echo Mirroring build\web to %TARGET% via robocopy
robocopy build\web %TARGET% /MIR /NFL /NDL /NJH /NJS /NP
set RC=%errorlevel%
if %RC% GEQ 8 (
  echo Robocopy reported issues (exit code %RC%)
  exit /b %RC%
)

echo Build assets copied to %TARGET%

echo Done.
endlocal
