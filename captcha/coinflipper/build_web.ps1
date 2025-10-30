Param(
  [string]$BaseHref = '/coinflipper/app/'
)

Write-Host '== Flutter Web Build (PowerShell) =='
$ErrorActionPreference = 'Stop'

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error 'flutter command not found in PATH.'
  exit 1
}

Write-Host "Building with base href: $BaseHref"
flutter build web --release --base-href $BaseHref --no-web-resources-cdn --no-wasm-dry-run
if ($LASTEXITCODE -ne 0) {
  Write-Error "Flutter build failed with exit code $LASTEXITCODE"
  exit $LASTEXITCODE
}

# Ensure target ../app directory exists and mirror build
$targetPath = Join-Path '..' 'app'
if (-not (Test-Path $targetPath)) { New-Item -ItemType Directory -Path $targetPath | Out-Null }

Write-Host "Mirroring build/web to $targetPath via robocopy"
robocopy .\build\web $targetPath /MIR /NFL /NDL /NJH /NJS /NP
$rc = $LASTEXITCODE
# Robocopy exit codes: 0=No copy,1=Copied, others may still be OK (<8)
if ($rc -ge 8) {
  Write-Warning "Robocopy reported issues (exit code $rc)"
  exit $rc
}

Write-Host "Build assets copied to $targetPath"
Write-Host 'Done.'
